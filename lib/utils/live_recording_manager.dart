import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'azure_storage_service.dart';

class LiveRecordingManager {
  static bool _isRecording = false;
  static String? _currentLiveId;
  static String? _currentRecordingPath;

  // Configuration ZegoCloud pour l'enregistrement côté serveur
  static const String _zegoAppId = '1635546276';
  static const String _zegoServerSecret =
      'YOUR_ZEGO_SERVER_SECRET'; // Remplacer par votre secret serveur

  /// Démarre l'enregistrement d'un live avec ZegoCloud Server Side Recording
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
        'recording_status': 'starting', // Nouveau statut pour le suivi
      });

      // Démarrer l'enregistrement côté serveur ZegoCloud
      final recordingStarted = await _startZegoCloudRecording(liveId);

      if (recordingStarted) {
        // Mettre à jour le statut en cours
        await FirebaseFirestore.instance.collection('lives').doc(liveId).update(
          {'recording_status': 'recording'},
        );
        debugPrint('✅ Enregistrement ZegoCloud démarré pour le live: $liveId');
        return true;
      } else {
        debugPrint('❌ Échec du démarrage de l\'enregistrement ZegoCloud');
        _isRecording = false;
        _currentLiveId = null;
        // Marquer l'échec dans Firestore
        await FirebaseFirestore.instance.collection('lives').doc(liveId).update(
          {'recording_status': 'failed', 'is_recording': false},
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du démarrage de l\'enregistrement: $e');
      _isRecording = false;
      _currentLiveId = null;
      return false;
    }
  }

  /// Arrête l'enregistrement et récupère le fichier depuis ZegoCloud
  static Future<bool> stopRecording(String liveId) async {
    try {
      if (!_isRecording || _currentLiveId != liveId) {
        debugPrint('Aucun enregistrement en cours pour ce live');
        return false;
      }

      _isRecording = false;

      // Arrêter l'enregistrement côté serveur ZegoCloud
      final recordingStopped = await _stopZegoCloudRecording(liveId);

      if (!recordingStopped) {
        debugPrint('Échec de l\'arrêt de l\'enregistrement ZegoCloud');
        return false;
      }

      // Mettre à jour le statut d'enregistrement dans Firestore
      await FirebaseFirestore.instance.collection('lives').doc(liveId).update({
        'is_recording': false,
        'recording_end_time': DateTime.now().millisecondsSinceEpoch,
      });

      // Attendre quelques secondes pour que ZegoCloud génère le fichier
      await Future.delayed(const Duration(seconds: 5));

      // Récupérer l'URL du fichier d'enregistrement depuis ZegoCloud
      final recordingUrl = await _getZegoCloudRecordingUrl(liveId);

      if (recordingUrl != null) {
        // Télécharger et uploader vers Azure Blob Storage
        final azureUrl = await _downloadAndUploadToAzure(liveId, recordingUrl);

        if (azureUrl != null) {
          // Mettre à jour l'URL d'enregistrement dans Firestore
          await FirebaseFirestore.instance
              .collection('lives')
              .doc(liveId)
              .update({
                'recording_url': azureUrl,
                'has_recording': true,
                'zego_recording_url': recordingUrl,
              });

          debugPrint('Enregistrement uploadé avec succès: $azureUrl');
          return true;
        } else {
          debugPrint('Échec de l\'upload vers Azure');
          return false;
        }
      } else {
        debugPrint('Aucune URL d\'enregistrement trouvée sur ZegoCloud');
        // Créer un enregistrement fictif pour les tests
        return await _createDummyRecording(liveId);
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'arrêt de l\'enregistrement: $e');
      return false;
    } finally {
      _currentLiveId = null;
      _currentRecordingPath = null;
    }
  }

  /// Démarre l'enregistrement côté serveur avec ZegoCloud REST API
  static Future<bool> _startZegoCloudRecording(String liveId) async {
    try {
      // Pour l'instant, simuler le démarrage réussi
      // TODO: Implémenter l'appel REST API vers ZegoCloud
      debugPrint(
        'Simulation du démarrage d\'enregistrement ZegoCloud pour: $liveId',
      );
      return true;
    } catch (e) {
      debugPrint('Erreur lors du démarrage ZegoCloud: $e');
      return false;
    }
  }

  /// Arrête l'enregistrement côté serveur avec ZegoCloud REST API
  static Future<bool> _stopZegoCloudRecording(String liveId) async {
    try {
      // Pour l'instant, simuler l'arrêt réussi
      // TODO: Implémenter l'appel REST API vers ZegoCloud
      debugPrint(
        'Simulation de l\'arrêt d\'enregistrement ZegoCloud pour: $liveId',
      );
      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'arrêt ZegoCloud: $e');
      return false;
    }
  }

  /// Récupère l'URL de l'enregistrement depuis ZegoCloud
  static Future<String?> _getZegoCloudRecordingUrl(String liveId) async {
    try {
      // Pour l'instant, retourner null pour déclencher la création d'un enregistrement fictif
      // TODO: Implémenter l'appel REST API vers ZegoCloud pour récupérer l'URL
      debugPrint(
        'Simulation de la récupération d\'URL ZegoCloud pour: $liveId',
      );
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération d\'URL ZegoCloud: $e');
      return null;
    }
  }

  /// Télécharge l'enregistrement depuis ZegoCloud et l'uploade vers Azure
  static Future<String?> _downloadAndUploadToAzure(
    String liveId,
    String zegoUrl,
  ) async {
    try {
      // Télécharger le fichier depuis ZegoCloud
      final response = await http.get(Uri.parse(zegoUrl));
      if (response.statusCode == 200) {
        // Uploader vers Azure Blob Storage
        final azureUrl = await AzureStorageService.uploadRecording(
          liveId,
          response.bodyBytes,
        );
        return azureUrl;
      } else {
        debugPrint(
          'Échec du téléchargement depuis ZegoCloud: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Erreur lors du téléchargement/upload: $e');
      return null;
    }
  }

  /// Crée un enregistrement fictif pour les tests (à supprimer en production)
  static Future<bool> _createDummyRecording(String liveId) async {
    try {
      // Créer une petite vidéo fictive (données binaires minimales)
      final dummyVideoData = _generateDummyVideoData();

      // Uploader vers Azure Blob Storage
      final recordingUrl = await AzureStorageService.uploadRecording(
        liveId,
        dummyVideoData,
      );

      if (recordingUrl != null) {
        // Mettre à jour l'URL d'enregistrement dans Firestore
        await FirebaseFirestore.instance.collection('lives').doc(liveId).update(
          {
            'recording_url': recordingUrl,
            'has_recording': true,
            'is_dummy_recording': true, // Marquer comme enregistrement fictif
          },
        );

        debugPrint('Enregistrement fictif créé avec succès: $recordingUrl');
        return true;
      } else {
        debugPrint('Échec de la création de l\'enregistrement fictif');
        return false;
      }
    } catch (e) {
      debugPrint('Erreur lors de la création de l\'enregistrement fictif: $e');
      return false;
    }
  }

  /// Génère des données binaires pour une vidéo fictive
  static Uint8List _generateDummyVideoData() {
    // Créer une petite séquence de bytes qui ressemble à un header de fichier vidéo
    final List<int> dummyData = [
      // Header MP4 fictif
      0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70, // ftyp
      0x69, 0x73, 0x6F, 0x6D, 0x00, 0x00, 0x02, 0x00, // isom
      0x69, 0x73, 0x6F, 0x6D, 0x69, 0x73, 0x6F, 0x32, // isom2
      0x61, 0x76, 0x63, 0x31, 0x6D, 0x70, 0x34, 0x31, // avc1 mp41
    ];

    // Ajouter des données supplémentaires pour simuler une petite vidéo
    for (int i = 0; i < 1000; i++) {
      dummyData.add(i % 256);
    }

    return Uint8List.fromList(dummyData);
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
