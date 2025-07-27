import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/zego_live_page.dart';

class ExplorerScreen extends StatefulWidget {
  const ExplorerScreen({super.key});

  @override
  State<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends State<ExplorerScreen> {
  String _currentUserID = '';
  PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentUserID = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lives en cours'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('lives')
            .where('is_live', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.tv_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucun live en cours',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Soyez le premier à démarrer un live !',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final lives = snapshot.data!.docs;

          // Tri côté client par livestarttime (plus récents en premier)
          lives.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['livestarttime'] ?? 0;
            final bTime = bData['livestarttime'] ?? 0;
            return bTime.compareTo(aTime); // Décroissant
          });

          return RefreshIndicator(
            onRefresh: () async {
              // Force refresh by rebuilding
              setState(() {});
            },
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              reverse: true, // Défilement du bas vers le haut
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: lives.length,
              itemBuilder: (context, index) {
                final liveData = lives[index].data() as Map<String, dynamic>;
                return FullScreenLiveCard(
                  liveData: liveData,
                  currentUserID: _currentUserID,
                  isCurrentPage: index == _currentPage,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class FullScreenLiveCard extends StatelessWidget {
  final Map<String, dynamic> liveData;
  final String currentUserID;
  final bool isCurrentPage;

  const FullScreenLiveCard({
    super.key,
    required this.liveData,
    required this.currentUserID,
    required this.isCurrentPage,
  });

  Future<void> _joinLive(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Récupérer le nom d'utilisateur depuis Firestore
      String userName = 'Utilisateur';
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data() ?? {};
          userName = userData['username'] ?? 'Utilisateur';
        }
      } catch (e) {
        debugPrint('Erreur lors de la récupération du nom d\'utilisateur: $e');
      }

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ZegoLivePage(
              liveID: liveData['live_id'] ?? '',
              userID: user.uid,
              userName: userName,
              isHost: false,
              hostID: liveData['id_host'],
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de la connexion au live: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la connexion au live'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewerCount = liveData['stats']?['account'] ?? 0;
    final likeCount = liveData['stats']?['likes'] ?? 0;
    final giftCount = liveData['totalgift'] ?? 0;
    final thumbnail = liveData['thumbnail'] ?? '';
    final title = liveData['desc'] ?? 'Live sans titre';
    final hostName = liveData['name_host'] ?? 'Host inconnu';
    final hostAvatar = liveData['avatar_host'] ?? '';

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black87, Colors.purple.shade900],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Image de fond ou gradient
          if (thumbnail.isNotEmpty)
            Container(
              width: double.infinity,
              height: double.infinity,
              child: Image.network(
                thumbnail,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildDefaultBackground(),
              ),
            )
          else
            _buildDefaultBackground(),

          // Overlay sombre pour la lisibilité
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Contenu principal
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Badge LIVE en haut
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.circle,
                              color: Colors.white,
                              size: 10,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Nombre de spectateurs
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.visibility,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatCount(viewerCount),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Informations en bas
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profil du host
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundImage: hostAvatar.isNotEmpty
                                ? NetworkImage(hostAvatar)
                                : null,
                            backgroundColor: Colors.purple,
                            child: hostAvatar.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 30,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hostName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Statistiques
                      Row(
                        children: [
                          _buildStatChip(Icons.favorite, likeCount, Colors.red),
                          const SizedBox(width: 12),
                          _buildStatChip(
                            Icons.card_giftcard,
                            giftCount,
                            Colors.amber,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Bouton rejoindre
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => _joinLive(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 8,
                            shadowColor: Colors.purple.withOpacity(0.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_arrow, size: 24),
                              const SizedBox(width: 8),
                              const Text(
                                'Rejoindre le live',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            _formatCount(count),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.live_tv, color: Colors.white, size: 80),
      ),
    );
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }
}
