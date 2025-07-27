import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'azure_storage_service.dart';

class LiveRecordingManager {
  static bool _isRecording = false;
  static String? _currentLiveId;
  static String? _currentRecordingPath;

  /// Démarre l'enregistrement d'un live
  static Future<bool> startRecording(String liveId) async {
    try {
      if (_isRecording) {
        debugPrint('Enregistrement déjà en cours');
        return false;
      }

      _currentLiveId = liveId;
      _isRecording = true;

      // Mettre à jour le statut d'enregistrement dans Firestore
      await FirebaseFirestore.instance.collection('lives').doc(liveId).update({
        'is_recording': true,
        'recording_start_time': DateTime.now().millisecondsSinceEpoch,
      });

      debugPrint('Enregistrement démarré pour le live: $liveId');

      // Note: L'enregistrement réel avec ZegoUIKit se fait automatiquement
      // Cette méthode sert principalement à marquer le statut
      return true;
    } catch (e) {
      debugPrint('Erreur lors du démarrage de l\'enregistrement: $e');
      _isRecording = false;
      _currentLiveId = null;
      return false;
    }
  }

  /// Arrête l'enregistrement et uploade vers Azure
  static Future<bool> stopRecording(String liveId) async {
    try {
      if (!_isRecording || _currentLiveId != liveId) {
        debugPrint('Aucun enregistrement en cours pour ce live');
        return false;
      }

      _isRecording = false;

      // Mettre à jour le statut d'enregistrement dans Firestore
      await FirebaseFirestore.instance.collection('lives').doc(liveId).update({
        'is_recording': false,
        'recording_end_time': DateTime.now().millisecondsSinceEpoch,
      });

      // Simuler l'obtention du fichier d'enregistrement
      // Dans une vraie implémentation, ceci viendrait de ZegoUIKit
      final recordingData = await _getRecordingData(liveId);

      if (recordingData != null) {
        // Uploader vers Azure Blob Storage
        final recordingUrl = await AzureStorageService.uploadRecording(
          liveId,
          recordingData,
        );

        if (recordingUrl != null) {
          // Mettre à jour l'URL d'enregistrement dans Firestore
          await FirebaseFirestore.instance
              .collection('lives')
              .doc(liveId)
              .update({'recording_url': recordingUrl, 'has_recording': true});

          debugPrint('Enregistrement uploadé avec succès: $recordingUrl');
          return true;
        } else {
          debugPrint('Échec de l\'upload vers Azure');
          return false;
        }
      } else {
        debugPrint('Aucune donnée d\'enregistrement trouvée');
        return false;
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'arrêt de l\'enregistrement: $e');
      return false;
    } finally {
      _currentLiveId = null;
      _currentRecordingPath = null;
    }
  }

  /// Simule l'obtention des données d'enregistrement
  /// Dans une vraie implémentation, ceci interfacerait avec ZegoUIKit
  static Future<Uint8List?> _getRecordingData(String liveId) async {
    try {
      // Simulation d'un fichier vidéo vide pour test
      // En réalité, ceci viendrait du SDK ZegoUIKit
      final simulatedVideoData = Uint8List.fromList([
        // Header MP4 minimal pour test
        0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70, // ftyp box
        0x69, 0x73, 0x6F, 0x6D, 0x00, 0x00, 0x02, 0x00, // isom major brand
        0x69, 0x73, 0x6F, 0x6D, 0x69, 0x73, 0x6F, 0x32, // compatible brands
        0x61, 0x76, 0x63, 0x31, 0x6D, 0x70, 0x34, 0x31, // avc1 mp41
      ]);

      // Simuler un délai de traitement
      await Future.delayed(const Duration(seconds: 2));

      return simulatedVideoData;
    } catch (e) {
      debugPrint(
        'Erreur lors de l\'obtention des données d\'enregistrement: $e',
      );
      return null;
    }
  }

  /// Vérifie si un live est en cours d'enregistrement
  static bool isRecording() => _isRecording;

  /// Obtient l'ID du live en cours d'enregistrement
  static String? getCurrentRecordingLiveId() => _currentLiveId;

  /// Récupère la liste des lives enregistrés depuis Azure et Firestore
  static Future<List<Map<String, dynamic>>> getRecordedLives() async {
    try {
      final List<Map<String, dynamic>> recordedLives = [];

      // Récupérer les lives avec enregistrements depuis Firestore
      // Note: Pas de orderBy pour éviter le problème d'index
      final querySnapshot = await FirebaseFirestore.instance
          .collection('lives')
          .where('has_recording', isEqualTo: true)
          .limit(50)
          .get();

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final liveId = data['live_id'] ?? '';

        // Vérifier si l'enregistrement existe toujours sur Azure
        final recordingExists = await AzureStorageService.recordingExists(
          liveId,
        );

        if (recordingExists) {
          recordedLives.add({
            ...data,
            'id': doc.id,
            'secure_recording_url': AzureStorageService.getSecureUrl(
              'live_$liveId.mp4',
            ),
          });
        }
      }

      // Trier côté client par livestarttime (plus récents en premier)
      recordedLives.sort((a, b) {
        final aTime = a['livestarttime'] ?? 0;
        final bTime = b['livestarttime'] ?? 0;
        return bTime.compareTo(aTime);
      });

      return recordedLives;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des lives enregistrés: $e');
      return [];
    }
  }

  /// Supprime un enregistrement (à la fois sur Azure et dans Firestore)
  static Future<bool> deleteRecording(String liveId) async {
    try {
      // Supprimer de Azure Blob Storage
      final azureDeleted = await AzureStorageService.deleteRecording(liveId);

      if (azureDeleted) {
        // Mettre à jour Firestore
        await FirebaseFirestore.instance.collection('lives').doc(liveId).update(
          {'recording_url': '', 'has_recording': false},
        );

        debugPrint('Enregistrement supprimé avec succès: $liveId');
        return true;
      } else {
        debugPrint('Échec de la suppression sur Azure: $liveId');
        return false;
      }
    } catch (e) {
      debugPrint('Erreur lors de la suppression de l\'enregistrement: $e');
      return false;
    }
  }
}
