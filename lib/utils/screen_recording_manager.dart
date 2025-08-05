import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screen_recorder/screen_recorder.dart';

import 'azure_storage_service.dart';

/// Gestionnaire d'enregistrement d'écran réel avec screen_recorder
/// Capture vraiment l'écran pendant le live et sauvegarde sur Azure
class ScreenRecordingManager {
  static bool _isRecording = false;
  static String? _currentLiveId;
  static DateTime? _recordingStartTime;
  static ScreenRecorderController? _controller;
  static String? _currentRecordingPath;

  /// Démarre l'enregistrement d'écran réel
  static Future<bool> startRecording(String liveId) async {
    try {
      if (_isRecording) {
        debugPrint('❌ Enregistrement déjà en cours');
        return false;
      }

      debugPrint(
        '🎥 Démarrage de l\'enregistrement d\'écran réel pour: $liveId',
      );

      // Vérifier et demander les permissions nécessaires
      final hasPermissions = await _requestScreenRecordingPermissions();
      if (!hasPermissions) {
        debugPrint(
          '⚠️ Certaines permissions manquantes - Continuation quand même',
        );
      }

      // Initialiser le contrôleur d'enregistrement
      _controller = ScreenRecorderController(
        pixelRatio: 1.0,
        skipFramesBetweenCaptures: 2,
      );

      // Obtenir le chemin pour sauvegarder le fichier temporairement
      final directory = await getTemporaryDirectory();
      final fileName =
          'live_${liveId}_${DateTime.now().millisecondsSinceEpoch}.gif';
      final filePath = '${directory.path}/$fileName';

      _currentLiveId = liveId;
      _recordingStartTime = DateTime.now();
      _currentRecordingPath = filePath;

      // Mettre à jour le statut dans Firestore
      await FirebaseFirestore.instance.collection('lives').doc(liveId).update({
        'is_recording': true,
        'recording_start_time': _recordingStartTime!.millisecondsSinceEpoch,
        'recording_status': 'recording',
        'recording_type': 'real_screen_capture',
        'recording_method': 'screen_recorder',
      });

      // Démarrer l'enregistrement d'écran
      _controller!.start();
      _isRecording = true;

      debugPrint('✅ Enregistrement d\'écran démarré avec succès');

      // Afficher une notification système
      _showRecordingNotification(true);

      return true;
    } catch (e) {
      debugPrint(
        '❌ Erreur lors du démarrage de l\'enregistrement d\'écran: $e',
      );
      await _resetRecordingState(liveId);
      return false;
    }
  }

  /// Arrête l'enregistrement et sauvegarde sur Azure
  static Future<bool> stopRecording(String liveId) async {
    try {
      if (!_isRecording || _currentLiveId != liveId || _controller == null) {
        debugPrint('❌ Aucun enregistrement en cours pour ce live');
        return false;
      }

      debugPrint('⏹️ Arrêt de l\'enregistrement d\'écran...');

      // Arrêter l'enregistrement
      _controller!.stop();
      _isRecording = false;

      final recordingEndTime = DateTime.now();
      final duration = recordingEndTime.difference(_recordingStartTime!);

      debugPrint(
        '⏱️ Durée de l\'enregistrement: ${duration.inSeconds} secondes',
      );

      // Attendre que screen_recorder finisse de sauvegarder le fichier
      await Future.delayed(const Duration(seconds: 3));

      // Récupérer le fichier d'enregistrement réel généré par screen_recorder
      Uint8List? recordingContent;

      if (_currentRecordingPath == null) {
        throw Exception('Chemin d\'enregistrement non défini');
      }

      final recordingFile = File(_currentRecordingPath!);
      if (!await recordingFile.exists()) {
        throw Exception(
          'Fichier d\'enregistrement non trouvé: $_currentRecordingPath',
        );
      }

      recordingContent = await recordingFile.readAsBytes();

      if (recordingContent.isEmpty) {
        throw Exception('Fichier d\'enregistrement vide');
      }

      debugPrint(
        '📁 Fichier d\'enregistrement réel trouvé: ${recordingContent.length} bytes',
      );

      final fileSizeMB = (recordingContent.length / (1024 * 1024))
          .toStringAsFixed(2);
      debugPrint('📊 Taille du fichier: ${fileSizeMB}MB');

      // Mettre à jour le statut d'enregistrement dans Firestore
      await FirebaseFirestore.instance.collection('lives').doc(liveId).update({
        'is_recording': false,
        'recording_end_time': recordingEndTime.millisecondsSinceEpoch,
        'recording_status': 'uploading',
        'recording_duration_seconds': duration.inSeconds,
        'recording_file_size_mb': double.parse(fileSizeMB),
      });

      // Upload vers Azure Blob Storage
      debugPrint('☁️ Upload vers Azure en cours...');
      final azureUrl = await AzureStorageService.uploadRecording(
        liveId,
        recordingContent,
      );

      if (azureUrl != null) {
        // Mise à jour finale dans Firestore
        await FirebaseFirestore.instance.collection('lives').doc(liveId).update(
          {
            'recording_status': 'completed',
            'has_recording': true,
            'recording_url': azureUrl,
            'recording_format': 'gif', // Format natif de screen_recorder
            'recording_quality': 'screen_capture',
            'recording_contains_audio':
                false, // screen_recorder ne capture pas l'audio
            'recording_local_path': _currentRecordingPath,
          },
        );

        debugPrint('✅ Enregistrement uploadé avec succès: $azureUrl');

        // Nettoyer le fichier temporaire après upload
        if (_currentRecordingPath != null) {
          try {
            final recordingFile = File(_currentRecordingPath!);
            if (await recordingFile.exists()) {
              await recordingFile.delete();
              debugPrint('🧹 Fichier temporaire supprimé');
            }
          } catch (e) {
            debugPrint('⚠️ Impossible de supprimer le fichier temporaire: $e');
          }
        }

        _showRecordingNotification(false);
        return true;
      } else {
        debugPrint('❌ Échec de l\'upload vers Azure');
        await _resetRecordingState(liveId);
        return false;
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'arrêt de l\'enregistrement: $e');
      await _resetRecordingState(liveId);
      return false;
    } finally {
      _controller = null;
      _currentLiveId = null;
      _recordingStartTime = null;
      _currentRecordingPath = null;
    }
  }

  /// Demande les permissions nécessaires pour l'enregistrement d'écran
  static Future<bool> _requestScreenRecordingPermissions() async {
    try {
      // Permissions de base
      final permissions = [
        Permission.microphone, // Pour l'audio
        Permission.storage, // Pour sauvegarder
      ];

      // Permissions spécifiques Android
      if (Platform.isAndroid) {
        permissions.addAll([
          Permission.systemAlertWindow, // Pour l'overlay d'enregistrement
          Permission.manageExternalStorage, // Pour accéder aux fichiers
        ]);
      }

      // Demander toutes les permissions
      final statuses = await permissions.request();

      // Vérifier si les permissions essentielles sont accordées
      final microphoneGranted =
          statuses[Permission.microphone]?.isGranted ?? false;
      final storageGranted = statuses[Permission.storage]?.isGranted ?? false;

      if (!microphoneGranted || !storageGranted) {
        debugPrint('⚠️ Permissions essentielles manquantes');
        debugPrint('Microphone: $microphoneGranted, Storage: $storageGranted');
      }

      // Retourner true même si certaines permissions optionnelles sont refusées
      return microphoneGranted && storageGranted;
    } catch (e) {
      debugPrint('❌ Erreur lors de la demande de permissions: $e');
      return false;
    }
  }

  /// Affiche une notification système pour l'enregistrement
  static void _showRecordingNotification(bool isStarting) {
    try {
      if (isStarting) {
        debugPrint(
          '🔴 ENREGISTREMENT D\'ÉCRAN EN COURS - Ne fermez pas l\'application',
        );
      } else {
        debugPrint('💾 Enregistrement d\'écran terminé et sauvegardé');
      }
    } catch (e) {
      debugPrint('⚠️ Impossible d\'afficher la notification: $e');
    }
  }

  /// Remet à zéro l'état d'enregistrement en cas d'erreur
  static Future<void> _resetRecordingState(String liveId) async {
    try {
      _isRecording = false;
      _currentLiveId = null;
      _recordingStartTime = null;

      await FirebaseFirestore.instance.collection('lives').doc(liveId).update({
        'recording_status': 'failed',
        'is_recording': false,
      });
    } catch (e) {
      debugPrint('❌ Erreur lors du reset de l\'état d\'enregistrement: $e');
    }
  }

  /// Vérifie si un enregistrement est en cours
  static bool get isRecording => _isRecording;

  /// Récupère l'ID du live en cours d'enregistrement
  static String? get currentLiveId => _currentLiveId;

  /// Récupère la durée actuelle de l'enregistrement
  static Duration? get currentDuration {
    if (!_isRecording || _recordingStartTime == null) return null;
    return DateTime.now().difference(_recordingStartTime!);
  }

  /// Récupère des informations sur l'enregistrement en cours
  static Map<String, dynamic>? getCurrentRecordingInfo() {
    if (!_isRecording) return null;

    return {
      'liveId': _currentLiveId,
      'startTime': _recordingStartTime?.millisecondsSinceEpoch,
      'duration_seconds': currentDuration?.inSeconds ?? 0,
      'recording_type': 'real_screen_capture',
      'status': 'recording',
      'method': 'screen_recorder',
    };
  }
}
