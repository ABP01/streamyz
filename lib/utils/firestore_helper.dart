import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreHelper {
  /// Récupère les données utilisateur depuis Firestore
  static Future<Map<String, String>> getUserData(String userID) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() ?? {};
        return {
          'username': userData['username'] ?? 'Utilisateur',
          'avatar': userData['avatar'] ?? '',
          'email': userData['email'] ?? '',
        };
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des données utilisateur: $e');
    }
    
    return {
      'username': 'Utilisateur',
      'avatar': '',
      'email': '',
    };
  }

  /// Récupère uniquement le nom d'utilisateur depuis Firestore
  static Future<String> getUserName(String userID) async {
    final userData = await getUserData(userID);
    return userData['username'] ?? 'Utilisateur';
  }

  /// Récupère uniquement l'avatar depuis Firestore
  static Future<String> getUserAvatar(String userID) async {
    final userData = await getUserData(userID);
    return userData['avatar'] ?? '';
  }
} 