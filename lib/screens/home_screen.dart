import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/recording_viewer_screen.dart';
import '../screens/zego_live_page.dart';
import '../utils/navigation_helper.dart';
import '../utils/permission_manager.dart';
import '../utils/simple_recording_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentUserID = '';
  List<String> _followingUsers = [];
  File? _selectedThumbnail;

  // Azure Blob Storage config
  static const String azureStorageAccount = 'streamyzstorage';
  static const String azureContainer = 'thumbnails';
  static const String azureSasToken =
      'sp=racwdl&st=2025-07-23T14:18:12Z&se=2025-08-31T22:33:12Z&sv=2024-11-04&sr=c&sig=u7jROdJBpryF%2BLjk9jAVahnbk%2FiEOUPZrokT0Lx90fg%3D';

  @override
  void initState() {
    super.initState();
    _currentUserID = FirebaseAuth.instance.currentUser?.uid ?? '';
    _loadFollowingUsers();
  }

  Future<void> _loadFollowingUsers() async {
    if (_currentUserID.isEmpty) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('user_following')
          .doc(_currentUserID)
          .get();

      if (userDoc.exists && mounted) {
        setState(() {
          _followingUsers = List<String>.from(
            userDoc.data()?['following'] ?? [],
          );
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des utilisateurs suivis: $e');
    }
  }

  void _showStartLiveBottomSheet() {
    final TextEditingController descController = TextEditingController();
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Démarrer un live',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Description du live',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descController,
                      maxLength: 100,
                      decoration: InputDecoration(
                        hintText: 'Décrivez votre live...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Miniature du live',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final pickedFile = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 80,
                        );
                        if (pickedFile != null) {
                          setModalState(() {
                            _selectedThumbnail = File(pickedFile.path);
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade400,
                            width: 1.5,
                          ),
                        ),
                        child: _selectedThumbnail != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _selectedThumbnail!,
                                  width: double.infinity,
                                  height: 160,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 48,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Appuyez pour ajouter une miniature',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Recommandé : 16:9 (1920x1080)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: Colors.black54,
                        ),
                        onPressed: () async {
                          await _startLive(descController.text);
                        },
                        child: const Text(
                          'Commencer le live',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _startLive(String description) async {
    // Fermer le bottom sheet
    Navigator.pop(context);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Récupérer les informations utilisateur
    String userName = 'Utilisateur';
    String userAvatar = '';

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() ?? {};
        userName = userData['username'] ?? 'Utilisateur';
        userAvatar = userData['avatar'] ?? '';
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des données utilisateur: $e');
    }

    // Upload de la thumbnail vers Azure Blob Storage si une image est sélectionnée
    String thumbnailUrl = '';
    if (_selectedThumbnail != null) {
      try {
        final fileName =
            '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String blobUrl =
            'https://$azureStorageAccount.blob.core.windows.net/$azureContainer/$fileName?$azureSasToken';

        final bytes = await _selectedThumbnail!.readAsBytes();
        final response = await http.put(
          Uri.parse(blobUrl),
          headers: {
            'x-ms-blob-type': 'BlockBlob',
            'Content-Type': 'image/jpeg',
          },
          body: bytes,
        );

        if (response.statusCode == 201) {
          thumbnailUrl =
              'https://$azureStorageAccount.blob.core.windows.net/$azureContainer/$fileName';
          debugPrint('Thumbnail uploadée avec succès: $thumbnailUrl');
        } else {
          debugPrint(
            'Erreur upload Azure: ${response.statusCode} ${response.body}',
          );
        }
      } catch (e) {
        debugPrint('Erreur upload thumbnail: $e');
      }
    }

    // Générer un ID unique pour le live
    final liveID = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}';

    // Utiliser la description fournie ou une description par défaut
    final liveDescription = description.trim().isNotEmpty
        ? description.trim()
        : 'Mon Live';

    try {
      // Créer le document live dans Firestore
      await FirebaseFirestore.instance.collection('lives').doc(liveID).set({
        'live_id': liveID,
        'live_url': '',
        'id_host': user.uid,
        'thumbnail': thumbnailUrl,
        'desc': liveDescription,
        'name_host': userName,
        'avatar_host': userAvatar,
        'id_chat': '',
        'src_live': '',
        'livestarttime': DateTime.now().millisecondsSinceEpoch,
        'liveendtime': 0,
        'is_signaler': false,
        'ispremiumlive': false,
        'totalgift': 0,
        'max_connect': 0,
        'invites': [],
        'has_recording': false,
        'recording_url': '',
        'is_recording': false,
        'stats': {
          'live_id': liveID,
          'live_url': '',
          'id_host': user.uid,
          'tab_likes': [], // Correspond à tabLikes dans Livestats
          'emojis': [],
          'account': 0,
          'likes': 0,
          'gifters': [], // Correspond à List<Donateur> gifters
        },
        'is_live': true,
        'created_at': FieldValue.serverTimestamp(),
      });

      // Réinitialiser la thumbnail sélectionnée pour le prochain live
      setState(() {
        _selectedThumbnail = null;
      });

      // Naviguer vers la page de live
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ZegoLivePage(
              liveID: liveID,
              userID: user.uid,
              userName: userName,
              isHost: true,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de la création du live: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la création du live'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
              _loadFollowingUsers();
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Onglets
            Container(
              color: Colors.grey.shade100,
              child: const TabBar(
                labelColor: Colors.purple,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.purple,
                tabs: [
                  Tab(text: 'Pour vous', icon: Icon(Icons.explore)),
                  Tab(text: 'Abonnements', icon: Icon(Icons.people)),
                ],
              ),
            ),
            // Contenu des onglets
            Expanded(
              child: TabBarView(
                children: [_buildForYouTab(), _buildFollowingTab()],
              ),
            ),
          ],
        ),
      ),
      // Bouton flottant pour démarrer un live
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showStartLiveBottomSheet,
        icon: const Icon(Icons.videocam),
        label: const Text('Démarrer Live'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildForYouTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SimpleRecordingManager.getRecordedLives(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_library, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucun live enregistré',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Les lives enregistrés sur Azure apparaîtront ici',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final recordedLives = snapshot.data!;

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Force rebuild with new data
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recordedLives.length,
            itemBuilder: (context, index) {
              final liveData = recordedLives[index];
              return RecordedLiveCard(
                liveData: liveData,
                currentUserID: _currentUserID,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFollowingTab() {
    if (_followingUsers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Vous ne suivez personne',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Suivez des créateurs pour voir leurs anciens lives ici',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lives')
          .where('is_live', isEqualTo: false)
          .where(
            'id_host',
            whereIn: _followingUsers.take(10).toList(),
          ) // Firestore limite à 10
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
                Icon(
                  Icons.video_library_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Aucun live récent',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Les personnes que vous suivez n\'ont pas fait de live récemment',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
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
            setState(() {});
            _loadFollowingUsers();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lives.length,
            itemBuilder: (context, index) {
              final liveData = lives[index].data() as Map<String, dynamic>;
              return PastLiveCard(
                liveData: liveData,
                currentUserID: _currentUserID,
                showFollowingBadge: true,
              );
            },
          ),
        );
      },
    );
  }
}

class PastLiveCard extends StatelessWidget {
  final Map<String, dynamic> liveData;
  final String currentUserID;
  final bool showFollowingBadge;

  const PastLiveCard({
    super.key,
    required this.liveData,
    required this.currentUserID,
    this.showFollowingBadge = false,
  });

  String _formatDuration(int startTime, int? endTime) {
    if (endTime == null || endTime == 0) return 'Durée inconnue';

    final duration = Duration(milliseconds: endTime - startTime);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}min';
    } else {
      return '${duration.inMinutes}min';
    }
  }

  String _formatTimeAgo(int startTime) {
    final now = DateTime.now();
    final startDateTime = DateTime.fromMillisecondsSinceEpoch(startTime);
    final difference = now.difference(startDateTime);

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

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
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
    final startTime = liveData['livestarttime'] ?? 0;
    final endTime = liveData['liveendtime'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec avatar et infos host
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    final hostId = liveData['id_host'] ?? '';
                    if (hostId.isNotEmpty) {
                      NavigationHelper.navigateToUserProfile(
                        context,
                        userId: hostId,
                        username: hostName,
                      );
                    }
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: hostAvatar.isNotEmpty
                        ? NetworkImage(hostAvatar)
                        : null,
                    child: hostAvatar.isEmpty
                        ? const Icon(Icons.person, size: 20)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            hostName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (showFollowingBadge) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Suivi',
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
                      Text(
                        _formatTimeAgo(startTime),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Thumbnail du live
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Stack(
              children: [
                // Image de fond
                if (thumbnail.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
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

                // Overlay avec badge TERMINÉ
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'TERMINÉ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Durée du live
                Positioned(
                  bottom: 8,
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
                    child: Text(
                      _formatDuration(startTime, endTime),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Titre et statistiques
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.visibility, size: 16, color: Colors.blue),
                    Text(' ${_formatCount(viewerCount)} spectateurs'),
                    const SizedBox(width: 16),
                    Icon(Icons.favorite, size: 16, color: Colors.red),
                    Text(' ${_formatCount(likeCount)}'),
                    const SizedBox(width: 16),
                    Icon(Icons.card_giftcard, size: 16, color: Colors.amber),
                    Text(' ${_formatCount(giftCount)}'),
                  ],
                ),
              ],
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
          colors: [Colors.grey.shade400, Colors.grey.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(Icons.play_circle_outline, color: Colors.white, size: 50),
      ),
    );
  }
}

class RecordedLiveCard extends StatelessWidget {
  final Map<String, dynamic> liveData;
  final String currentUserID;

  const RecordedLiveCard({
    super.key,
    required this.liveData,
    required this.currentUserID,
  });

  String _formatDuration(int startTime, int? endTime) {
    if (endTime == null || endTime == 0) return 'Durée inconnue';

    final duration = Duration(milliseconds: endTime - startTime);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}min';
    } else {
      return '${duration.inMinutes}min';
    }
  }

  String _formatTimeAgo(int startTime) {
    final now = DateTime.now();
    final startDateTime = DateTime.fromMillisecondsSinceEpoch(startTime);
    final difference = now.difference(startDateTime);

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

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }

  void _showRecordingOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_circle_fill, color: Colors.green),
              title: const Text('Regarder l\'enregistrement'),
              onTap: () {
                Navigator.pop(context);
                _playRecording(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: const Text('Partager l\'enregistrement'),
              onTap: () {
                Navigator.pop(context);
                _shareRecording(context);
              },
            ),
            if (liveData['id_host'] == currentUserID) ...[
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Supprimer l\'enregistrement'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteRecording(context);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _playRecording(BuildContext context) {
    final recordingUrl = liveData['recording_url'] ?? '';
    final localPath = liveData['local_recording_path'] ?? '';
    final title = liveData['desc'] ?? 'Live enregistré';

    if (localPath.isNotEmpty) {
      // Ouvrir le fichier local (HTML interactif)
      _openLocalRecording(context, localPath, title);
    } else if (recordingUrl.isNotEmpty) {
      // Ouvrir l'URL Azure (HTML)
      _openWebRecording(context, recordingUrl, title);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Aucun enregistrement disponible'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openLocalRecording(
    BuildContext context,
    String filePath,
    String title,
  ) async {
    try {
      // Utiliser url_launcher pour ouvrir le fichier HTML local
      final file = File(filePath);
      if (await file.exists()) {
        final uri = Uri.file(filePath);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📱 Ouverture du recap: $title'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _showRecordingDialog(
            context,
            title,
            'Fichier sauvegardé localement mais impossible à ouvrir avec le navigateur par défaut.',
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Fichier local introuvable'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur ouverture fichier local: $e');
      _showRecordingDialog(
        context,
        title,
        'Erreur lors de l\'ouverture du fichier local.',
      );
    }
  }

  void _openWebRecording(BuildContext context, String url, String title) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🌐 Ouverture du recap en ligne: $title'),
            backgroundColor: Colors.blue,
          ),
        );
      } else {
        _showRecordingDialog(
          context,
          title,
          'Impossible d\'ouvrir le lien. Vérifiez votre connexion Internet.',
        );
      }
    } catch (e) {
      debugPrint('Erreur ouverture URL: $e');
      _showRecordingDialog(
        context,
        title,
        'Erreur lors de l\'ouverture du lien.',
      );
    }
  }

  void _showRecordingDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Recap: $title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _shareRecording(BuildContext context) {
    final liveId = liveData['live_id'] ?? '';
    final title = liveData['desc'] ?? 'Live enregistré';
    final recordingUrl = 'streamyz://recording/$liveId';

    // Utiliser le package share_plus pour partager
    // Share.share('Regardez cet enregistrement: $title\n$recordingUrl');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de partage bientôt disponible'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _deleteRecording(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'enregistrement'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cet enregistrement ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final liveId = liveData['live_id'] ?? '';
      final success = await SimpleRecordingManager.deleteRecording(liveId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Enregistrement supprimé avec succès'
                  : 'Erreur lors de la suppression',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
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
    final startTime = liveData['livestarttime'] ?? 0;
    final endTime = liveData['liveendtime'];
    final hasRecording = liveData['has_recording'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showRecordingOptions(context),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec avatar et infos host
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      final hostId = liveData['id_host'] ?? '';
                      if (hostId.isNotEmpty) {
                        NavigationHelper.navigateToUserProfile(
                          context,
                          userId: hostId,
                          username: hostName,
                        );
                      }
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: hostAvatar.isNotEmpty
                          ? NetworkImage(hostAvatar)
                          : null,
                      child: hostAvatar.isEmpty
                          ? const Icon(Icons.person, size: 20)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              hostName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'ENREGISTRÉ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _formatTimeAgo(startTime),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Thumbnail du live avec overlay de lecture
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.symmetric(horizontal: 12),
              child: Stack(
                children: [
                  // Image de fond
                  if (thumbnail.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
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

                  // Overlay avec gradient et bouton play
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),

                  // Bouton play central
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.black,
                        size: 40,
                      ),
                    ),
                  ),

                  // Badge enregistrement
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.videocam, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'ENREGISTRÉ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Durée du live
                  if (endTime != null && endTime > 0)
                    Positioned(
                      bottom: 8,
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
                        child: Text(
                          _formatDuration(startTime, endTime),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Titre et statistiques
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.visibility, size: 16, color: Colors.blue),
                      Text(' ${_formatCount(viewerCount)} spectateurs'),
                      const SizedBox(width: 16),
                      Icon(Icons.favorite, size: 16, color: Colors.red),
                      Text(' ${_formatCount(likeCount)}'),
                      const SizedBox(width: 16),
                      Icon(Icons.card_giftcard, size: 16, color: Colors.amber),
                      Text(' ${_formatCount(giftCount)}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultThumbnail() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(Icons.videocam, color: Colors.white, size: 50),
      ),
    );
  }
}
