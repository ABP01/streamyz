import 'package:flutter/material.dart';

import '../screens/zego_live_page.dart';

/// Exemple d'utilisation de la page ZegoLivePage personnalisée
///
/// Cette page inclut maintenant :
/// - Chat en temps réel avec défilement automatique
/// - Système de likes et roses avec animations
/// - Overlay avec profil du host, bouton suivre/ne plus suivre
/// - Statistiques en temps réel (spectateurs, likes, cadeaux)
/// - Actions du host : arrêter le live, inviter des amis
/// - Système de signalement pour les spectateurs
/// - Interface utilisateur moderne et fluide

class LivePageExample extends StatelessWidget {
  const LivePageExample({super.key});

  // Exemple pour rejoindre un live en tant que spectateur
  void _joinAsViewer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ZegoLivePage(
          liveID: 'live_123',
          userID: 'user_456',
          userName: 'Spectateur',
          isHost: false,
          hostID: 'host_789', // ID du host du live
        ),
      ),
    );
  }

  // Exemple pour démarrer un live en tant que host
  void _startAsHost(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ZegoLivePage(
          liveID: 'live_123',
          userID: 'host_789',
          userName: 'HostName',
          isHost: true,
          hostID: 'host_789', // Son propre ID
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exemple Live Page')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _joinAsViewer(context),
              child: const Text('Rejoindre en tant que spectateur'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _startAsHost(context),
              child: const Text('Démarrer un live'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fonctionnalités disponibles dans la page ZegoLivePage :
/// 
/// 🎥 STREAMING
/// - Streaming vidéo en temps réel via Zego
/// - Configuration différente pour host/spectateur
/// - Gestion automatique de la connexion
/// 
/// 💬 CHAT
/// - Chat en temps réel avec Firestore
/// - Défilement automatique des messages
/// - Badge spécial pour le host
/// - Interface moderne avec overlay semi-transparent
/// 
/// ❤️ INTERACTIONS
/// - Système de likes avec animations flottantes
/// - Envoi de roses (cadeaux virtuels)
/// - Animations personnalisées pour chaque interaction
/// - Mise à jour en temps réel des statistiques
/// 
/// 👤 PROFIL & SUIVI
/// - Affichage du profil du host (nom, avatar, stats)
/// - Bouton suivre/ne plus suivre en temps réel
/// - Modal avec détails complets du profil
/// - Badge premium pour les utilisateurs premium
/// 
/// 📊 STATISTIQUES
/// - Nombre de spectateurs en temps réel
/// - Compteur de likes en direct
/// - Total des cadeaux reçus
/// - Mise à jour automatique via StreamBuilder
/// 
/// ⚙️ ACTIONS HOST
/// - Bouton pour arrêter le live avec confirmation
/// - Fonction d'invitation via partage (share_plus)
/// - Gestion automatique de la fin du live
/// 
/// 🚩 MODÉRATION
/// - Bouton signaler pour les spectateurs
/// - Système de reports stocké dans Firestore
/// - Interface simple et accessible
/// 
/// 🎨 INTERFACE
/// - Design moderne avec overlays semi-transparents
/// - Animations fluides pour les interactions
/// - Responsive design pour tous les écrans
/// - Toggle chat pour optimiser l'espace d'écran 