import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat.dart';

class ChatList extends StatefulWidget {
  const ChatList({super.key});

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Ouvrir la recherche d'utilisateurs
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getConversationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune conversation',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Commencez une nouvelle conversation',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return _buildConversationTile(conversation);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "chat_list_fab",
        onPressed: () {
          // Ouvrir la sélection de nouveaux contacts
        },
        child: const Icon(Icons.chat),
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _getConversationsStream() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        // Temporarily remove orderBy to avoid index requirement
        .snapshots()
        .map((snapshot) {
          // Sort in memory instead
          final docs = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();

          // Sort by updatedAt in descending order
          docs.sort((a, b) {
            final aTime = a['updatedAt'] as Timestamp?;
            final bTime = b['updatedAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime); // Descending order
          });

          return docs;
        });
  }

  Widget _buildConversationTile(Map<String, dynamic> conversation) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final participants = List<String>.from(conversation['participants'] ?? []);
    final otherUserId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    if (otherUserId.isEmpty) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return ListTile(
            leading: CircleAvatar(backgroundColor: Colors.grey.shade300),
            title: Container(
              width: 100,
              height: 14,
              color: Colors.grey.shade300,
            ),
            subtitle: Container(
              width: 150,
              height: 12,
              color: Colors.grey.shade200,
            ),
          );
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
        final avatarUrl = userData?['avatarUrl'] as String?;
        final username =
            userData?['username'] ?? userData?['displayName'] ?? otherUserId;
        final lastMessage = conversation['lastMessage'] ?? 'Nouveau message';
        final updatedAt = conversation['updatedAt'];

        String timeString = '';
        if (updatedAt is Timestamp) {
          final date = updatedAt.toDate();
          final now = DateTime.now();
          final difference = now.difference(date);

          if (difference.inDays > 0) {
            timeString = '${difference.inDays}j';
          } else if (difference.inHours > 0) {
            timeString = '${difference.inHours}h';
          } else if (difference.inMinutes > 0) {
            timeString = '${difference.inMinutes}m';
          } else {
            timeString = 'maintenant';
          }
        }

        // Vérifier si l'utilisateur est en live
        final isLive = userData?['isLive'] == true;

        return ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),
              if (isLive)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.live_tv,
                      size: 8,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (isLive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text(
            lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          trailing: Text(
            timeString,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailPage(userId: otherUserId),
              ),
            );
          },
        );
      },
    );
  }
}
