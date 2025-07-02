import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:streamyz/views/home/chat_list.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String? username;
  Future<List<Map<String, dynamic>>>? _searchFuture;
  Set<String> followedUserIds = {};
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  void _onSearchChanged(String value) async {
    setState(() {
      username = value.trim();
      if (username != null && username!.length > 2) {
        _searchFuture = _searchUsersAndFollows(username!);
      } else {
        _searchFuture = null;
        followedUserIds = {};
      }
    });
  }

  Future<List<Map<String, dynamic>>> _searchUsersAndFollows(
    String username,
  ) async {
    final users = await FirebaseFirestore.instance
        .collection('users')
        .where(
          'username_lowercase',
          isGreaterThanOrEqualTo: username.toLowerCase(),
        )
        .where(
          'username_lowercase',
          isLessThanOrEqualTo: username.toLowerCase() + '\uf8ff',
        )
        .get();

    final filteredUsers = users.docs
        .where((doc) => doc.id != currentUserId)
        .toList();

    final userIds = filteredUsers.map((u) => u.id).toList();
    if (userIds.isNotEmpty) {
      final follows = await FirebaseFirestore.instance
          .collection('follows')
          .where('follower_id', isEqualTo: currentUserId)
          .where('followed_id', whereIn: userIds)
          .get();
      setState(() {
        followedUserIds = Set<String>.from(follows.docs.map((f) => f.id));
      });
    } else {
      setState(() {
        followedUserIds = {};
      });
    }
    return filteredUsers.map((doc) => doc.data()).toList();
  }

  void _toggleFollow(String userId, bool isFollowed) async {
    try {
      if (isFollowed) {
        await FirebaseFirestore.instance
            .collection('follows')
            .where('follower_id', isEqualTo: currentUserId)
            .where('followed_id', isEqualTo: userId)
            .get()
            .then((snapshot) {
              for (var doc in snapshot.docs) {
                doc.reference.delete();
              }
            });
        setState(() {
          followedUserIds.remove(userId);
        });
      } else {
        await FirebaseFirestore.instance.collection('follows').add({
          'follower_id': currentUserId,
          'followed_id': userId,
        });
        setState(() {
          followedUserIds.add(userId);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search For User')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter Username',
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          if (_searchFuture != null)
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _searchFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text("Erreur : \\${snapshot.error}");
                  }
                  final data = snapshot.data;
                  if (data == null || data.isEmpty) {
                    return const Center(child: Text("No User Found !"));
                  }
                  return ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final user = data[index];
                      final userId = user['uid'] ?? user['id'];
                      if (userId == null || userId == currentUserId) {
                        return const SizedBox.shrink();
                      }
                      final isFollowed = followedUserIds.contains(userId);
                      return ListTile(
                        leading: IconButton(
                          icon: Icon(Icons.chat),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ChatList(),
                              ),
                            );
                          },
                        ),
                        title: Text(user['username'] ?? 'Nom inconnu'),
                        subtitle: Text(user['email'] ?? 'Email inconnu'),
                        trailing: ElevatedButton(
                          onPressed: () => _toggleFollow(userId, isFollowed),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFollowed
                                ? Colors.grey
                                : Colors.blue,
                          ),
                          child: Text(
                            isFollowed ? 'Abonné' : 'Suivre',
                            style: const TextStyle(color: Colors.white),
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
    );
  }
}
