import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'live_feed.dart';
import 'live_stream.dart';

class LiveDemoPage extends StatefulWidget {
  const LiveDemoPage({super.key});

  @override
  State<LiveDemoPage> createState() => _LiveDemoPageState();
}

class _LiveDemoPageState extends State<LiveDemoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Live Demo', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo ou icône
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.blue, Colors.cyan],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.live_tv, color: Colors.white, size: 60),
              ),

              const SizedBox(height: 40),

              // Titre
              const Text(
                'Interface Live Immersive',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Description
              const Text(
                'Découvrez les lives en mode TikTok\navec interactions en temps réel',
                style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.5),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 60),

              // Boutons d'action
              Column(
                children: [
                  // Rejoindre les lives
                  _buildActionButton(
                    icon: Icons.play_circle_fill,
                    title: 'Rejoindre les Lives',
                    subtitle: 'Faites défiler et interagissez',
                    gradient: const LinearGradient(
                      colors: [Colors.red, Colors.orange],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LiveFeedPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Démarrer un live
                  _buildActionButton(
                    icon: Icons.videocam,
                    title: 'Démarrer un Live',
                    subtitle: 'Commencez votre streaming',
                    gradient: const LinearGradient(
                      colors: [Colors.purple, Colors.blue],
                    ),
                    onTap: () {
                      _startLive();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Fonctionnalités
              _buildFeaturesList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fonctionnalités',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            icon: Icons.swipe_vertical,
            title: 'Défilement vertical',
            description: 'Naviguez entre les lives comme sur TikTok',
          ),
          _buildFeatureItem(
            icon: Icons.favorite,
            title: 'Interactions temps réel',
            description: 'Envoyez des cœurs et cadeaux instantanément',
          ),
          _buildFeatureItem(
            icon: Icons.card_giftcard,
            title: 'Cadeaux virtuels',
            description: 'Cœurs, étoiles, diamants avec animations',
          ),
          _buildFeatureItem(
            icon: Icons.auto_awesome,
            title: 'Animations fluides',
            description: 'Effets visuels immersifs et réactifs',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startLive() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Connectez-vous pour démarrer un live');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LiveStreamBasePage()),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
