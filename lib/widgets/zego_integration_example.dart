import 'package:flutter/material.dart';

/// Exemple de l'intégration directe dans ZegoUIKit
///
/// AVANT : Overlays au-dessus de ZegoUIKit
/// - Les widgets étaient dans un Stack au-dessus du ZegoUIKitPrebuiltLiveStreaming
/// - Risque de conflits avec l'UI native de Zego
/// - Moins intégré visuellement
///
/// MAINTENANT : Intégration native dans ZegoUIKit
/// - Utilisation de config.foreground pour intégrer les widgets personnalisés
/// - Utilisation de config.background pour le design personnalisé
/// - Désactivation des éléments UI natifs non désirés
/// - Intégration parfaite avec le cycle de vie de ZegoUIKit

class ZegoIntegrationExample extends StatelessWidget {
  const ZegoIntegrationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intégration ZegoUIKit'),
        backgroundColor: Colors.blue,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎯 Avantages de l\'intégration native ZegoUIKit',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 16),

            FeatureCard(
              icon: Icons.integration_instructions,
              title: 'Intégration Native',
              description:
                  'Les widgets personnalisés sont intégrés directement dans le foreground de ZegoUIKit, garantissant une compatibilité parfaite.',
            ),

            FeatureCard(
              icon: Icons.layers_clear,
              title: 'UI Propre',
              description:
                  'Désactivation des éléments UI natifs non nécessaires (boutons close, more, message) pour une interface sur mesure.',
            ),

            FeatureCard(
              icon: Icons.palette,
              title: 'Background Personnalisé',
              description:
                  'Utilisation de config.background pour appliquer un dégradé personnalisé sous le stream vidéo.',
            ),

            FeatureCard(
              icon: Icons.memory,
              title: 'Performance Optimisée',
              description:
                  'Meilleure gestion mémoire et moins de conflits de rendu par rapport aux overlays externes.',
            ),

            FeatureCard(
              icon: Icons.build,
              title: 'Configuration Flexible',
              description:
                  'Configurations séparées pour host et audience avec des fonctionnalités adaptées à chaque rôle.',
            ),
          ],
        ),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.blue, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Configuration technique utilisée :
/// 
/// ```dart
/// ZegoUIKitPrebuiltLiveStreamingConfig _getHostConfig() {
///   return ZegoUIKitPrebuiltLiveStreamingConfig.host()
///     ..audioVideoView.showAvatarInAudioMode = true
///     ..topMenuBar.showCloseButton = false
///     ..bottomMenuBar.showInRoomMessageButton = false
///     ..foreground = _buildCustomForeground()  // NOS WIDGETS ICI
///     ..background = _buildCustomBackground(); // DESIGN PERSONNALISÉ
/// }
/// ```
/// 
/// Widgets intégrés dans le foreground :
/// - LiveOverlayWidget : Profil host, boutons follow/report
/// - LiveInteractionsWidget : Likes et roses animés 
/// - LiveStatsWidget : Statistiques en temps réel
/// - LiveChatWidget : Chat en overlay toggle
/// 
/// Cette approche garantit que tous nos widgets personnalisés
/// fonctionnent parfaitement avec ZegoUIKit sans conflits. 