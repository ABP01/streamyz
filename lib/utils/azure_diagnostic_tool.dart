import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Outil de diagnostic pour vérifier l'état des récapitulatifs Azure
class AzureDiagnosticTool {
  static const String _storageAccount = 'streamyzstorage';
  static const String _containerName = 'livespasses';
  static const String _sasToken =
      'sp=racwdl&st=2025-08-05T16:30:12Z&se=2025-09-30T00:45:12Z&sv=2024-11-04&sr=c&sig=Vu%2BjnQg8vv3VebczR0Lb2mm4p75X%2FwfFO2jzSIS%2BPVk%3D';

  static String get _baseUrl =>
      'https://$_storageAccount.blob.core.windows.net/$_containerName';

  /// Vérifie la connexion Azure et liste tous les fichiers
  static Future<void> checkAzureConnection() async {
    debugPrint('🔍 === DIAGNOSTIC AZURE STREAMYZ ===');
    debugPrint('📅 Date: ${DateTime.now()}');
    debugPrint('🔗 Container: $_containerName');

    try {
      // Test de connexion
      final url = '$_baseUrl?restype=container&comp=list&$_sasToken';
      debugPrint('🌐 URL de test: ${url.substring(0, 100)}...');

      final response = await http.get(Uri.parse(url));
      debugPrint('📡 Code de réponse: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ Connexion Azure réussie !');
        _parseAndDisplayFiles(response.body);
      } else {
        debugPrint('❌ Erreur de connexion Azure: ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 Exception lors du test Azure: $e');
    }
  }

  /// Parse et affiche la liste des fichiers
  static void _parseAndDisplayFiles(String xmlContent) {
    debugPrint('📁 === FICHIERS SUR AZURE ===');

    // Parse simple du XML pour extraire les noms de fichiers
    final blobMatches = RegExp(r'<Name>(.*?)</Name>').allMatches(xmlContent);

    if (blobMatches.isEmpty) {
      debugPrint('📭 Container vide - Aucun récapitulatif trouvé');
      debugPrint(
        '💡 Cause possible: Aucun live n\'a encore été enregistré avec succès',
      );
    } else {
      debugPrint('📦 ${blobMatches.length} fichier(s) trouvé(s):');

      for (final match in blobMatches) {
        final fileName = match.group(1) ?? '';
        debugPrint('   📄 $fileName');

        // Analyser le type de fichier
        if (fileName.endsWith('.mp4')) {
          debugPrint('      🎥 Type: Enregistrement vidéo');
        } else if (fileName.endsWith('.gif')) {
          debugPrint('      🖼️ Type: Enregistrement d\'écran GIF');
        } else if (fileName.endsWith('.json')) {
          debugPrint('      📊 Type: Métadonnées JSON');
        } else {
          debugPrint('      ❓ Type: Inconnu');
        }
      }
    }
  }

  /// Vérifie les lives dans Firestore qui devraient avoir des enregistrements
  static Future<void> checkFirestoreLives() async {
    debugPrint('🔍 === VÉRIFICATION FIRESTORE ===');

    try {
      final livesQuery = await FirebaseFirestore.instance
          .collection('lives')
          .where('has_recording', isEqualTo: true)
          .orderBy('liveendtime', descending: true)
          .limit(10)
          .get();

      debugPrint(
        '📺 Lives avec enregistrement dans Firestore: ${livesQuery.docs.length}',
      );

      if (livesQuery.docs.isEmpty) {
        debugPrint('📭 Aucun live marqué comme enregistré dans Firestore');
        debugPrint(
          '💡 Cause possible: Les lives n\'ont pas encore été enregistrés',
        );
      } else {
        for (final doc in livesQuery.docs) {
          final data = doc.data();
          final liveId = doc.id;
          final title = data['title'] ?? 'Sans titre';
          final recordingUrl = data['recording_url'] ?? 'Non défini';
          final recordingStatus = data['recording_status'] ?? 'Inconnu';

          debugPrint('   📺 Live: $liveId');
          debugPrint('      📝 Titre: $title');
          debugPrint('      📊 Statut: $recordingStatus');
          debugPrint('      🔗 URL: $recordingUrl');

          // Vérifier si le fichier existe sur Azure
          if (recordingUrl.contains('azure')) {
            await _checkFileExists(recordingUrl);
          }
        }
      }
    } catch (e) {
      debugPrint('💥 Erreur lors de la vérification Firestore: $e');
    }
  }

  /// Vérifie si un fichier existe sur Azure
  static Future<void> _checkFileExists(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      if (response.statusCode == 200) {
        debugPrint('      ✅ Fichier accessible sur Azure');
      } else {
        debugPrint('      ❌ Fichier non accessible (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('      💥 Erreur de vérification: $e');
    }
  }

  /// Diagnostic complet
  static Future<void> runCompleteDiagnostic() async {
    debugPrint('🚀 === DIAGNOSTIC COMPLET STREAMYZ ===');

    await checkAzureConnection();
    debugPrint('');
    await checkFirestoreLives();

    debugPrint('');
    debugPrint('📋 === RÉSUMÉ ET RECOMMANDATIONS ===');
    debugPrint('1. Si container Azure vide → Créer un nouveau live test');
    debugPrint(
      '2. Si lives Firestore vides → Système d\'enregistrement pas encore utilisé',
    );
    debugPrint('3. Si erreurs de connexion → Vérifier le token SAS');
    debugPrint(
      '4. Pour voir les récaps → Aller dans "Pour vous" après un live',
    );
    debugPrint('🏁 === FIN DU DIAGNOSTIC ===');
  }

  /// Créer un fichier de test sur Azure
  static Future<void> createTestFile() async {
    debugPrint('🧪 Création d\'un fichier de test sur Azure...');

    try {
      final testContent =
          '''
{
  "test": true,
  "message": "Fichier de test créé le ${DateTime.now()}",
  "purpose": "Vérifier que l'upload Azure fonctionne",
  "container": "$_containerName",
  "storage_account": "$_storageAccount"
}
''';

      final fileName = 'test_${DateTime.now().millisecondsSinceEpoch}.json';
      final url = '$_baseUrl/$fileName?$_sasToken';

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'x-ms-blob-type': 'BlockBlob',
          'Content-Type': 'application/json',
        },
        body: testContent,
      );

      if (response.statusCode == 201) {
        debugPrint('✅ Fichier de test créé avec succès: $fileName');
        debugPrint('🔗 URL: $_baseUrl/$fileName');
      } else {
        debugPrint(
          '❌ Échec de création du fichier de test: ${response.statusCode}',
        );
        debugPrint('📄 Réponse: ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 Erreur lors de la création du fichier de test: $e');
    }
  }
}
