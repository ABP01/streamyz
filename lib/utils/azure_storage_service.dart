import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AzureStorageService {
  // Configuration Azure avec le SAS token fourni par l'utilisateur
  static const String _storageAccount = 'streamyzstorage';
  static const String _containerName = 'livespasses';
  static const String _sasToken =
      'sp=racwdl&st=2025-08-05T16:30:12Z&se=2025-09-30T00:45:12Z&sv=2024-11-04&sr=c&sig=Vu%2BjnQg8vv3VebczR0Lb2mm4p75X%2FwfFO2jzSIS%2BPVk%3D';

  static String get _baseUrl =>
      'https://$_storageAccount.blob.core.windows.net/$_containerName';

  /// Upload un fichier d'enregistrement vers Azure Blob Storage
  static Future<String?> uploadRecording(
    String liveId,
    Uint8List recordingData,
  ) async {
    try {
      final fileName = 'live_$liveId.mp4';
      final url = '$_baseUrl/$fileName?$_sasToken';

      final response = await http.put(
        Uri.parse(url),
        headers: {'x-ms-blob-type': 'BlockBlob', 'Content-Type': 'video/mp4'},
        body: recordingData,
      );

      if (response.statusCode == 201) {
        debugPrint('Enregistrement uploadé avec succès: $fileName');
        return '$_baseUrl/$fileName'; // URL publique sans SAS token pour lecture
      } else {
        debugPrint(
          'Erreur upload Azure: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'upload vers Azure: $e');
      return null;
    }
  }

  /// Récupère la liste des enregistrements disponibles
  static Future<List<AzureBlobItem>> getRecordingsList() async {
    try {
      final url = '$_baseUrl?restype=container&comp=list&$_sasToken';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return _parseXmlBlobList(response.body);
      } else {
        debugPrint('Erreur récupération liste Azure: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la liste Azure: $e');
      return [];
    }
  }

  /// Parse la réponse XML d'Azure pour extraire la liste des blobs
  static List<AzureBlobItem> _parseXmlBlobList(String xmlContent) {
    final List<AzureBlobItem> items = [];

    try {
      // Parse simple du XML pour extraire les informations des blobs
      final blobMatches = RegExp(
        r'<Blob>(.*?)</Blob>',
        dotAll: true,
      ).allMatches(xmlContent);

      for (final match in blobMatches) {
        final blobContent = match.group(1) ?? '';

        final nameMatch = RegExp(r'<Name>(.*?)</Name>').firstMatch(blobContent);
        final lastModifiedMatch = RegExp(
          r'<Last-Modified>(.*?)</Last-Modified>',
        ).firstMatch(blobContent);
        final sizeMatch = RegExp(
          r'<Content-Length>(\d+)</Content-Length>',
        ).firstMatch(blobContent);

        if (nameMatch != null) {
          final name = nameMatch.group(1) ?? '';
          final lastModified = lastModifiedMatch?.group(1) ?? '';
          final size = int.tryParse(sizeMatch?.group(1) ?? '0') ?? 0;

          // Extraire l'ID du live depuis le nom du fichier
          final liveIdMatch = RegExp(r'live_(.+)\.mp4').firstMatch(name);
          if (liveIdMatch != null) {
            final liveId = liveIdMatch.group(1) ?? '';

            items.add(
              AzureBlobItem(
                name: name,
                liveId: liveId,
                url: '$_baseUrl/$name',
                lastModified: DateTime.tryParse(lastModified) ?? DateTime.now(),
                size: size,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur parsing XML Azure: $e');
    }

    return items;
  }

  /// Génère une URL avec SAS token pour lecture sécurisée
  static String getSecureUrl(String blobName) {
    return '$_baseUrl/$blobName?$_sasToken';
  }

  /// Vérifie si un enregistrement existe pour un live donné
  static Future<bool> recordingExists(String liveId) async {
    try {
      final fileName = 'live_$liveId.mp4';
      final url = '$_baseUrl/$fileName?$_sasToken';

      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erreur vérification existence: $e');
      return false;
    }
  }

  /// Supprime un enregistrement (si nécessaire)
  static Future<bool> deleteRecording(String liveId) async {
    try {
      final fileName = 'live_$liveId.mp4';
      final url = '$_baseUrl/$fileName?$_sasToken';

      final response = await http.delete(Uri.parse(url));
      return response.statusCode == 202;
    } catch (e) {
      debugPrint('Erreur suppression: $e');
      return false;
    }
  }
}

/// Modèle pour représenter un élément blob Azure
class AzureBlobItem {
  final String name;
  final String liveId;
  final String url;
  final DateTime lastModified;
  final int size;

  AzureBlobItem({
    required this.name,
    required this.liveId,
    required this.url,
    required this.lastModified,
    required this.size,
  });

  @override
  String toString() {
    return 'AzureBlobItem{name: $name, liveId: $liveId, size: $size}';
  }
}
