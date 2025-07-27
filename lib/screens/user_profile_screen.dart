import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/zego_live_page.dart';
import '../utils/follow_manager.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String? username;

  const UserProfileScreen({super.key, required this.userId, this.username});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String _currentUserID = '';
  bool _isFollowing = false;
  bool _isLoading = false;

  // Statistiques calculées
  int _totalLives = 0;
  int _totalGifts = 0;
  int _totalViewers = 0;
  int _totalLikes = 0;

  @override
  void initState() {
    super.initState();
    _currentUserID = FirebaseAuth.instance.currentUser?.uid ?? '';
    _checkFollowStatus();
    _calculateUserStats();
  }

  Future<void> _checkFollowStatus() async {
    if (_currentUserID.isNotEmpty && _currentUserID != widget.userId) {
      final isFollowing = await FollowManager.isFollowing(
        _currentUserID,
        widget.userId,
      );
      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
        });
      }
    }
  }

  Future<void> _calculateUserStats() async {
    try {
      final livesSnapshot = await FirebaseFirestore.instance
          .collection('lives')
          .where('id_host', isEqualTo: widget.userId)
          .get();

      int totalLives = livesSnapshot.docs.length;
      int totalGifts = 0;
      int totalViewers = 0;
      int totalLikes = 0;

      for (var doc in livesSnapshot.docs) {
        final data = doc.data();
        totalGifts += (data['totalgift'] ?? 0) as int;

        final stats = data['stats'] as Map<String, dynamic>?;
        if (stats != null) {
          totalViewers += (stats['account'] ?? 0) as int;
          totalLikes += (stats['likes'] ?? 0) as int;
        }
      }

      if (mounted) {
        setState(() {
          _totalLives = totalLives;
          _totalGifts = totalGifts;
          _totalViewers = totalViewers;
          _totalLikes = totalLikes;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du calcul des statistiques: $e');
    }
  }

  String _getUserLevel() {
    if (_totalLives >= 50) return 'LÉGENDE';
    if (_totalLives >= 20) return 'EXPERT';
    if (_totalLives >= 10) return 'AVANCÉ';
    if (_totalLives >= 5) return 'INTERMÉDIAIRE';
    if (_totalLives >= 1) return 'DÉBUTANT';
    return 'NOUVEAU';
  }

  Color _getLevelColor() {
    switch (_getUserLevel()) {
      case 'LÉGENDE':
        return Colors.purple;
      case 'EXPERT':
        return Colors.orange;
      case 'AVANCÉ':
        return Colors.blue;
      case 'INTERMÉDIAIRE':
        return Colors.green;
      case 'DÉBUTANT':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  String _formatNumber(int number) {
    if (number < 1000) {
      return number.toString();
    } else if (number < 1000000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
  }

  Future<void> _toggleFollow() async {
    if (_currentUserID.isEmpty || _currentUserID == widget.userId) return;

    setState(() => _isLoading = true);

    try {
      if (_isFollowing) {
        await FollowManager.unfollowUser(_currentUserID, widget.userId);
      } else {
        await FollowManager.followUser(_currentUserID, widget.userId);
      }

      setState(() {
        _isFollowing = !_isFollowing;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFollowing ? 'Utilisateur suivi' : 'Utilisateur non suivi',
          ),
          backgroundColor: _isFollowing ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'action'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.username ?? 'Profil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Utilisateur non trouvé',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final username = userData['username'] ?? 'Utilisateur';
          final bio = userData['bio'] ?? '';
          final avatar = userData['avatar'] ?? '';
          final followersCount = userData['followers'] != null
              ? (userData['followers'] as List).length
              : 0;
          final followingCount = userData['following'] != null
              ? (userData['following'] as List).length
              : 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Avatar avec badge niveau
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: avatar.isNotEmpty
                          ? NetworkImage(avatar)
                          : null,
                      backgroundColor: Colors.purple,
                      child: avatar.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getLevelColor(),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          _getUserLevel(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Nom d'utilisateur
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // Bio
                if (bio.isNotEmpty)
                  Text(
                    bio,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: 24),

                // Statistiques en grille 2x3
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard(
                      'Lives',
                      _formatNumber(_totalLives),
                      Icons.live_tv,
                      Colors.red,
                    ),
                    _buildStatCard(
                      'Cadeaux',
                      _formatNumber(_totalGifts),
                      Icons.card_giftcard,
                      Colors.amber,
                    ),
                    _buildStatCard(
                      'Spectateurs',
                      _formatNumber(_totalViewers),
                      Icons.visibility,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Likes',
                      _formatNumber(_totalLikes),
                      Icons.favorite,
                      Colors.pink,
                    ),
                    _buildStatCard(
                      'Abonnés',
                      _formatNumber(followersCount),
                      Icons.people,
                      Colors.green,
                    ),
                    _buildStatCard(
                      'Abonnements',
                      _formatNumber(followingCount),
                      Icons.person_add,
                      Colors.purple,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Badge de motivation
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getLevelColor().withOpacity(0.2),
                        _getLevelColor().withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getLevelColor().withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(_getLevelIcon(), size: 32, color: _getLevelColor()),
                      const SizedBox(height: 8),
                      Text(
                        '${_getUserLevel()} STREAMER',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getLevelColor(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getMotivationMessage(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Bouton suivre/ne plus suivre
                if (_currentUserID.isNotEmpty &&
                    _currentUserID != widget.userId)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _toggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFollowing
                            ? Colors.grey
                            : Colors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              _isFollowing
                                  ? Icons.person_remove
                                  : Icons.person_add,
                            ),
                      label: Text(
                        _isFollowing ? 'Ne plus suivre' : 'Suivre',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // Lives récents
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Lives récents',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 16),

                // Liste des lives
                SizedBox(
                  height: 400,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('lives')
                        .where('id_host', isEqualTo: widget.userId)
                        .limit(20)
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
                              Icon(Icons.tv_off, size: 48, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Aucun live récent',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
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

                      // Limite à 10 après le tri
                      final limitedLives = lives.take(10).toList();

                      return ListView.builder(
                        itemCount: limitedLives.length,
                        itemBuilder: (context, index) {
                          final liveData =
                              limitedLives[index].data()
                                  as Map<String, dynamic>;
                          final isLive = liveData['is_live'] ?? false;
                          final thumbnail = liveData['thumbnail'] ?? '';
                          final title = liveData['desc'] ?? 'Live sans titre';
                          final startTime = liveData['livestarttime'] ?? 0;
                          final giftCount = liveData['totalgift'] ?? 0;
                          final stats =
                              liveData['stats'] as Map<String, dynamic>?;
                          final viewerCount = stats?['account'] ?? 0;
                          final likeCount = stats?['likes'] ?? 0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.purple.shade100,
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: thumbnail.isNotEmpty
                                          ? Image.network(
                                              thumbnail,
                                              fit: BoxFit.cover,
                                              width: 60,
                                              height: 60,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(
                                                    Icons.live_tv,
                                                    color: Colors.purple,
                                                  ),
                                            )
                                          : const Icon(
                                              Icons.live_tv,
                                              color: Colors.purple,
                                            ),
                                    ),
                                    if (isLive)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Text(
                                            'LIVE',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              title: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isLive
                                        ? 'En direct'
                                        : _formatTimeAgo(startTime),
                                    style: TextStyle(
                                      color: isLive ? Colors.red : Colors.grey,
                                      fontWeight: isLive
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.visibility,
                                        size: 12,
                                        color: Colors.blue,
                                      ),
                                      Text(' ${_formatNumber(viewerCount)}'),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.favorite,
                                        size: 12,
                                        color: Colors.red,
                                      ),
                                      Text(' ${_formatNumber(likeCount)}'),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.card_giftcard,
                                        size: 12,
                                        color: Colors.amber,
                                      ),
                                      Text(' ${_formatNumber(giftCount)}'),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: isLive
                                  ? const Icon(
                                      Icons.play_arrow,
                                      color: Colors.red,
                                    )
                                  : const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                    ),
                              onTap: isLive ? () => _joinLive(liveData) : null,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  IconData _getLevelIcon() {
    switch (_getUserLevel()) {
      case 'LÉGENDE':
        return Icons.emoji_events;
      case 'EXPERT':
        return Icons.star;
      case 'AVANCÉ':
        return Icons.trending_up;
      case 'INTERMÉDIAIRE':
        return Icons.thumb_up;
      case 'DÉBUTANT':
        return Icons.play_arrow;
      default:
        return Icons.person;
    }
  }

  String _getMotivationMessage() {
    switch (_getUserLevel()) {
      case 'LÉGENDE':
        return 'Vous êtes une légende du streaming ! 🏆';
      case 'EXPERT':
        return 'Expert confirmé ! Continuez à briller ! ⭐';
      case 'AVANCÉ':
        return 'Excellent travail ! Vous progressez rapidement ! 📈';
      case 'INTERMÉDIAIRE':
        return 'Bon début ! Continuez sur cette lancée ! 👍';
      case 'DÉBUTANT':
        return 'Bienvenue dans l\'aventure streaming ! 🚀';
      default:
        return 'Créez votre premier live et rejoignez la communauté ! 🎬';
    }
  }

  String _formatTimeAgo(int timestamp) {
    final now = DateTime.now();
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  Future<void> _joinLive(Map<String, dynamic> liveData) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Récupérer le nom d'utilisateur
      String userName = 'Utilisateur';
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() ?? {};
        userName = userData['username'] ?? 'Utilisateur';
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ZegoLivePage(
              liveID: liveData['live_id'] ?? '',
              userID: currentUser.uid,
              userName: userName,
              isHost: false,
              hostID: liveData['id_host'],
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de la connexion au live: $e');
    }
  }
}
