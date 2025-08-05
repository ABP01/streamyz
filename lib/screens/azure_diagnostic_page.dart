import 'package:flutter/material.dart';

import '../utils/azure_diagnostic_tool.dart';

/// Page de diagnostic pour tester et vérifier Azure Blob Storage
class AzureDiagnosticPage extends StatefulWidget {
  const AzureDiagnosticPage({super.key});

  @override
  State<AzureDiagnosticPage> createState() => _AzureDiagnosticPageState();
}

class _AzureDiagnosticPageState extends State<AzureDiagnosticPage> {
  String _diagnosticResults =
      'Appuyez sur un bouton pour commencer le diagnostic...';
  bool _isRunning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Diagnostic Azure'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête d'information
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔍 Diagnostic Azure Streamyz',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Utilisez ces outils pour vérifier pourquoi vous ne voyez pas les récapitulatifs sur Azure.',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Container: livespasses',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Token valide jusqu\'au: 6 août 2025 00:34',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Boutons de diagnostic
            _buildDiagnosticButton(
              '🔗 Tester Connexion Azure',
              'Vérifie si Azure est accessible avec le token actuel',
              () => _runDiagnostic(
                () => AzureDiagnosticTool.checkAzureConnection(),
              ),
            ),

            const SizedBox(height: 8),

            _buildDiagnosticButton(
              '📺 Vérifier Lives Firestore',
              'Cherche les lives marqués comme enregistrés dans la base',
              () => _runDiagnostic(
                () => AzureDiagnosticTool.checkFirestoreLives(),
              ),
            ),

            const SizedBox(height: 8),

            _buildDiagnosticButton(
              '🧪 Créer Fichier Test',
              'Upload un fichier de test pour vérifier que l\'upload fonctionne',
              () => _runDiagnostic(() => AzureDiagnosticTool.createTestFile()),
            ),

            const SizedBox(height: 8),

            _buildDiagnosticButton(
              '🚀 Diagnostic Complet',
              'Lance tous les tests en une fois',
              () => _runDiagnostic(
                () => AzureDiagnosticTool.runCompleteDiagnostic(),
              ),
            ),

            const SizedBox(height: 16),

            // Zone de résultats
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.terminal, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(
                            'Résultats du diagnostic',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (_isRunning)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _diagnosticResults,
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Instructions
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Instructions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Si container vide → Créez un nouveau live test\n'
                      '• Si erreurs de connexion → Token SAS expiré\n'
                      '• Regardez les logs détaillés dans la console',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticButton(
    String title,
    String description,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: _isRunning ? null : onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.centerLeft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Future<void> _runDiagnostic(
    Future<void> Function() diagnosticFunction,
  ) async {
    setState(() {
      _isRunning = true;
      _diagnosticResults = 'Exécution du diagnostic...\n';
    });

    try {
      // Capturer les logs de debug
      final originalDebugPrint = debugPrint;
      final logBuffer = StringBuffer();

      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          logBuffer.writeln(message);
          if (mounted) {
            setState(() {
              _diagnosticResults = logBuffer.toString();
            });
          }
        }
        originalDebugPrint?.call(message, wrapWidth: wrapWidth);
      };

      await diagnosticFunction();

      // Restaurer debugPrint
      debugPrint = originalDebugPrint;
    } catch (e) {
      setState(() {
        _diagnosticResults += '\n❌ Erreur: $e';
      });
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }
}
