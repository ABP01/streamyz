import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:streamyz/views/home/live_stream.dart';

class ProfilePage extends StatelessWidget {
  final String userId;
  const ProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Utilisateur introuvable'));
          }
          final user = snapshot.data!.data() as Map<String, dynamic>;
          return Column(
            children: [
              const SizedBox(height: 30),
              CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
              const SizedBox(height: 10),
              Text(
                user['username'] ?? '',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (user['isLive'] == true) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'EN LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.live_tv),
                    label: const Text('Rejoindre le live'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      // Récupère l'utilisateur courant pour passer son uid/userName
                      final currentUser = FirebaseAuth.instance.currentUser;
                      final uid = currentUser?.uid ?? '';
                      final userName =
                          currentUser?.displayName ?? currentUser?.email ?? uid;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ZegoLiveStream(
                            uid: uid,
                            userName: userName,
                            liveID: 'live_${userId}',
                            isHost: false,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              Text(user['email'] ?? '', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              Expanded(child: FollowersList(userId: userId)),
            ],
          );
        },
      ),
    );
  }
}

class FollowersList extends StatelessWidget {
  final String userId;
  const FollowersList({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('follows')
          .where('followed_id', isEqualTo: userId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Aucun abonné'));
        }
        final followers = snapshot.data!.docs;
        return ListView.builder(
          itemCount: followers.length,
          itemBuilder: (context, index) {
            final followerId = followers[index]['follower_id'];
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(followerId)
                  .get(),
              builder: (context, userSnap) {
                if (!userSnap.hasData || !userSnap.data!.exists) {
                  return const SizedBox.shrink();
                }
                final user = userSnap.data!.data() as Map<String, dynamic>;
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(user['username'] ?? ''),
                  subtitle: Text(user['email'] ?? ''),
                );
              },
            );
          },
        );
      },
    );
  }
}
