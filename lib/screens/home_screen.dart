// FICHIER DOUBLON. Utilisez lib/screens/home_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:streamyz/screens/zego_live_page.dart';

import 'package:streamyz/screens/zego_live_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showStartLiveSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final TextEditingController descController = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Démarrer un live',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Ajouter ImagePicker
                },
                icon: const Icon(Icons.image),
                label: const Text('Choisir une miniature'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;
                    final liveID =
                        user.uid +
                        DateTime.now().millisecondsSinceEpoch.toString();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ZegoLivePage(
                          liveID: liveID,
                          userID: user.uid,
                          userName:
                              user.displayName ?? user.email ?? 'Utilisateur',
                          isHost: true,
                        ),
                      ),
                    );
                  },
                  child: const Text('Commencer'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Accueil'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher un profil...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Anciens lives',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('lives')
                      .orderBy('livestarttime', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('Aucun live trouvé.'));
                    }
                    final docs = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: Container(
                              width: 56,
                              height: 56,
                              color: Colors.grey[300],
                              child: const Icon(Icons.live_tv, size: 32),
                            ),
                            title: Text(data['desc'] ?? 'Live'),
                            subtitle: Text(data['name_host'] ?? ''),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () {
                              // Ouvre le live en mode spectateur
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ZegoLivePage(
                                    liveID: data['live_id'] ?? '',
                                    userID:
                                        FirebaseAuth
                                            .instance
                                            .currentUser
                                            ?.uid ??
                                        '',
                                    userName:
                                        FirebaseAuth
                                            .instance
                                            .currentUser
                                            ?.displayName ??
                                        FirebaseAuth
                                            .instance
                                            .currentUser
                                            ?.email ??
                                        'Utilisateur',
                                    isHost: false,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showStartLiveSheet,
          icon: const Icon(Icons.videocam),
          label: const Text('Démarrer live'),
        ),
      ),
    );
  }
}
