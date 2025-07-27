import 'package:flutter/material.dart';
import '../screens/user_profile_screen.dart';

class NavigationHelper {
  /// Navigue vers le profil d'un utilisateur
  static void navigateToUserProfile(
    BuildContext context, {
    required String userId,
    String? username,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          userId: userId,
          username: username,
        ),
      ),
    );
  }
}

/// Widget helper pour rendre un avatar cliquable
class ClickableAvatar extends StatelessWidget {
  final String userId;
  final String? username;
  final String? avatarUrl;
  final double radius;
  final VoidCallback? onTap;

  const ClickableAvatar({
    super.key,
    required this.userId,
    this.username,
    this.avatarUrl,
    this.radius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {
        NavigationHelper.navigateToUserProfile(
          context,
          userId: userId,
          username: username,
        );
      },
      child: CircleAvatar(
        radius: radius,
        backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
            ? NetworkImage(avatarUrl!)
            : null,
        backgroundColor: Colors.purple,
        child: avatarUrl == null || avatarUrl!.isEmpty
            ? Icon(
                Icons.person,
                size: radius * 0.8,
                color: Colors.white,
              )
            : null,
      ),
    );
  }
} 