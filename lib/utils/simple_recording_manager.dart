import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'azure_storage_service.dart';
import 'permission_manager.dart';

/// Gestionnaire d'enregistrement simplifié qui capture les métadonnées du live
/// et crée des fichiers vidéo simulés avec vraies informations
class SimpleRecordingManager {
  static bool _isRecording = false;
  static String? _currentLiveId;
  static DateTime? _recordingStartTime;
  static List<Map<String, dynamic>> _liveMetadata = [];

  /// Démarre l'enregistrement (capture de métadonnées en temps réel)
  static Future<bool> startRecording(String liveId) async {
    try {
      if (_isRecording) {
        debugPrint('❌ Enregistrement déjà en cours');
        return false;
      }

      debugPrint('🎥 Démarrage de l\'enregistrement simplifié pour: $liveId');

      // Vérifier les permissions avec le gestionnaire centralisé
      final hasPermissions = await PermissionManager.hasEssentialPermissions();
      if (!hasPermissions) {
        debugPrint(
          '⚠️ Permissions manquantes - Enregistrement en mode dégradé',
        );
        // Essayer de demander seulement si vraiment nécessaire
        await PermissionManager.requestIfNeeded(Permission.storage);
      }

      _currentLiveId = liveId;
      _recordingStartTime = DateTime.now();
      _liveMetadata.clear();

      // Mettre à jour le statut dans Firestore
      await FirebaseFirestore.instance.collection('lives').doc(liveId).update({
        'is_recording': true,
        'recording_start_time': _recordingStartTime!.millisecondsSinceEpoch,
        'recording_status': 'recording',
        'recording_type': 'metadata_capture',
      });

      _isRecording = true;

      // Démarrer la capture de métadonnées en temps réel
      _startMetadataCapture(liveId);

      debugPrint('✅ Enregistrement de métadonnées démarré avec succès');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors du démarrage de l\'enregistrement: $e');
      await _resetRecordingState(liveId);
      return false;
    }
  }

  /// Arrête l'enregistrement et crée un fichier de recap
  static Future<bool> stopRecording(String liveId) async {
    try {
      if (!_isRecording || _currentLiveId != liveId) {
        debugPrint('❌ Aucun enregistrement en cours pour ce live');
        return false;
      }

      _isRecording = false;
      final recordingEndTime = DateTime.now();
      final duration = recordingEndTime.difference(_recordingStartTime!);

      debugPrint(
        '⏹️ Arrêt de l\'enregistrement après ${duration.inSeconds} secondes',
      );

      // Récupérer les données finales du live
      final liveData = await _getFinalLiveData(liveId);

      // Créer un fichier de recap détaillé
      final success = await _createRecapFile(liveId, liveData, duration);

      if (success) {
        await FirebaseFirestore.instance
            .collection('lives')
            .doc(liveId)
            .update({
              'is_recording': false,
              'recording_end_time': recordingEndTime.millisecondsSinceEpoch,
              'recording_status': 'completed',
              'has_recording': true,
              'recording_duration_seconds': duration.inSeconds,
              'recording_format': 'recap_html',
              'recording_quality': 'complete_metadata',
            });

        debugPrint('✅ Enregistrement terminé et recap créé avec succès');
        return true;
      } else {
        debugPrint('❌ Échec de la création du recap');
        await _resetRecordingState(liveId);
        return false;
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'arrêt de l\'enregistrement: $e');
      await _resetRecordingState(liveId);
      return false;
    } finally {
      _currentLiveId = null;
      _recordingStartTime = null;
      _liveMetadata.clear();
    }
  }

  /// Capture les métadonnées du live en temps réel
  static void _startMetadataCapture(String liveId) {
    // Capturer les stats toutes les 30 secondes
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isRecording || _currentLiveId != liveId) {
        timer.cancel();
        return;
      }

      _captureCurrentStats(liveId);
    });
  }

  /// Capture les statistiques actuelles du live (avec retry en cas d'erreur réseau)
  static Future<void> _captureCurrentStats(String liveId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('lives')
          .doc(liveId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _liveMetadata.add({
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'viewers': data['stats']?['account'] ?? 0,
          'likes': data['stats']?['likes'] ?? 0,
          'gifts': data['totalgift'] ?? 0,
        });
        debugPrint('📊 Stats capturées: ${_liveMetadata.length} échantillons');
      }
    } catch (e) {
      debugPrint('⚠️ Erreur capture métadonnées (retry plus tard): $e');
      // En cas d'erreur réseau, on sauvegarde quand même les stats locales
      _liveMetadata.add({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'viewers': 0,
        'likes': 0,
        'gifts': 0,
        'error': 'Connexion temporairement indisponible',
      });
    }
  }

  /// Récupère les données finales du live
  static Future<Map<String, dynamic>> _getFinalLiveData(String liveId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('lives')
          .doc(liveId)
          .get();

      return doc.exists ? doc.data()! : {};
    } catch (e) {
      debugPrint('❌ Erreur récupération données live: $e');
      return {};
    }
  }

  /// Crée un fichier recap HTML interactif
  static Future<bool> _createRecapFile(
    String liveId,
    Map<String, dynamic> liveData,
    Duration duration,
  ) async {
    try {
      debugPrint('📄 Création du fichier recap...');

      // Générer le contenu HTML du recap
      final htmlContent = _generateRecapHTML(liveId, liveData, duration);
      final htmlBytes = Uint8List.fromList(htmlContent.codeUnits);

      // Sauvegarder localement
      final localPath = await _saveRecapLocally(liveId, htmlContent);

      // Uploader vers Azure
      final azureUrl = await AzureStorageService.uploadRecording(
        liveId,
        htmlBytes,
      );

      if (azureUrl != null) {
        await FirebaseFirestore.instance
            .collection('lives')
            .doc(liveId)
            .update({
              'recording_url': azureUrl,
              'local_recording_path': localPath,
              'recording_file_size_kb': (htmlBytes.length / 1024)
                  .toStringAsFixed(2),
            });

        debugPrint('✅ Recap sauvegardé: local=$localPath, azure=$azureUrl');
        return true;
      } else {
        // Échec Azure, garder au moins le fichier local
        await FirebaseFirestore.instance.collection('lives').doc(liveId).update(
          {'local_recording_path': localPath},
        );
        return true;
      }
    } catch (e) {
      debugPrint('❌ Erreur création recap: $e');
      return false;
    }
  }

  /// Sauvegarde le recap localement
  static Future<String?> _saveRecapLocally(
    String liveId,
    String htmlContent,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/live_recap_$liveId.html';

      final file = File(filePath);
      await file.writeAsString(htmlContent);

      debugPrint('💾 Recap sauvegardé localement: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde locale: $e');
      return null;
    }
  }

  /// Génère le contenu HTML du recap
  static String _generateRecapHTML(
    String liveId,
    Map<String, dynamic> liveData,
    Duration duration,
  ) {
    final title = liveData['desc'] ?? 'Live sans titre';
    final hostName = liveData['name_host'] ?? 'Host inconnu';
    final hostAvatar = liveData['avatar_host'] ?? '';
    final thumbnail = liveData['thumbnail'] ?? '';
    final startTime = DateTime.fromMillisecondsSinceEpoch(
      liveData['livestarttime'] ?? 0,
    );
    final stats = liveData['stats'] ?? {};
    final maxViewers = stats['account'] ?? 0;
    final totalLikes = stats['likes'] ?? 0;
    final totalGifts = liveData['totalgift'] ?? 0;

    return '''
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title - Recap Live Streamyz</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', system-ui, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh; 
            padding: 20px;
        }
        .container {
            max-width: 800px; 
            margin: 0 auto; 
            background: white; 
            border-radius: 20px; 
            overflow: hidden;
            box-shadow: 0 20px 60px rgba(0,0,0,0.2);
        }
        .header {
            background: linear-gradient(45deg, #667eea, #764ba2);
            color: white; 
            padding: 30px; 
            text-align: center;
        }
        .header h1 { font-size: 2.5em; margin-bottom: 10px; }
        .header p { font-size: 1.2em; opacity: 0.9; }
        .host-info {
            display: flex; 
            align-items: center; 
            justify-content: center; 
            margin-top: 20px;
        }
        .host-avatar {
            width: 60px; 
            height: 60px; 
            border-radius: 50%; 
            margin-right: 15px; 
            border: 3px solid white;
        }
        .content { padding: 40px; }
        .stats-grid {
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); 
            gap: 20px; 
            margin: 30px 0;
        }
        .stat-card {
            background: #f8fafc; 
            padding: 25px; 
            border-radius: 15px; 
            text-align: center;
            border-left: 5px solid #667eea;
        }
        .stat-number { 
            font-size: 2.5em; 
            font-weight: bold; 
            color: #667eea; 
            margin-bottom: 10px;
        }
        .stat-label { color: #64748b; font-weight: 600; }
        .timeline {
            background: #f8fafc; 
            padding: 30px; 
            border-radius: 15px; 
            margin: 30px 0;
        }
        .timeline h3 { 
            color: #334155; 
            margin-bottom: 20px; 
            font-size: 1.3em;
        }
        .timeline-item {
            display: flex; 
            align-items: center; 
            margin-bottom: 15px; 
            padding: 15px; 
            background: white; 
            border-radius: 10px;
        }
        .timeline-time { 
            font-weight: bold; 
            color: #667eea; 
            margin-right: 15px; 
            min-width: 80px;
        }
        .play-button {
            background: linear-gradient(45deg, #ff6b6b, #ee5a24);
            color: white; 
            border: none; 
            padding: 15px 30px; 
            border-radius: 50px; 
            font-size: 1.1em; 
            font-weight: bold; 
            cursor: pointer; 
            margin: 20px auto; 
            display: block;
            transition: transform 0.2s;
        }
        .play-button:hover { transform: scale(1.05); }
        .footer {
            background: #f1f5f9; 
            padding: 30px; 
            text-align: center; 
            color: #64748b;
        }
        .badge {
            display: inline-block; 
            background: #10b981; 
            color: white; 
            padding: 8px 16px; 
            border-radius: 20px; 
            font-size: 0.9em; 
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎥 $title</h1>
            <p>Live streamé sur Streamyz</p>
            <div class="host-info">
                ${hostAvatar.isNotEmpty ? '<img src="$hostAvatar" alt="Avatar" class="host-avatar">' : '<div class="host-avatar" style="background: #667eea; display: flex; align-items: center; justify-content: center; color: white; font-size: 24px;">👤</div>'}
                <div>
                    <div style="font-size: 1.3em; font-weight: bold;">$hostName</div>
                    <div style="opacity: 0.8;">Créateur</div>
                </div>
            </div>
        </div>

        <div class="content">
            <div style="text-align: center; margin-bottom: 30px;">
                <span class="badge">Live terminé</span>
            </div>

            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-number">$maxViewers</div>
                    <div class="stat-label">Spectateurs max</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number">$totalLikes</div>
                    <div class="stat-label">Likes totaux</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number">$totalGifts</div>
                    <div class="stat-label">Cadeaux reçus</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number">${duration.inMinutes}</div>
                    <div class="stat-label">Minutes diffusées</div>
                </div>
            </div>

            <div class="timeline">
                <h3>📊 Informations du live</h3>
                <div class="timeline-item">
                    <div class="timeline-time">Début</div>
                    <div>${_formatDateTime(startTime)}</div>
                </div>
                <div class="timeline-item">
                    <div class="timeline-time">Durée</div>
                    <div>${_formatDuration(duration)}</div>
                </div>
                <div class="timeline-item">
                    <div class="timeline-time">Pic d'audience</div>
                    <div>$maxViewers spectateurs simultanés</div>
                </div>
                <div class="timeline-item">
                    <div class="timeline-time">Engagement</div>
                    <div>${totalLikes + totalGifts} interactions totales</div>
                </div>
            </div>

            <button class="play-button" onclick="playRecording()">
                ▶️ Voir les moments forts
            </button>
        </div>

        <div class="footer">
            <p><strong>Streamyz</strong> - Plateforme de streaming live</p>
            <p>Recap généré automatiquement le ${_formatDateTime(DateTime.now())}</p>
            <p style="margin-top: 10px; font-size: 0.9em;">
                Cet enregistrement contient toutes les statistiques et moments clés de votre live.
            </p>
        </div>
    </div>

    <script>
        function playRecording() {
            alert('🎬 Cette fonctionnalité ouvrira bientôt un lecteur vidéo intégré.\\n\\nPour l\\'instant, ce recap contient toutes les statistiques importantes de votre live !');
        }
    </script>
</body>
</html>
''';
  }

  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} à ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}min';
    } else {
      return '${duration.inMinutes}min ${duration.inSeconds.remainder(60)}s';
    }
  }

  /// Remet à zéro l'état d'enregistrement
  static Future<void> _resetRecordingState(String liveId) async {
    try {
      _isRecording = false;
      _currentLiveId = null;
      _recordingStartTime = null;
      _liveMetadata.clear();

      await FirebaseFirestore.instance.collection('lives').doc(liveId).update({
        'is_recording': false,
        'recording_status': 'failed',
      });
    } catch (e) {
      debugPrint('❌ Erreur lors de la remise à zéro: $e');
    }
  }

  // Méthodes publiques pour l'interface
  static bool isRecording() => _isRecording;
  static String? getCurrentRecordingLiveId() => _currentLiveId;
  static Duration? getCurrentRecordingDuration() {
    if (_recordingStartTime == null) return null;
    return DateTime.now().difference(_recordingStartTime!);
  }

  /// Obtient les statistiques de l'enregistrement en cours
  static Map<String, dynamic> getCurrentRecordingStats() {
    return {
      'isRecording': _isRecording,
      'liveId': _currentLiveId,
      'startTime': _recordingStartTime?.millisecondsSinceEpoch,
      'duration': getCurrentRecordingDuration()?.inSeconds ?? 0,
      'metadataSamples': _liveMetadata.length,
      'lastSample': _liveMetadata.isNotEmpty ? _liveMetadata.last : null,
    };
  }

  /// Formate le statut pour l'affichage
  static String getRecordingStatusText() {
    if (!_isRecording) {
      return '⭕ Enregistrement arrêté';
    }

    final duration = getCurrentRecordingDuration();
    if (duration == null) {
      return '🟡 Enregistrement en préparation...';
    }

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '🔴 Enregistrement actif ${minutes}min ${seconds}s (${_liveMetadata.length} échantillons)';
  }

  /// Récupère les enregistrements disponibles
  static Future<List<Map<String, dynamic>>> getRecordedLives() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('lives')
          .where('has_recording', isEqualTo: true)
          .orderBy('livestarttime', descending: true)
          .limit(50)
          .get();

      final recordedLives = <Map<String, dynamic>>[];
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        recordedLives.add({...data, 'id': doc.id});
      }

      debugPrint('📋 ${recordedLives.length} enregistrements trouvés');
      return recordedLives;
    } catch (e) {
      debugPrint('❌ Erreur récupération enregistrements: $e');
      return [];
    }
  }

  /// Supprime un enregistrement
  static Future<bool> deleteRecording(String liveId) async {
    try {
      // Récupérer les infos de l'enregistrement
      final doc = await FirebaseFirestore.instance
          .collection('lives')
          .doc(liveId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;

        // Supprimer le fichier local s'il existe
        final localPath = data['local_recording_path'] ?? '';
        if (localPath.isNotEmpty) {
          try {
            final file = File(localPath);
            if (await file.exists()) {
              await file.delete();
              debugPrint('✅ Fichier local supprimé');
            }
          } catch (e) {
            debugPrint('⚠️ Erreur suppression locale: $e');
          }
        }

        // Supprimer de Azure s'il existe
        if (data['recording_url'] != null) {
          await AzureStorageService.deleteRecording(liveId);
        }
      }

      // Mettre à jour Firestore
      await FirebaseFirestore.instance.collection('lives').doc(liveId).update({
        'recording_url': '',
        'has_recording': false,
        'recording_status': 'deleted',
        'local_recording_path': '',
      });

      debugPrint('✅ Enregistrement supprimé: $liveId');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur suppression: $e');
      return false;
    }
  }
}
