import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/zego_live_page.dart';
import '../widgets/user_search_widget.dart';

class ExplorerScreen extends StatefulWidget {
  const ExplorerScreen({super.key});

  @override
  State<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends State<ExplorerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorer'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Lives en cours', icon: Icon(Icons.live_tv)),
            Tab(text: 'Utilisateurs', icon: Icon(Icons.people)),
          ],
          indicatorColor: Colors.purple,
          labelColor: Colors.purple,
          unselectedLabelColor: Colors.grey,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [LiveStreamsTab(), UserSearchWidget()],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class LiveStreamsTab extends StatefulWidget {
  const LiveStreamsTab({super.key});

  @override
  State<LiveStreamsTab> createState() => _LiveStreamsTabState();
}

class _LiveStreamsTabState extends State<LiveStreamsTab> {
  String _currentUserID = '';

  @override
  void initState() {
    super.initState();
    _currentUserID = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
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
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio:
                  0.8, // Augmenté de 0.75 à 0.8 pour plus d'espace
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: lives.length,
            itemBuilder: (context, index) {
              final liveData = lives[index].data() as Map<String, dynamic>;
              return LiveStreamCard(
                liveData: liveData,
                currentUserID: _currentUserID,
              );
            },
          ),
        );
      },
    );
  }
}

class LiveStreamCard extends StatelessWidget {
  final Map<String, dynamic> liveData;
  final String currentUserID;

  const LiveStreamCard({
    super.key,
    required this.liveData,
    required this.currentUserID,
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

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail/Couverture
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Image de couverture ou gradient par défaut
                  if (thumbnail.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Image.network(
                        thumbnail,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildDefaultThumbnail(),
                      ),
                    )
                  else
                    _buildDefaultThumbnail(),

                  // Overlay avec badge LIVE
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
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
                            size: 8,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Nombre de spectateurs
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.visibility,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatCount(viewerCount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Informations du live
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Titre du live
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Informations du host
                  Text(
                    hostName,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),

                  // Statistiques et bouton rejoindre
                  Column(
                    children: [
                      // Statistiques
                      Row(
                        children: [
                          Icon(Icons.favorite, color: Colors.red, size: 12),
                          Text(
                            ' ${_formatCount(likeCount)}',
                            style: const TextStyle(fontSize: 10),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.card_giftcard,
                            color: Colors.amber,
                            size: 12,
                          ),
                          Text(
                            ' ${_formatCount(giftCount)}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Bouton rejoindre
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _joinLive(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(double.infinity, 28),
                          ),
                          child: const Text(
                            'Rejoindre',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
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

  Widget _buildDefaultThumbnail() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const Center(
        child: Icon(Icons.live_tv, color: Colors.white, size: 40),
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
