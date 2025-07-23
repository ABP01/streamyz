// FICHIER DOUBLON. Utilisez lib/screens/explorer_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:streamyz/screens/zego_live_page.dart';


class ExplorerScreen extends StatelessWidget {
  const ExplorerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explorer')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lives en cours',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('lives')
                    .where('is_live', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Aucun live en cours.'));
                  }
                  final docs = snapshot.data!.docs;
                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final data = docs[i].data();
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            final currentUser = FirebaseAuth.instance.currentUser;
                            final userName = (currentUser?.displayName?.isNotEmpty ?? false)
                                ? currentUser!.displayName!
                                : (currentUser?.email?.isNotEmpty ?? false)
                                    ? currentUser!.email!
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
                          child: Row(
                            children: [
                              Container(
                                width: 100,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple[100],
                                  borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(16),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.live_tv,
                                  size: 40,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['desc'] ?? 'Live',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'par ${data['name_host'] ?? ''}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        data['desc'] ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: Icon(Icons.arrow_forward_ios, size: 18),
                              ),
                            ],
                          ),
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
    );
  }
}
          