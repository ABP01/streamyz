import 'package:flutter/material.dart';

/// Exemple de configuration des boutons dans ZegoUIKit
///
/// CONFIGURATION ACTUELLE :
///
/// 🎯 HOST (Animateur) :
/// ✅ Bouton Micro (ON/OFF)
/// ✅ Bouton Caméra (ON/OFF)
/// ✅ Bouton Flip Caméra (Avant/Arrière)
/// ❌ Tous les autres boutons ZegoUIKit supprimés
///
/// 👥 AUDIENCE (Spectateurs) :
/// ❌ Aucun bouton ZegoUIKit (interface clean)
/// ✅ Nos boutons personnalisés uniquement
///
/// 📱 INTERFACE PERSONNALISÉE :
/// - Chat toggle avec overlay
/// - Boutons likes et roses
/// - Profil du host cliquable
/// - Statistiques en temps réel
/// - Actions host (arrêter, inviter)
/// - Signalement pour spectateurs

class CustomButtonsExample extends StatelessWidget {
  const CustomButtonsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration Boutons ZegoUIKit'),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎮 Configuration des Boutons',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(height: 20),

            ConfigurationCard(
              role: 'HOST (Animateur)',
              color: Colors.red,
              buttons: [
                '🎤 Bouton Micro - Activer/Désactiver le microphone',
                '📹 Bouton Caméra - Activer/Désactiver la caméra',
                '🔄 Bouton Flip - Basculer caméra avant/arrière',
              ],
              description:
                  'Les boutons ZegoUIKit essentiels pour contrôler le stream',
            ),

            SizedBox(height: 16),

            ConfigurationCard(
              role: 'AUDIENCE (Spectateurs)',
              color: Colors.blue,
              buttons: [
                '❌ Aucun bouton ZegoUIKit',
                '✨ Interface 100% personnalisée',
                '💬 Chat via nos widgets',
                '❤️ Interactions via nos boutons',
              ],
              description:
                  'Interface épurée avec nos fonctionnalités personnalisées',
            ),

            SizedBox(height: 20),

            Text(
              '⚙️ Nos Boutons Personnalisés',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 12),

            CustomButtonsList(),
          ],
        ),
      ),
    );
  }
}

class ConfigurationCard extends StatelessWidget {
  final String role;
  final Color color;
  final List<String> buttons;
  final String description;

  const ConfigurationCard({
    super.key,
    required this.role,
    required this.color,
    required this.buttons,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...buttons.map(
              (button) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(button, style: const TextStyle(fontSize: 14)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomButtonsList extends StatelessWidget {
  const CustomButtonsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fonctionnalités Intégrées dans notre Foreground :',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ..._buildCustomFeaturesList(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCustomFeaturesList() {
    final features = [
      '💬 Chat en temps réel avec toggle',
      '❤️ Bouton Like avec animation',
      '🌹 Bouton Rose (cadeau virtuel)',
      '👤 Profil host avec infos complètes',
      '➕ Bouton Suivre/Ne plus suivre',
      '📊 Statistiques live (spectateurs, likes, cadeaux)',
      '🚩 Bouton Signaler (pour spectateurs)',
      '⏹️ Bouton Arrêter live (pour host)',
      '📤 Bouton Inviter amis (pour host)',
      '🎨 Background dégradé personnalisé',
    ];

    return features
        .map(
          (feature) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(feature, style: const TextStyle(fontSize: 13)),
          ),
        )
        .toList();
  }
}

/// Code de configuration utilisé :
/// 
/// ```dart
/// // POUR LE HOST :
/// ..bottomMenuBar.hostButtons = [
///   ZegoLiveStreamingMenuBarButtonName.toggleMicrophoneButton,
///   ZegoLiveStreamingMenuBarButtonName.toggleCameraButton,
///   ZegoLiveStreamingMenuBarButtonName.switchCameraButton,
/// ]
/// 
/// // POUR L'AUDIENCE :
/// ..bottomMenuBar.maxCount = 0  // Aucun bouton ZegoUIKit
/// 
/// // INTÉGRATION DE NOS WIDGETS :
/// ..foreground = _buildCustomForeground()  // Nos fonctionnalités
/// ..background = _buildCustomBackground()  // Notre design
/// ```
/// 
/// Cette configuration garantit :
/// ✅ Interface épurée sans éléments parasites
/// ✅ Contrôles essentiels pour le host
/// ✅ Expérience optimisée pour les spectateurs
/// ✅ Intégration parfaite de nos fonctionnalités personnalisées 