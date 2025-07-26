import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FollowManager {
  /// Suivre un utilisateur
  static Future<bool> followUser(
    String currentUserID,
    String targetUserID,
  ) async {
    if (currentUserID == targetUserID) return false;

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Ajouter aux suivis de l'utilisateur actuel (utiliser une collection séparée)
      final followingRef = FirebaseFirestore.instance
          .collection('user_following')
          .doc(currentUserID);
      batch.set(followingRef, {
        'user_id': currentUserID,
        'following': FieldValue.arrayUnion([targetUserID]),
      }, SetOptions(merge: true));

      // Ajouter aux followers de l'utilisateur cible
      final targetUserRef = FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserID);
      batch.update(targetUserRef, {
        'followers': FieldValue.arrayUnion([currentUserID]),
      });

      // Créer une notification de follow
      final notificationRef = FirebaseFirestore.instance
          .collection('notifications')
          .doc();
      batch.set(notificationRef, {
        'id': notificationRef.id,
        'type': 'follow',
        'from_user_id': currentUserID,
        'to_user_id': targetUserID,
        'message': 'a commencé à vous suivre',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'read': false,
      });

      await batch.commit();
      debugPrint('Utilisateur $targetUserID suivi avec succès');
      return true;
    } catch (e) {
      debugPrint('Erreur lors du follow: $e');
      return false;
    }
  }

  /// Ne plus suivre un utilisateur
  static Future<bool> unfollowUser(
    String currentUserID,
    String targetUserID,
  ) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Retirer des suivis de l'utilisateur actuel (collection séparée)
      final followingRef = FirebaseFirestore.instance
          .collection('user_following')
          .doc(currentUserID);
      batch.update(followingRef, {
        'following': FieldValue.arrayRemove([targetUserID]),
      });

      // Retirer des followers de l'utilisateur cible
      final targetUserRef = FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserID);
      batch.update(targetUserRef, {
        'followers': FieldValue.arrayRemove([currentUserID]),
      });

      await batch.commit();
      debugPrint('Utilisateur $targetUserID retiré des suivis');
      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'unfollow: $e');
      return false;
    }
  }

  /// Vérifier si un utilisateur est suivi
  static Future<bool> isFollowing(
    String currentUserID,
    String targetUserID,
  ) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('user_following')
          .doc(currentUserID)
          .get();

      if (doc.exists) {
        final following = List<String>.from(doc.data()!['following'] ?? []);
        return following.contains(targetUserID);
      }
      return false;
    } catch (e) {
      debugPrint('Erreur lors de la vérification du follow: $e');
      return false;
    }
  }

  /// Obtenir la liste des utilisateurs suivis
  static Future<List<String>> getFollowing(String userID) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('user_following')
          .doc(userID)
          .get();

      if (doc.exists) {
        return List<String>.from(doc.data()!['following'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('Erreur lors de la récupération des suivis: $e');
      return [];
    }
  }

  /// Obtenir la liste des followers
  static Future<List<String>> getFollowers(String userID) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .get();

      if (doc.exists) {
        return List<String>.from(doc.data()!['followers'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('Erreur lors de la récupération des followers: $e');
      return [];
    }
  }

  /// Obtenir les suggestions d'utilisateurs à suivre
  static Future<List<Map<String, dynamic>>> getSuggestedUsers(
    String currentUserID,
  ) async {
    try {
      // Récupérer les utilisateurs que l'utilisateur actuel ne suit pas encore
      final currentUserFollowing = await FirebaseFirestore.instance
          .collection('user_following')
          .doc(currentUserID)
          .get();

      final following = List<String>.from(
        currentUserFollowing.data()?['following'] ?? [],
      );
      following.add(currentUserID); // Exclure l'utilisateur actuel

      // Comme Firestore limite whereNotIn à 10 éléments, on fait une requête simple
      final query = await FirebaseFirestore.instance
          .collection('users')
          .orderBy(
            'totallivegift',
            descending: true,
          ) // Suggérer les utilisateurs avec plus de cadeaux
          .limit(50) // Plus large pour filtrer ensuite
          .get();

      final suggestions = query.docs
          .where((doc) => !following.contains(doc.id))
          .take(20)
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      return suggestions;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des suggestions: $e');
      return [];
    }
  }
}
