import 'package:flutter/material.dart';

import '../utils/permission_manager.dart';
import '../utils/video_recording_manager.dart';
import '../widgets/video_recording_indicator_widget.dart';

class VideoRecordingSettingsScreen extends StatefulWidget {
  const VideoRecordingSettingsScreen({super.key});

  @override
  State<VideoRecordingSettingsScreen> createState() =>
      _VideoRecordingSettingsScreenState();
}

class _VideoRecordingSettingsScreenState
    extends State<VideoRecordingSettingsScreen> {
  bool _isLoading = true;
  bool _hasVideoPermissions = false;
  bool _hasAudioPermissions = false;
  bool _hasStoragePermissions = false;
  Map<String, dynamic> _recordingStats = {};

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    await VideoRecordingManager.initialize();
    await _checkPermissions();
    _updateRecordingStats();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _checkPermissions() async {
    try {
      _hasVideoPermissions =
          await VideoRecordingManager.checkVideoPermissions();
      _hasAudioPermissions = await PermissionManager.hasEssentialPermissions();
      _hasStoragePermissions =
          await PermissionManager.hasEssentialPermissions();
    } catch (e) {
      debugPrint('Erreur vérification permissions: $e');
    }
  }

  void _updateRecordingStats() {
    setState(() {
      _recordingStats = VideoRecordingManager.getRecordingStats();
    });
  }

  Future<void> _requestPermissions() async {
    final success = await VideoRecordingManager.requestVideoPermissions();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Permissions vidéo accordées'),
          backgroundColor: Colors.green,
        ),
      );
      await _checkPermissions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Certaines permissions ont été refusées'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Enregistrement Vidéo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec informations principales
                  _buildHeaderCard(),

                  const SizedBox(height: 20),

                  // État des permissions
                  _buildPermissionsSection(),

                  const SizedBox(height: 20),

                  // Informations sur l'enregistrement en cours
                  if (_recordingStats['isRecording'] == true) ...[
                    _buildRecordingInfoSection(),
                    const SizedBox(height: 20),
                  ],

                  // Fonctionnalités disponibles
                  _buildFeaturesSection(),

                  const SizedBox(height: 20),

                  // Guide d'utilisation
                  _buildUsageGuideSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.videocam, size: 48, color: Colors.white),
          const SizedBox(height: 16),
          const Text(
            'Enregistrement Vidéo HD',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Capture d\'écran en temps réel avec audio synchronisé',
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          RecordingStatusBadge(
            isRecording: _recordingStats['isRecording'] ?? false,
            statusText: _recordingStats['isRecording'] == true
                ? 'Enregistrement actif'
                : 'Prêt à enregistrer',
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security, color: Color(0xFF667eea)),
              const SizedBox(width: 12),
              const Text(
                'Permissions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (!_hasVideoPermissions ||
                  !_hasAudioPermissions ||
                  !_hasStoragePermissions)
                ElevatedButton.icon(
                  onPressed: _requestPermissions,
                  icon: const Icon(Icons.admin_panel_settings, size: 16),
                  label: const Text('Configurer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          _buildPermissionItem(
            'Microphone',
            'Enregistrement audio synchronisé',
            _hasAudioPermissions,
            Icons.mic,
          ),
          _buildPermissionItem(
            'Stockage',
            'Sauvegarde des vidéos',
            _hasStoragePermissions,
            Icons.storage,
          ),
          _buildPermissionItem(
            'Enregistrement d\'écran',
            'Capture vidéo en temps réel',
            _hasVideoPermissions,
            Icons.videocam,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(
    String title,
    String description,
    bool granted,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: granted
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: granted ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
          Icon(
            granted ? Icons.check_circle : Icons.cancel,
            color: granted ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingInfoSection() {
    return RecordingInfoPanel(recordingStats: _recordingStats);
  }

  Widget _buildFeaturesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Color(0xFF667eea)),
              const SizedBox(width: 12),
              const Text(
                'Fonctionnalités Avancées',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildFeatureItem(
            '🎥 Capture Vidéo HD',
            'Enregistrement d\'écran en résolution native',
            true,
          ),
          _buildFeatureItem(
            '🎵 Audio Synchronisé',
            'Son de haute qualité parfaitement synchronisé',
            true,
          ),
          _buildFeatureItem(
            '🗜️ Compression Intelligente',
            'Optimisation automatique de la taille des fichiers',
            true,
          ),
          _buildFeatureItem(
            '⚡ Post-Processing',
            'Traitement automatique après enregistrement',
            true,
          ),
          _buildFeatureItem(
            '☁️ Upload Azure',
            'Sauvegarde sécurisée dans le cloud',
            true,
          ),
          _buildFeatureItem(
            '📱 Interface Intuitive',
            'Indicateurs en temps réel et contrôles simples',
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description, bool available) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: available ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageGuideSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Text(
                'Guide d\'Utilisation',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildGuideStep(
            '1',
            'Démarrer un Live',
            'L\'enregistrement commence automatiquement',
          ),
          _buildGuideStep(
            '2',
            'Pendant le Live',
            'L\'indicateur rouge montre l\'état d\'enregistrement',
          ),
          _buildGuideStep(
            '3',
            'Fin du Live',
            'L\'enregistrement s\'arrête et le post-processing démarre',
          ),
          _buildGuideStep(
            '4',
            'Voir l\'Enregistrement',
            'Retrouvez vos vidéos dans l\'onglet "Pour vous"',
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
