import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'immersive_live_viewer.dart';
import 'live_stats.dart';
import 'live_welcome.dart';

class LiveFeedPage extends StatefulWidget {
  const LiveFeedPage({super.key});

  @override
  State<LiveFeedPage> createState() => _LiveFeedPageState();
}

class _LiveFeedPageState extends State<LiveFeedPage>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // Stream pour les lives en temps réel
  late Stream<QuerySnapshot> _liveUsersStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeLiveStream();

    // Configuration du StatusBar pour l'immersion
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  void _initializeLiveStream() {
    _liveUsersStream = FirebaseFirestore.instance
        .collection('users')
        .where('isLive', isEqualTo: true)
        // Temporarily remove orderBy to avoid index requirement
        .snapshots();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();

    // Restaurer le StatusBar
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Gérer les cycles de vie de l'app pour optimiser les connexions live
    if (state == AppLifecycleState.paused) {
      // Mettre en pause les connexions live
      debugPrint('App paused - pausing live connections');
    } else if (state == AppLifecycleState.resumed) {
      // Reprendre les connexions live
      debugPrint('App resumed - resuming live connections');
    }
  }

  void _preloadAdjacentLives(
    int currentIndex,
    List<DocumentSnapshot> liveUsers,
  ) {
    // Pré-charger les lives adjacents (précédent et suivant) pour une navigation fluide
    for (int i = -1; i <= 1; i++) {
      final index = currentIndex + i;
      if (index >= 0 && index < liveUsers.length && index != currentIndex) {
        final liveUser = liveUsers[index];
        final hostId = liveUser.id;
        final liveID = 'live_$hostId';
        debugPrint('Preloading live: $liveID');
        // La logique de pré-chargement sera gérée dans ImmersiveLiveViewerPage
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        stream: _liveUsersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _initializeLiveStream();
                      });
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final liveUsers = snapshot.data?.docs ?? [];

          // Sort in memory by liveStartTime (descending order)
          liveUsers.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['liveStartTime'] as Timestamp?;
            final bTime = bData['liveStartTime'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime); // Descending order
          });

          if (liveUsers.isEmpty) {
            return _buildEmptyState();
          }

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: liveUsers.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              // Vibration légère pour le feedback haptic
              HapticFeedback.lightImpact();

              // Pré-charger les lives adjacents pour une expérience fluide
              _preloadAdjacentLives(index, liveUsers);
            },
            itemBuilder: (context, index) {
              final liveUser = liveUsers[index];
              final hostId = liveUser.id;
              final userData = liveUser.data() as Map<String, dynamic>;
              final hostName =
                  userData['username'] ?? userData['displayName'] ?? hostId;
              final liveID = 'live_$hostId';

              return ImmersiveLiveViewerPage(
                hostId: hostId,
                hostName: hostName,
                liveID: liveID,
                isActive: index == _currentIndex,
                userData: userData,
                onDispose: () {
                  // Callback pour nettoyer les ressources
                  debugPrint('Live viewer disposed for: $hostName');
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.live_tv, size: 64, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucun live en cours',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Soyez le premier à lancer un live !',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LiveWelcomePage(),
                    ),
                  );
                },
                icon: const Icon(Icons.info_outline),
                label: const Text('Découvrir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LiveStatsPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.leaderboard),
                label: const Text('Classement'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
