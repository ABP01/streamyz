import 'package:flutter/material.dart';

import 'live_feed.dart';

class LiveWelcomePage extends StatelessWidget {
  const LiveWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                scrollDirection: Axis.vertical,
                children: [
                  _buildWelcomeSlide(
                    icon: Icons.swipe_vertical,
                    title: 'Découvrez les Lives',
                    description:
                        'Faites défiler verticalement pour découvrir tous les lives en cours',
                    color: Colors.blue,
                  ),
                  _buildWelcomeSlide(
                    icon: Icons.card_giftcard,
                    title: 'Envoyez des Cadeaux',
                    description:
                        'Soutenez vos streamers préférés avec des cadeaux virtuels',
                    color: Colors.red,
                  ),
                  _buildWelcomeSlide(
                    icon: Icons.chat_bubble,
                    title: 'Chat Intégré',
                    description:
                        'Utilisez le chat natif ZegoCloud pour interagir avec la communauté',
                    color: Colors.green,
                  ),
                  _buildWelcomeSlide(
                    icon: Icons.leaderboard,
                    title: 'Classements',
                    description:
                        'Consultez les classements des meilleurs streamers et généreux donateurs',
                    color: Colors.amber,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LiveFeedPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Commencer à explorer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Retour',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSlide({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
            ),
            child: Icon(icon, color: color, size: 60),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
