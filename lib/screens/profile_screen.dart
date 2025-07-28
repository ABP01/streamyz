import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:streamyz/screens/edit_profile_screen.dart';
import 'package:streamyz/screens/settings_screen.dart';
import 'package:streamyz/screens/start_live_screen.dart';
import 'package:streamyz/screens/zego_live_page.dart';
import 'package:streamyz/utils/premium_manager.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Map<String, dynamic> _premiumInfo = {};
  Map<String, dynamic> _userStats = {};
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _loadUserStats();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final premiumInfo = await PremiumManager.getPremiumInfo(user.uid);
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          if (mounted) {
            setState(() {
              _premiumInfo = premiumInfo;
              _userStats = {
                'total_lives': userData['total_lives'] ?? 0,
                'total_viewers': userData['total_viewers'] ?? 0,
                'total_likes_received': userData['total_likes_received'] ?? 0,
                'total_gifts': userData['totallivegift'] ?? 0,
              };
              _isLoadingStats = false;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoadingStats = false);
        }
      }
    }
  }

  String _getUserLevel() {
    final totalGifts = _userStats['total_gifts'] ?? 0;
    if (totalGifts >= 1000) return 'LVL 50+';
    if (totalGifts >= 500) return 'LVL 30';
    if (totalGifts >= 100) return 'LVL 20';
    if (totalGifts >= 50) return 'LVL 10';
    if (totalGifts >= 10) return 'LVL 5';
    return 'LVL 1';
  }

  Color _getLevelColor() {
    final totalGifts = _userStats['total_gifts'] ?? 0;
    if (totalGifts >= 1000) return Colors.amber;
    if (totalGifts >= 500) return Colors.purple;
    if (totalGifts >= 100) return Colors.blue;
    if (totalGifts >= 50) return Colors.green;
    if (totalGifts >= 10) return Colors.orange;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: user == null
          ? const Center(child: Text('Non connecté'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Utilisateur non trouvé'));
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;

                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: CustomScrollView(
                      slivers: [
                        _buildSliverAppBar(userData),
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              _buildProfileHeader(userData),
                              const SizedBox(height: 24),
                              _buildStatsCards(),
                              const SizedBox(height: 24),
                              _buildPremiumProgress(),
                              const SizedBox(height: 24),
                              _buildActionButtons(),
                              const SizedBox(height: 24),
                              _buildLivesSection(user.uid),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSliverAppBar(Map<String, dynamic> userData) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor.withValues(alpha: 0.8),
                Theme.of(context).primaryColor.withValues(alpha: 0.6),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> userData) {
    final username = userData['username'] ?? 'Utilisateur';
    final bio = userData['bio'] ?? '';
    final avatar = userData['avatar'] ?? '';
    final followersCount = userData['followers'] != null
        ? (userData['followers'] as List).length
        : 0;
    final followingCount = userData['following'] != null
        ? (userData['following'] as List).length
        : 0;
    final isPremium = _premiumInfo['is_premium'] ?? false;

    return Container(
      transform: Matrix4.translationValues(0, -80, 0),
      child: Column(
        children: [
          // Avatar avec badge niveau
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: avatar.isNotEmpty
                      ? NetworkImage(avatar)
                      : null,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: avatar.isEmpty
                      ? const Icon(Icons.person, size: 60, color: Colors.white)
                      : null,
                ),
              ),
              // Badge niveau
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 5,
                      ),
                    ],
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
              // Badge Premium
              if (isPremium)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Nom d'utilisateur avec badge premium
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                username,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isPremium) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.amber, Colors.orange],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PREMIUM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),

          if (bio.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                bio,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Statistiques suiveurs/suivis
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn('Abonnés', followersCount.toString()),
              _buildStatColumn('Abonnements', followingCount.toString()),
              _buildStatColumn(
                'Lives',
                (_userStats['total_lives'] ?? 0).toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildStatsCards() {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Spectateurs',
            (_userStats['total_viewers'] ?? 0).toString(),
            Icons.visibility,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Likes',
            (_userStats['total_likes_received'] ?? 0).toString(),
            Icons.favorite,
            Colors.pink,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Cadeaux',
            (_userStats['total_gifts'] ?? 0).toString(),
            Icons.card_giftcard,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildPremiumProgress() {
    if (_premiumInfo.isEmpty) return const SizedBox.shrink();

    final isPremium = _premiumInfo['is_premium'] ?? false;
    final percentage = _premiumInfo['premium_percentage'] ?? 0;
    final giftsNeeded = _premiumInfo['gifts_needed'] ?? 0;

    if (isPremium) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Colors.amber, Colors.orange]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.star, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statut Premium',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Vous avez accès à toutes les fonctionnalités !',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_border, color: Colors.grey[600]),
              const SizedBox(width: 8),
              const Text(
                'Progression vers Premium',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Encore $giftsNeeded cadeaux pour devenir Premium',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StartLiveScreen()),
            ),
            icon: const Icon(Icons.video_call),
            label: const Text('Commencer Live'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
            icon: const Icon(Icons.edit),
            label: const Text('Modifier'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLivesSection(String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mes Lives',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('lives')
              .where('id_host', isEqualTo: userId)
              .orderBy('created_at', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.live_tv_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun live pour le moment',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Commencez votre premier live !',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }

            final docs = snapshot.data!.docs;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final live = docs[index].data() as Map<String, dynamic>;
                return _buildLiveCard(live, userId);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildLiveCard(Map<String, dynamic> live, String userId) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) return;

            String userName = 'Utilisateur';
            try {
              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .get();
              if (userDoc.exists) {
                final userData = userDoc.data() ?? {};
                userName = userData['username'] ?? 'Utilisateur';
              }
            } catch (e) {
              debugPrint('Erreur: $e');
            }

            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ZegoLivePage(
                    liveID: live['live_id'] ?? '',
                    userID: currentUser.uid,
                    userName: userName,
                    isHost: false,
                  ),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.live_tv,
                      color: Theme.of(context).primaryColor,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  live['desc'] ?? 'Mon Live',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  live['name_host'] ?? '',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
