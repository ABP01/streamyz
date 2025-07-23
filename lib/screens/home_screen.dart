import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:streamyz/screens/zego_live_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  File? _pickedImage;

  Future<void> _handleStartLive(
    BuildContext parentContext,
    TextEditingController descController,
  ) async {
    Navigator.pop(parentContext);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final liveID = user.uid + DateTime.now().millisecondsSinceEpoch.toString();

    String? thumbnailUrl;
    if (_pickedImage != null) {
      try {
        final fileName =
            '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String blobUrl =
            'https://$azureStorageAccount.blob.core.windows.net/$azureContainer/$fileName?$azureSasToken';
        final bytes = await _pickedImage!.readAsBytes();
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
        } else {
          debugPrint(
            'Erreur upload Azure: ${response.statusCode} ${response.body}',
          );
        }
      } catch (e) {
        debugPrint('Erreur upload Azure: $e');
      }
    }

    // Récupère username et avatar depuis Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userData = userDoc.data() ?? {};
    final userName = (userData['username'] as String?)?.isNotEmpty == true
        ? userData['username'] as String
        : 'Utilisateur';
    final userAvatar = (userData['avatar'] as String?)?.isNotEmpty == true
        ? userData['avatar'] as String
        : (user.photoURL ?? '');

    // Initialisation du live dans Firestore selon le modèle Live
    final liveDesc = descController.text.isNotEmpty
        ? descController.text
        : 'Live';
    final liveData = {
      'live_id': liveID,
      'live_url': '',
      'id_host': user.uid,
      'thumbnail': thumbnailUrl ?? '',
      'desc': liveDesc,
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
      'stats': {},
      'is_live': true,
      'created_at': FieldValue.serverTimestamp(),
    };
    await FirebaseFirestore.instance
        .collection('lives')
        .doc(liveID)
        .set(liveData, SetOptions(merge: true));

    // Initialisation de la sous-collection Livestats
    final livestatsData = {
      'live_id': liveID,
      'live_url': '',
      'id_host': user.uid,
      'tab_likes': [],
      'emojis': [],
      'account': 0,
      'likes': 0,
      'gifters': [],
    };
    await FirebaseFirestore.instance
        .collection('lives')
        .doc(liveID)
        .collection('livestats')
        .doc(liveID)
        .set(livestatsData, SetOptions(merge: true));

    Navigator.push(
      parentContext,
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

  // Azure Blob Storage config
  static const String azureStorageAccount = 'streamyzstorage';
  static const String azureContainer = 'thumbnails';
  static const String azureSasToken =
      'sp=racwdl&st=2025-07-23T14:18:12Z&se=2025-08-31T22:33:12Z&sv=2024-11-04&sr=c&sig=u7jROdJBpryF%2BLjk9jAVahnbk%2FiEOUPZrokT0Lx90fg%3D';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showStartLiveSheet(BuildContext parentContext) {
    final ImagePicker _picker = ImagePicker();
    final TextEditingController descController = TextEditingController();

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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Description du live',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descController,
                      maxLength: 100,
                      decoration: InputDecoration(
                        hintText: 'Entrez une description...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Miniature du live',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final pickedFile = await _picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 80,
                        );
                        if (pickedFile != null) {
                          setModalState(() {
                            _pickedImage = File(pickedFile.path);
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade400,
                            width: 1.5,
                          ),
                        ),
                        child: _pickedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _pickedImage!,
                                  width: double.infinity,
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.upload_file,
                                    size: 32,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Appuyez pour télécharger une image',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: Colors.black54,
                        ),
                        onPressed: () =>
                            _handleStartLive(parentContext, descController),
                        child: const Text(
                          'Commencer',
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

  Widget _buildLiveCard(Map<String, dynamic> data) {
    final String? thumbnailUrl = data['thumbnail'] as String?;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final currentUser = FirebaseAuth.instance.currentUser;
          final userName = (currentUser?.displayName?.isNotEmpty ?? false)
              ? currentUser!.displayName!
              : 'Utilisateur';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ZegoLivePage(
                liveID: data['live_id'] ?? '',
                userID: currentUser?.uid ?? '',
                userName: userName,
                isHost: false,
              ),
            ),
          );
        },
        child: SizedBox(
          height: 160,
          child: Stack(
            children: [
              Positioned.fill(
                child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                    ? Image.network(thumbnailUrl, fit: BoxFit.cover)
                    : Container(
                        color: Colors.deepPurple[100],
                        child: const Center(
                          child: Icon(
                            Icons.live_tv,
                            size: 60,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 16,
                right: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['desc'] ?? 'Live',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 13,
                          backgroundImage:
                              (data['avatar_host'] != null &&
                                  data['avatar_host'].toString().isNotEmpty)
                              ? NetworkImage(data['avatar_host'])
                              : null,
                          backgroundColor: Colors.grey[300],
                          child:
                              (data['avatar_host'] == null ||
                                  data['avatar_host'].toString().isEmpty)
                              ? const Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          data['name_host'] ?? 'Utilisateur',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () {
                    final currentUser = FirebaseAuth.instance.currentUser;
                    final userName =
                        (currentUser?.displayName?.isNotEmpty ?? false)
                        ? currentUser!.displayName!
                        : 'Utilisateur';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ZegoLivePage(
                          liveID: data['live_id'] ?? '',
                          userID: currentUser?.uid ?? '',
                          userName: userName,
                          isHost: false,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Revoir',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Accueil'),
          backgroundColor: theme.colorScheme.primary,
          elevation: 4,
          shadowColor: Colors.black45,
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher un profil...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Anciens lives',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('lives')
                      .orderBy('livestarttime', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'Aucun live trouvé.',
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data =
                            docs[index].data()! as Map<String, dynamic>;
                        return _buildLiveCard(data);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showStartLiveSheet(context),
          icon: const Icon(Icons.videocam),
          label: const Text('Démarrer live'),
          backgroundColor: theme.colorScheme.primary,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
