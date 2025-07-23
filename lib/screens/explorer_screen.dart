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
                      final thumbnailUrl = data['thumbnail'] as String?;
                      return LiveCard(data: data, thumbnailUrl: thumbnailUrl);
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

class LiveCard extends StatelessWidget {
  const LiveCard({super.key, required this.data, required this.thumbnailUrl});

  final Map<String, dynamic> data;
  final String? thumbnailUrl;

  @override
  Widget build(BuildContext context) {
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
                child: (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
                    ? Image.network(thumbnailUrl!, fit: BoxFit.cover)
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
                    'Rejoindre',
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

}
