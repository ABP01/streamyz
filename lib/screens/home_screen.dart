import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../utils/follow_manager.dart';
import 'zego_live_page.dart';

// HomeScreen minimal corrigé: ancien code incomplet supprimé.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final String _currentUserID;
  String _currentUserName = '';
  final ImagePicker _picker = ImagePicker();
  Set<String> _following = {};
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _liveStream;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _currentUserID = FirebaseAuth.instance.currentUser?.uid ?? '';
    _tabController = TabController(length: 2, vsync: this);
    _liveStream = FirebaseFirestore.instance
        .collection('lives')
        .where('is_live', isEqualTo: true)
        .snapshots();
    _loadUser();
    _loadFollowing();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _currentUserName = doc.data()?['username'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Erreur load user: $e');
    }
  }

  Future<void> _loadFollowing() async {
    if (_currentUserID.isEmpty) return;
    final list = await FollowManager.getFollowing(_currentUserID);
    setState(() => _following = list.toSet());
  }

  Future<void> _refresh() async {
    await _loadFollowing();
  }

  // Ouvre le bottom sheet pour démarrer un live (description & miniature optionnelles)
  void _openStartLiveSheet() {
    final descController = TextEditingController();
    File? selectedThumbnail;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> pickThumb() async {
              final picked = await _picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 80,
              );
              if (picked != null) {
                setSheetState(() => selectedThumbnail = File(picked.path));
              }
            }

            Future<void> startLive() async {
              if (isLoading) return;
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Utilisateur non connecté')),
                );
                return;
              }
              setSheetState(() => isLoading = true);

              String userName = 'Utilisateur';
              String avatarHost = '';
              try {
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get();
                if (userDoc.exists) {
                  final data = userDoc.data() ?? {};
                  userName = data['username'] ?? userName;
                  avatarHost = data['avatar'] ?? '';
                }
              } catch (e) {
                debugPrint('Erreur userDoc: $e');
              }

              // Upload miniature (facultatif)
              String thumbnailUrl = '';
              if (selectedThumbnail != null) {
                try {
                  final fileName =
                      '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
                  const sasToken =
                      '?sp=racwdl&st=2025-08-08T16:32:14Z&se=2025-08-31T00:47:14Z&sv=2024-11-04&sr=c&sig=%2B9OsjPlA0tXgLa0Avcnz8rfM5Ks82GyCBDyvzW%2BwRUw%3D';
                  final blobUrl =
                      'https://streamyzstorage.blob.core.windows.net/thumbnails/$fileName$sasToken';
                  final bytes = await selectedThumbnail!.readAsBytes();
                  final resp = await http.put(
                    Uri.parse(blobUrl),
                    headers: {
                      'x-ms-blob-type': 'BlockBlob',
                      'Content-Type': 'image/jpeg',
                    },
                    body: bytes,
                  );
                  if (resp.statusCode == 201) {
                    thumbnailUrl =
                        'https://streamyzstorage.blob.core.windows.net/thumbnails/$fileName';
                  } else {
                    debugPrint('Erreur upload thumbnail: ${resp.statusCode}');
                  }
                } catch (e) {
                  debugPrint('Upload miniature échoué: $e');
                }
              }

              final liveID = FirebaseFirestore.instance
                  .collection('lives')
                  .doc()
                  .id;
              try {
                await FirebaseFirestore.instance
                    .collection('lives')
                    .doc(liveID)
                    .set({
                      'live_id': liveID,
                      'id_host': user.uid,
                      'name_host': userName,
                      'avatar_host': avatarHost,
                      'desc': (descController.text.trim().isEmpty
                          ? 'Live de $userName'
                          : descController.text.trim()),
                      'thumbnail': thumbnailUrl,
                      'is_live': true,
                      'livestarttime': DateTime.now().millisecondsSinceEpoch,
                      'liveendtime': 0,
                      'stats': {'account': 0, 'likes': 0},
                    });
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur Firestore: $e')),
                  );
                }
                setSheetState(() => isLoading = false);
                return;
              }

              if (!mounted) return;
              Navigator.pop(context); // fermer sheet
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

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Text(
                      'Démarrer un live',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      maxLength: 100,
                      decoration: InputDecoration(
                        labelText: 'Description (optionnelle)',
                        hintText: 'Décrivez votre live... (facultatif)',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Miniature (optionnelle)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: isLoading ? null : pickThumb,
                      child: Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: selectedThumbnail != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  selectedThumbnail!,
                                  width: double.infinity,
                                  height: 160,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add_photo_alternate,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Appuyez pour ajouter (facultatif)',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Format recommandé 16:9',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : startLive,
                        icon: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.wifi_tethering),
                        label: Text(
                          isLoading ? 'Démarrage...' : 'Commencer le live',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
    ).whenComplete(() => descController.dispose());
  }

  Widget _buildLivesPage({required bool onlyFollowing}) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _liveStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          final List<QueryDocumentSnapshot<Map<String, dynamic>>> filtered =
              onlyFollowing
              ? docs.where((d) => _following.contains(d['id_host'])).toList()
              : docs;

          if (filtered.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Center(
                    child: Text(
                      onlyFollowing
                          ? 'Aucun live de vos abonnements.'
                          : 'Aucun live en cours.',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            );
          }

          return PageView.builder(
            controller: PageController(viewportFraction: 0.85),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final data = filtered[index].data();
              final liveID = data['live_id'] ?? filtered[index].id;
              final hostId = data['id_host'] ?? '';
              final hostName = data['name_host'] ?? 'Host';
              final desc = data['desc'] ?? '';
              final thumb = data['thumbnail'];
              return _LiveCard(
                liveID: liveID,
                hostId: hostId,
                hostName: hostName,
                desc: desc,
                thumbnail: thumb,
                onTap: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ZegoLivePage(
                        liveID: liveID,
                        userID: user.uid,
                        userName: _currentUserName.isEmpty
                            ? 'Viewer'
                            : _currentUserName,
                        isHost: user.uid == hostId,
                        hostID: hostId,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Abonnements'),
            Tab(text: 'Explorer'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            tooltip: 'Démarrer un live',
            onPressed: _openStartLiveSheet,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLivesPage(onlyFollowing: true),
          _buildLivesPage(onlyFollowing: false),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openStartLiveSheet,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  final String liveID;
  final String hostId;
  final String hostName;
  final String desc;
  final String? thumbnail;
  final VoidCallback onTap;
  const _LiveCard({
    required this.liveID,
    required this.hostId,
    required this.hostName,
    required this.desc,
    required this.thumbnail,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumbnail != null && thumbnail!.isNotEmpty)
                Ink.image(image: NetworkImage(thumbnail!), fit: BoxFit.cover)
              else
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF41295a), Color(0xFF2F0743)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.live_tv,
                    size: 80,
                    color: Colors.white30,
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, color: Colors.red, size: 10),
                        const SizedBox(width: 6),
                        const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hostName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
