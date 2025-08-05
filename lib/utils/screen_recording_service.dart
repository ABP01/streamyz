import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screen_recorder/screen_recorder.dart';

import 'azure_storage_service.dart';

/// Service d'enregistrement d'écran utilisant screen_recorder
/// Enregistre l'écran du live et sauvegarde automatiquement sur Azure
class ScreenRecordingService {
  static ScreenRecorderController? _screenRecorderController;
  static bool _isRecording = false;
  static String? _currentLiveId;
  static DateTime? _recordingStartTime;
  static String? _currentRecordingPath;

  /// Démarre l'enregistrement de l'écran pour un live
  static Future<bool> startScreenRecording(
    String liveId, [
    GlobalKey? widgetKey,
  ]) async {
    try {
      if (_isRecording) {
        debugPrint('❌ Enregistrement d\'écran déjà en cours');
        return false;
      }

      // Vérifier et demander les permissions nécessaires
      final hasPermissions = await _requestScreenRecordingPermissions();
      if (!hasPermissions) {
        debugPrint('❌ Permissions d\'enregistrement d\'écran manquantes');
        return false;
      }

      // Initialiser le contrôleur d'enregistrement
      _screenRecorderController = ScreenRecorderController(
        pixelRatio: 2.0, // Utiliser une résolution élevée
        skipFramesBetweenCaptures:
            1, // Capturer plus de frames pour une meilleure qualité
      );

      // Obtenir le chemin pour sauvegarder le fichier temporairement
      final directory = await getTemporaryDirectory();
      final fileName =
          'live_${liveId}_${DateTime.now().millisecondsSinceEpoch}';
      final filePath = '${directory.path}/$fileName';

      _currentRecordingPath = filePath;
      _currentLiveId = liveId;
      _recordingStartTime = DateTime.now();

      // Mettre à jour le statut dans Firestore
      await FirebaseFirestore.instance.collection('lives').doc(liveId).update({
        'is_recording': true,
        'recording_start_time': _recordingStartTime!.millisecondsSinceEpoch,
        'recording_status': 'recording',
        'recording_type': 'screen_capture',
        'recording_quality': 'native_resolution',
        'recording_path': filePath,
      });

      // Démarrer l'enregistrement d'écran
      try {
        _screenRecorderController!.start();
        _isRecording = true;

        debugPrint('✅ Enregistrement d\'écran démarré pour le live: $liveId');
        debugPrint('📁 Fichier d\'enregistrement: $filePath');

        // Mettre à jour le statut pour confirmer que l'enregistrement est actif
        await FirebaseFirestore.instance.collection('lives').doc(liveId).update(
          {
            'recording_status': 'active_recording',
            'local_recording_path': filePath,
          },
        );

        return true;
      } catch (e) {
        debugPrint('❌ Erreur lors du démarrage de l\'enregistrement: $e');
        await _resetRecordingState(liveId);
        return false;
      }
    } catch (e) {
      debugPrint(
        '❌ Erreur lors du démarrage de l\'enregistrement d\'écran: $e',
      );
      await _resetRecordingState(liveId);
      return false;
    }
  }

  /// Arrête l'enregistrement et upload automatiquement vers Azure
  static Future<bool> stopScreenRecording(String liveId) async {
    try {
      if (!_isRecording ||
          _currentLiveId != liveId ||
          _screenRecorderController == null) {
        debugPrint('❌ Aucun enregistrement d\'écran en cours pour ce live');
        return false;
      }

      debugPrint('⏹️ Arrêt de l\'enregistrement d\'écran pour: $liveId');

      // Arrêter l'enregistrement d'écran et récupérer le fichier
      _screenRecorderController!.stop();

      _isRecording = false;
      final recordingEndTime = DateTime.now();
      final duration = recordingEndTime.difference(_recordingStartTime!);

      debugPrint(
        '⏱️ Durée de l\'enregistrement: ${duration.inSeconds} secondes',
      );

      // Mettre à jour le statut dans Firestore
      await FirebaseFirestore.instance.collection('lives').doc(liveId).update({
        'is_recording': false,
        'recording_end_time': recordingEndTime.millisecondsSinceEpoch,
        'recording_status': 'processing',
        'recording_duration_seconds': duration.inSeconds,
      });

      // Attendre que le fichier d'enregistrement soit disponible
      await Future.delayed(const Duration(seconds: 3));

      // Récupérer le fichier d'enregistrement réel
      Uint8List? recordingContent;
      if (_currentRecordingPath != null) {
        final recordingFile = File(_currentRecordingPath!);
        if (await recordingFile.exists()) {
          recordingContent = await recordingFile.readAsBytes();
          debugPrint(
            '📁 Fichier d\'enregistrement trouvé: ${recordingContent.length} bytes',
          );
        } else {
          debugPrint(
            '❌ Fichier d\'enregistrement non trouvé: $_currentRecordingPath',
          );
          throw Exception('Fichier d\'enregistrement non disponible');
        }
      } else {
        debugPrint('❌ Chemin de fichier d\'enregistrement non défini');
        throw Exception('Chemin d\'enregistrement non défini');
      }

      if (recordingContent.isEmpty) {
        throw Exception('Contenu d\'enregistrement vide');
      }

      // Upload vers Azure Blob Storage
      final azureUrl = await AzureStorageService.uploadRecording(
        liveId,
        recordingContent,
      );

      if (azureUrl != null) {
        // Succès de l'upload - mettre à jour Firestore
        await FirebaseFirestore.instance
            .collection('lives')
            .doc(liveId)
            .update({
              'recording_url': azureUrl,
              'has_recording': true,
              'recording_status': 'completed',
              'recording_file_size_mb': (recordingContent.length / 1024 / 1024)
                  .toStringAsFixed(2),
              'recording_format': 'mp4',
              'azure_upload_time': DateTime.now().millisecondsSinceEpoch,
            });

        debugPrint('✅ Enregistrement uploadé vers Azure: $azureUrl');

        // Nettoyer le fichier temporaire
        if (_currentRecordingPath != null) {
          try {
            final recordingFile = File(_currentRecordingPath!);
            if (await recordingFile.exists()) {
              await recordingFile.delete();
              debugPrint('🗑️ Fichier temporaire supprimé');
            }
          } catch (e) {
            debugPrint('⚠️ Erreur suppression fichier temporaire: $e');
          }
        }

        return true;
      } else {
        debugPrint('❌ Échec de l\'upload vers Azure');

        // Garder le fichier local en cas d'échec Azure
        await FirebaseFirestore.instance
            .collection('lives')
            .doc(liveId)
            .update({
              'recording_status': 'upload_failed',
              'local_recording_path': _currentRecordingPath,
              'recording_file_size_mb': (recordingContent.length / 1024 / 1024)
                  .toStringAsFixed(2),
            });

        return false;
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'arrêt de l\'enregistrement: $e');
      await _resetRecordingState(liveId);
      return false;
    } finally {
      _screenRecorderController = null;
      _currentLiveId = null;
      _recordingStartTime = null;
      _currentRecordingPath = null;
    }
  }

  /// Demande les permissions nécessaires pour l'enregistrement d'écran
  static Future<bool> _requestScreenRecordingPermissions() async {
    try {
      debugPrint(
        '🔍 Vérification des permissions d\'enregistrement d\'écran...',
      );

      // Permissions de base nécessaires
      final permissions = <Permission>[
        Permission.microphone,
        Permission.storage,
        Permission.manageExternalStorage,
      ];

      // Sur Android, ajouter des permissions spécifiques si disponibles
      if (Platform.isAndroid) {
        permissions.addAll([
          Permission.systemAlertWindow,
          Permission.accessMediaLocation,
        ]);
      }

      final statuses = await permissions.request();

      int granted = 0;
      int total = statuses.length;

      statuses.forEach((permission, status) {
        final isGranted =
            status == PermissionStatus.granted ||
            status == PermissionStatus.limited;
        if (isGranted) granted++;

        debugPrint('📋 ${permission.toString()}: ${status.toString()}');
      });

      final success = granted >= (total * 0.8); // Au moins 80% des permissions

      if (success) {
        debugPrint(
          '✅ Permissions d\'enregistrement accordées ($granted/$total)',
        );
      } else {
        debugPrint('❌ Permissions insuffisantes ($granted/$total)');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Erreur lors de la demande de permissions: $e');
      return false;
    }
  }

  /// Remet à zéro l'état d'enregistrement en cas d'erreur
  static Future<void> _resetRecordingState(String liveId) async {
    try {
      _isRecording = false;
      _currentLiveId = null;
      _recordingStartTime = null;
      _currentRecordingPath = null;
      _screenRecorderController = null;

      await FirebaseFirestore.instance.collection('lives').doc(liveId).update({
        'is_recording': false,
        'recording_status': 'failed',
      });
    } catch (e) {
      debugPrint('❌ Erreur lors de la remise à zéro: $e');
    }
  }

  /// Vérifie si un enregistrement est en cours
  static bool isRecording() => _isRecording;

  /// Obtient l'ID du live en cours d'enregistrement
  static String? getCurrentRecordingLiveId() => _currentLiveId;

  /// Obtient la durée actuelle de l'enregistrement
  static Duration? getCurrentRecordingDuration() {
    if (_recordingStartTime == null) return null;
    return DateTime.now().difference(_recordingStartTime!);
  }

  /// Obtient le statut formaté pour l'affichage
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
    return '🔴 Enregistrement d\'écran actif ${minutes}min ${seconds}s';
  }

  /// Récupère les enregistrements disponibles depuis Azure et Firestore
  static Future<List<Map<String, dynamic>>> getRecordedLives() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('lives')
          .where('has_recording', isEqualTo: true)
          .where('recording_type', isEqualTo: 'screen_capture')
          .orderBy('livestarttime', descending: true)
          .limit(50)
          .get();

      final recordedLives = <Map<String, dynamic>>[];
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final liveId = data['live_id'] ?? '';

        // Vérifier si l'enregistrement existe toujours sur Azure
        final exists = await AzureStorageService.recordingExists(liveId);
        if (exists) {
          recordedLives.add({...data, 'id': doc.id});
        }
      }

      debugPrint('📋 ${recordedLives.length} enregistrements d\'écran trouvés');
      return recordedLives;
    } catch (e) {
      debugPrint('❌ Erreur récupération enregistrements: $e');
      return [];
    }
  }

  /// Supprime un enregistrement d'écran
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

  /// Obtient l'URL sécurisée Azure pour un enregistrement
  static String getSecureRecordingUrl(String liveId) {
    return AzureStorageService.getSecureUrl('live_$liveId.mp4');
  }

  /// Obtient les statistiques de l'enregistrement en cours
  static Map<String, dynamic> getCurrentRecordingStats() {
    return {
      'isRecording': _isRecording,
      'liveId': _currentLiveId,
      'startTime': _recordingStartTime?.millisecondsSinceEpoch,
      'duration': getCurrentRecordingDuration()?.inSeconds ?? 0,
      'filePath': _currentRecordingPath,
      'recorder': _screenRecorderController != null ? 'active' : 'inactive',
    };
  }
}
