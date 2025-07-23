import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:streamyz/screens/edit_profile_screen.dart';
import 'package:streamyz/screens/settings_screen.dart';
import 'package:streamyz/screens/zego_live_page.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Non connecté'))
          : StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Utilisateur non trouvé.'));
                }
                final data = snapshot.data!.data()!;
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.deepPurple,
                        child: const Icon(
                          Icons.person,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        data['username'] ?? 'Nom d\'utilisateur',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(data['bio'] ?? 'Bio de l\'utilisateur...'),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text(
                                (data['lives_count'] ?? 0).toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('Lives'),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                (data['followers'] != null
                                        ? (data['followers'] as List).length
                                        : 0)
                                    .toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('Abonnés'),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                (data['following'] != null
                                        ? (data['following'] as List).length
                                        : 0)
                                    .toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('Abonnements'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Mes lives',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: StreamBuilder(
                          stream: FirebaseFirestore.instance
                              .collection('lives')
                              .where('id_host', isEqualTo: user.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Center(
                                child: Text('Aucun live trouvé.'),
                              );
                            }
                            final docs = snapshot.data!.docs;
                            return ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final live = docs[index].data();
                                return Card(
                                  child: ListTile(
                                    leading: Container(
                                      width: 48,
                                      height: 48,
                                      color: Colors.deepPurple[100],
                                      child: const Icon(
                                        Icons.live_tv,
                                        size: 28,
                                      ),
                                    ),
                                    title: Text(live['desc'] ?? 'Mon live'),
                                    subtitle: Text(live['name_host'] ?? ''),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                    ),
                                    onTap: () {
                                      final currentUser =
                                          FirebaseAuth.instance.currentUser;
                                      final userName =
                                          (currentUser
                                                  ?.displayName
                                                  ?.isNotEmpty ??
                                              false)
                                          ? currentUser!.displayName!
                                          : (currentUser?.email?.isNotEmpty ??
                                                false)
                                          ? currentUser!.email!
                                          : 'Utilisateur';
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ZegoLivePage(
                                            liveID: live['live_id'] ?? '',
                                            userID: currentUser?.uid ?? '',
                                            userName: userName,
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
                );
              },
            ),
    );
  }
}
