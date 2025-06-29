import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String? username;
  Future<List<Map<String, dynamic>>>? _searchFuture;
  Set<String> followedUserIds = {};
  final String currentUserId =
      Supabase.instance.client.auth.currentUser?.id ?? '';

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
    final users = await Supabase.instance.client
        .from('users')
        .select('id, username, email')
        .ilike('username', '%$username%');
    final userIds = users.map((u) => u['id'] as String).toList();
    if (userIds.isNotEmpty) {
      final follows = await Supabase.instance.client
          .from('follows')
          .select('followed_id')
          .eq('follower_id', currentUserId)
          .inFilter('followed_id', userIds);
      setState(() {
        followedUserIds = Set<String>.from(
          follows.map((f) => f['followed_id'] as String),
        );
      });
    } else {
      setState(() {
        followedUserIds = {};
      });
    }
    return List<Map<String, dynamic>>.from(users);
  }

  void _toggleFollow(String userId, bool isFollowed) async {
    try {
      if (isFollowed) {
        await Supabase.instance.client
            .from('follows')
            .delete()
            .eq('follower_id', currentUserId)
            .eq('followed_id', userId);
        setState(() {
          followedUserIds.remove(userId);
        });
      } else {
        await Supabase.instance.client.from('follows').insert({
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
      ).showSnackBar(SnackBar(content: Text('Erreur: \\${e.toString()}')));
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
                      if (user['id'] == currentUserId) {
                        return const SizedBox.shrink();
                      }
                      final isFollowed = followedUserIds.contains(user['id']);
                      return ListTile(
                        title: Text(user['username'] ?? 'Nom inconnu'),
                        subtitle: Text(user['email'] ?? ''),
                        trailing: ElevatedButton(
                          onPressed: () =>
                              _toggleFollow(user['id'], isFollowed),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFollowed
                                ? Colors.grey
                                : Colors.blue,
                          ),
                          child: Text(isFollowed ? 'Abonné' : 'Suivre',
                            style: const TextStyle(color: Colors.white ),
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
