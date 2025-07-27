import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/follow_manager.dart';
import '../utils/navigation_helper.dart';

class UserSearchWidget extends StatefulWidget {
  const UserSearchWidget({super.key});

  @override
  State<UserSearchWidget> createState() => _UserSearchWidgetState();
}

class _UserSearchWidgetState extends State<UserSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _suggestedUsers = [];
  bool _isSearching = false;
  bool _isLoading = false;
  String _currentUserID = '';

  @override
  void initState() {
    super.initState();
    _currentUserID = FirebaseAuth.instance.currentUser?.uid ?? '';
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    if (_currentUserID.isEmpty) return;

    setState(() => _isLoading = true);
    final suggestions = await FollowManager.getSuggestedUsers(_currentUserID);
    if (mounted) {
      setState(() {
        _suggestedUsers = suggestions;
        _isLoading = false;
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Recherche par nom d'utilisateur (insensible à la casse)
      final usernameQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('username_lower', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('username_lower', isLessThan: query.toLowerCase() + 'z')
          .limit(20)
          .get();

      final results = usernameQuery.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Exclure l'utilisateur actuel
      results.removeWhere((user) => user['id'] == _currentUserID);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la recherche: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleFollow(Map<String, dynamic> user) async {
    final isFollowing = await FollowManager.isFollowing(
      _currentUserID,
      user['id'],
    );

    bool success;
    if (isFollowing) {
      success = await FollowManager.unfollowUser(_currentUserID, user['id']);
    } else {
      success = await FollowManager.followUser(_currentUserID, user['id']);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFollowing
                ? 'Vous ne suivez plus ${user['username']}'
                : 'Vous suivez maintenant ${user['username']}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Recharger les suggestions si nécessaire
      if (!_isSearching) {
        _loadSuggestions();
      }
    }
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return FutureBuilder<bool>(
      future: FollowManager.isFollowing(_currentUserID, user['id']),
      builder: (context, snapshot) {
        final isFollowing = snapshot.data ?? false;
        final isOnline = user['is_online'] ?? false;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    NavigationHelper.navigateToUserProfile(
                      context,
                      userId: user['id'] ?? '',
                      username: user['username'],
                    );
                  },
                  child: CircleAvatar(
                    radius: 25,
                    backgroundImage:
                        user['avatar'] != null && user['avatar'].isNotEmpty
                        ? NetworkImage(user['avatar'])
                        : null,
                    child: user['avatar'] == null || user['avatar'].isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                ),
                // Indicateur en ligne
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    user['username'] ?? 'Utilisateur',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (user['is_premium'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.amber, Colors.orange],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'PREMIUM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.card_giftcard, size: 14, color: Colors.amber),
                    Text(' ${user['totallivegift'] ?? 0} cadeaux'),
                    const SizedBox(width: 12),
                    Icon(Icons.people, size: 14, color: Colors.blue),
                    Text(
                      ' ${(user['followers'] as List?)?.length ?? 0} abonnés',
                    ),
                  ],
                ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () => _toggleFollow(user),
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing ? Colors.grey : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                isFollowing ? 'Suivi' : 'Suivre',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher des utilisateurs...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _searchUsers('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged: _searchUsers,
          ),
        ),

        // Contenu
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _isSearching
              ? _buildSearchResults()
              : _buildSuggestions(),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun utilisateur trouvé',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildUserCard(_searchResults[index]);
      },
    );
  }

  Widget _buildSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Suggestions pour vous',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        if (_suggestedUsers.isEmpty)
          const Expanded(
            child: Center(
              child: Text(
                'Aucune suggestion disponible',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _suggestedUsers.length,
              itemBuilder: (context, index) {
                return _buildUserCard(_suggestedUsers[index]);
              },
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
