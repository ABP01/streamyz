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
  final String currentUserId =
      Supabase.instance.client.auth.currentUser?.id ?? '';

  void _onSearchChanged(String value) {
    setState(() {
      username = value;
      if (username != null && username!.length > 2) {
        _searchFuture = Supabase.instance.client
            .from('users')
            .select('id, username, email')
            .ilike('username', '%$username%');
      } else {
        _searchFuture = null;
      }
    });
  }

  Future<bool> _isFollowed(String userId) async {
    final res = await Supabase.instance.client
        .from('follows')
        .select('id')
        .eq('follower_id', currentUserId)
        .eq('followed_id', userId)
        .maybeSingle();
    return res != null;
  }

  void _toggleFollow(String userId, bool isFollowed) async {
    try {
      if (isFollowed) {
        await Supabase.instance.client
            .from('follows')
            .delete()
            .eq('follower_id', currentUserId)
            .eq('followed_id', userId);
      } else {
        await Supabase.instance.client.from('follows').insert({
          'follower_id': currentUserId,
          'followed_id': userId,
        });
      }
      if (username != null && username!.length > 2) {
        setState(() {}); // refresh
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
                    return Text("Erreur : ${snapshot.error}");
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
                        return const SizedBox.shrink(); // Ne pas afficher soi-même
                      }
                      return FutureBuilder<bool>(
                        future: _isFollowed(user['id']),
                        builder: (context, followSnap) {
                          final isFollowed = followSnap.data ?? false;
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
                              child: Text(isFollowed ? 'Abonné' : 'Suivre'),
                            ),
                          );
                        },
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
