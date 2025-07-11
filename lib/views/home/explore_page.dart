import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:streamyz/services/live_cleanup_service.dart';
import 'package:streamyz/views/home/immersive_live_viewer.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage>
    with AutomaticKeepAliveClientMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  List<QueryDocumentSnapshot> _liveStreams = [];
  bool _isBuilding = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('isLive', isEqualTo: true)
            .orderBy('liveStartTime', descending: true)
            .limit(20)
            .snapshots(),
        builder: (context, snapshot) {
          if (_isBuilding) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          print('ExplorePage: Nombre de docs trouvés: ${docs.length}');
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            print(
              'Live trouvé: ${doc.id}, isLive: ${data['isLive']}, username: ${data['username']}',
            );
          }

          // Trier et filtrer les lives valides en mémoire
          final sortedDocs = List<QueryDocumentSnapshot>.from(docs);

          // Filtrer les lives réellement actifs
          final validLives = <QueryDocumentSnapshot>[];
          for (final doc in sortedDocs) {
            final data = doc.data() as Map<String, dynamic>;

            // Vérifications de validité
            final isLive = data['isLive'] == true;
            final liveStartTime = data['liveStartTime'] as Timestamp?;

            if (!isLive) continue;

            // Vérifier que le live n'est pas trop ancien (max 2h)
            if (liveStartTime != null) {
              final startTime = liveStartTime.toDate();
              final now = DateTime.now();
              final difference = now.difference(startTime);

              if (difference.inHours >= 2) {
                print(
                  'Live de ${doc.id} trop ancien (${difference.inHours}h) - Ignoré',
                );
                // Optionnel : nettoyer automatiquement
                LiveCleanupService.forceCleanupUser(doc.id);
                continue;
              }
            }

            validLives.add(doc);
          }

          // Trier par liveStartTime (plus récent en premier)
          validLives.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['liveStartTime'] as Timestamp?;
            final bTime = bData['liveStartTime'] as Timestamp?;

            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime); // Descending order
          });

          print('Lives valides trouvés: ${validLives.length}/${docs.length}');

          if (validLives.isEmpty) {
            return _buildNoLivesAvailable();
          }

          // Mettre à jour la liste des lives
          if (!_isBuilding) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _liveStreams = validLives;
                });
              }
            });
          }

          // Interface de type TikTok avec PageView vertical
          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: (index) {
              if (mounted && !_isBuilding) {
                setState(() {
                  _currentIndex = index;
                });
              }
            },
            itemCount: _liveStreams.isEmpty
                ? validLives.length
                : _liveStreams.length,
            itemBuilder: (context, index) {
              final liveDoc = _liveStreams.isEmpty
                  ? validLives[index]
                  : _liveStreams[index];
              final liveData = liveDoc.data() as Map<String, dynamic>;

              return _buildLiveView(liveDoc, liveData, index);
            },
          );
        },
      ),
    );
  }

  Widget _buildLiveView(
    QueryDocumentSnapshot liveDoc,
    Map<String, dynamic> liveData,
    int index,
  ) {
    // Optimisation : ne charger que le live visible et les adjacents
    final isCurrentPage = index == _currentIndex;
    final isAdjacentPage = (index - _currentIndex).abs() <= 1;

    if (!isCurrentPage && !isAdjacentPage) {
      // Pour les pages lointaines, on affiche juste un placeholder
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Chargement du live...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Live viewer en plein écran avec gestion d'erreur améliorée
        Container(
          color: Colors.black,
          child: _buildSafeLiveViewer(liveDoc, liveData, isCurrentPage),
        ),

        // Indicateurs de navigation (points en haut à droite)
        Positioned(
          top: 60,
          right: 20,
          child: Column(
            children: List.generate(
              _liveStreams.isNotEmpty ? _liveStreams.length : 1,
              (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  width: 6,
                  height: i == _currentIndex ? 20 : 6,
                  decoration: BoxDecoration(
                    color: i == _currentIndex
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              },
            ),
          ),
        ),

        // Instructions de navigation (au centre en bas)
        if (_liveStreams.length > 1)
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.keyboard_arrow_up,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Glissez pour voir d\'autres lives',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNoLivesAvailable() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.tv_off, color: Colors.white54, size: 80),
          const SizedBox(height: 24),
          Text(
            'Aucun live disponible',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Revenez plus tard ou démarrez votre propre live !',
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // Navigation vers l'onglet Live pour démarrer un stream
                  if (mounted) {
                    Navigator.of(context).pop();
                    // Vous pouvez ajouter une logique pour changer d'onglet ici
                  }
                },
                icon: Icon(Icons.live_tv),
                label: Text('Démarrer un Live'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _refreshLives,
                icon: Icon(Icons.refresh, color: Colors.white),
                label: Text(
                  'Actualiser',
                  style: TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _refreshLives() async {
    try {
      // Afficher un indicateur de chargement
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Text('Nettoyage des lives obsolètes...'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );

      // Nettoyer les lives obsolètes
      await LiveCleanupService.cleanupStaleLives();

      // Confirmer le succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Lives actualisés avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Afficher l'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de l\'actualisation: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildSafeLiveViewer(
    QueryDocumentSnapshot liveDoc,
    Map<String, dynamic> liveData,
    bool isCurrentPage,
  ) {
    return FutureBuilder(
      future: Future.delayed(Duration(milliseconds: isCurrentPage ? 0 : 500)),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done &&
            !isCurrentPage) {
          return Container(
            color: Colors.black,
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        // Vérifier que les données du live sont valides
        if (!_isValidLiveData(liveData)) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Erreur lors du chargement du live',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Données invalides',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        try {
          return ImmersiveLiveViewerPage(
            hostId: liveDoc.id,
            hostName:
                liveData['username'] ?? liveData['displayName'] ?? 'Streamer',
            liveID: 'live_${liveDoc.id}',
            isActive: isCurrentPage,
            userData: liveData,
          );
        } catch (e) {
          print('Erreur lors de la création de ImmersiveLiveViewerPage: $e');
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Impossible de charger le live',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Erreur technique: ${e.toString().substring(0, 50)}...',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (mounted) {
                        setState(() {
                          // Forcer le rechargement
                        });
                      }
                    },
                    child: Text('Réessayer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  bool _isValidLiveData(Map<String, dynamic> liveData) {
    // Vérifier les champs essentiels
    if (liveData.isEmpty) return false;

    // Vérifier la présence d'au moins un nom d'utilisateur
    final hasValidUserName =
        liveData['username'] != null &&
            liveData['username'].toString().isNotEmpty ||
        liveData['displayName'] != null &&
            liveData['displayName'].toString().isNotEmpty;

    // Vérifier que le live n'est pas trop ancien
    if (liveData['liveStartTime'] != null) {
      final startTime = (liveData['liveStartTime'] as Timestamp).toDate();
      final difference = DateTime.now().difference(startTime);
      if (difference.inHours >= 2) return false;
    }

    return hasValidUserName;
  }
}
