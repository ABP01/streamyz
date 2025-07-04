import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:streamyz/views/home/profile.dart';
import 'package:streamyz/views/home/live_stream.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  Stream<List<Map<String, dynamic>>> getConversationsStream() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const Stream.empty();
    }

    final combinedStream = FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots();

    return combinedStream.map((snapshot) {
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    });
  }

  Future<void> sendMessage(String conversationId, String content) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final message = {
      'conversationId': conversationId,
      'senderId': currentUserId,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('messages').add(message);

      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .update({
            'lastMessage': content,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi du message : $e');
    }
  }

  Future<void> createConversation(String userId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final ids = [currentUserId, userId]..sort();
    final conversationId = ids.join('_');
    final conversationRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId);

    try {
      final conversationSnapshot = await conversationRef.get();
      if (!conversationSnapshot.exists) {
        await conversationRef.set({
          'participants': ids,
          'lastMessage': '',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la création de la conversation : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final userId = await showDialog<String>(
                context: context,
                builder: (context) => const UserSearchDialog(),
              );
              debugPrint('UserSearchDialog returned userId: $userId');
              if (userId != null && userId.trim().isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(userId: userId.trim()),
                  ),
                );
              } else {
                if (userId == null) {
                  debugPrint('Aucun utilisateur sélectionné dans la recherche.');
                } else {
                  debugPrint('userId vide ou invalide: "$userId"');
                }
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getConversationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final conversations = snapshot.data ?? [];
          if (conversations.isEmpty) {
            return const Center(child: Text('Aucune conversation disponible.'));
          }
          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final currentUserId = FirebaseAuth.instance.currentUser?.uid;
              String otherUserId = '';
              if (conversation['participants'] != null &&
                  conversation['participants'] is List) {
                final participants = List<String>.from(
                  conversation['participants'],
                );
                otherUserId = participants.firstWhere(
                  (id) => id != currentUserId,
                  orElse: () => '',
                );
              }
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade300,
                      ),
                      title: Container(
                        width: 100,
                        height: 14,
                        color: Colors.grey.shade300,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      subtitle: Container(
                        width: 150,
                        height: 12,
                        color: Colors.grey.shade200,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                      ),
                    );
                  }
                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>?;
                  final avatarUrl = userData?['avatarUrl'] as String?;
                  final username =
                      userData?['username'] ??
                      userData?['displayName'] ??
                      otherUserId;
                  final lastMessage =
                      conversation['lastMessage'] ?? 'Pas de message';
                  final updatedAt = conversation['updatedAt'];
                  String timeString = '';
                  if (updatedAt is Timestamp) {
                    final date = updatedAt.toDate();
                    timeString =
                        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                  }
                  return Slidable(
                    endActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (context) {
                            // Add delete functionality here
                          },
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: 'Supprimer',
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: avatarUrl != null && avatarUrl.isNotEmpty
                          ? CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(
                                avatarUrl,
                              ),
                            )
                          : const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(
                        username,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        timeString,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      onTap: () {
                        if (otherUserId.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ChatDetailPage(userId: otherUserId),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final userId = await showDialog<String>(
            context: context,
            builder: (context) => MutualFollowersDialog(),
          );
          if (userId != null && userId.trim().isNotEmpty) {
            await createConversation(userId.trim());
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailPage(userId: userId.trim()),
              ),
            );
          }
        },
        child: const Icon(Icons.group),
        tooltip: 'Abonnés mutuels',
      ),
    );
  }
}

// Dialog de recherche d'utilisateur par username/email
class UserSearchDialog extends StatefulWidget {
  const UserSearchDialog({Key? key}) : super(key: key);

  @override
  State<UserSearchDialog> createState() => _UserSearchDialogState();
}

class _UserSearchDialogState extends State<UserSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  void _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() => _loading = true);
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('username_lowercase', isEqualTo: query.toLowerCase())
        .get();
    setState(() {
      _results = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rechercher un utilisateur'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Nom d\'utilisateur',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 10),
          _loading
              ? const CircularProgressIndicator()
              : _results.isEmpty
                  ? const SizedBox.shrink()
                  : SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final user = _results[index];
                          return ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(user['username'] ?? user['id']),
                            subtitle: Text(user['email'] ?? ''),
                            onTap: () => Navigator.pop(context, user['id']),
                          );
                        },
                      ),
                    ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: _search,
          child: const Text('Rechercher'),
        ),
      ],
    );
  }
}

class MutualFollowersDialog extends StatefulWidget {
  @override
  State<MutualFollowersDialog> createState() => _MutualFollowersDialogState();
}

class _MutualFollowersDialogState extends State<MutualFollowersDialog> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchMutualFollowers();
  }

  Future<void> _fetchMutualFollowers() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      setState(() {
        _loading = false;
      });
      return;
    }
    // Utilisateurs suivis par moi
    final followingSnap = await FirebaseFirestore.instance
        .collection('follows')
        .where('follower_id', isEqualTo: currentUserId)
        .get();
    final following = followingSnap.docs
        .map((d) => d['followed_id'] as String)
        .toSet();
    // Utilisateurs qui me suivent
    final followersSnap = await FirebaseFirestore.instance
        .collection('follows')
        .where('followed_id', isEqualTo: currentUserId)
        .get();
    final followers = followersSnap.docs
        .map((d) => d['follower_id'] as String)
        .toSet();
    // Intersection
    final mutualIds = following.intersection(followers);
    if (mutualIds.isEmpty) {
      setState(() {
        _users = [];
        _loading = false;
      });
      return;
    }
    // Récupérer les infos utilisateurs
    final usersSnap = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: mutualIds.toList())
        .get();
    setState(() {
      _users = usersSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Abonnés mutuels'),
      content: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
          ? const Text('Aucun abonné mutuel.')
          : SizedBox(
              width: 300,
              height: 400,
              child: ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return ListTile(
                    leading: user['avatarUrl'] != null
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(user['avatarUrl']),
                          )
                        : const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(user['username'] ?? user['id']),
                    subtitle: user['displayName'] != null
                        ? Text(user['displayName'])
                        : null,
                    onTap: () => Navigator.pop(context, user['id']),
                  );
                },
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}

class ChatDetailPage extends StatefulWidget {
  final String userId;
  const ChatDetailPage({super.key, required this.userId});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _controller = TextEditingController();

  String get chatId {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final ids = [currentUserId, widget.userId]..sort();
    return ids.join('_');
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;
    await FirebaseFirestore.instance.collection('messages').add({
      'conversationId': chatId,
      'senderId': currentUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(chatId)
        .update({
          'lastMessage': text,
          'updatedAt': FieldValue.serverTimestamp(),
        });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Discussion')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
        final avatarUrl = userData?['avatarUrl'] as String?;
        final username =
            userData?['username'] ?? userData?['displayName'] ?? widget.userId;
        // Ajout d'un bouton pour rejoindre le live de l'utilisateur si il est en live
        final isLive = userData?['isLive'] == true;
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                avatarUrl != null && avatarUrl.isNotEmpty
                    ? CircleAvatar(backgroundImage: NetworkImage(avatarUrl))
                    : const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 10),
                Text(
                  username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (isLive)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.live_tv, size: 18),
                      label: const Text('Live', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        final currentUser = FirebaseAuth.instance.currentUser;
                        final uid = currentUser?.uid ?? '';
                        final myName = currentUser?.displayName ?? currentUser?.email ?? uid;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ZegoLiveStream(
                              uid: uid,
                              userName: myName,
                              liveID: 'live_${widget.userId}',
                              isHost: false,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('messages')
                      .where('conversationId', isEqualTo: chatId)
                      .orderBy('timestamp')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final messages = snapshot.data!.docs;
                    return ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg['senderId'] == currentUserId;
                        String timeString = '';
                        if (msg['timestamp'] is Timestamp) {
                          final date = (msg['timestamp'] as Timestamp).toDate();
                          timeString =
                              '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                        }
                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? const Color(0xFFDCF8C6)
                                      : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(12),
                                    topRight: const Radius.circular(12),
                                    bottomLeft: isMe
                                        ? const Radius.circular(12)
                                        : const Radius.circular(0),
                                    bottomRight: isMe
                                        ? const Radius.circular(0)
                                        : const Radius.circular(12),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  msg['text'],
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 8,
                                  right: 8,
                                  bottom: 4,
                                ),
                                child: Text(
                                  timeString,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Écrire un message...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
