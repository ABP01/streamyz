import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class OnlineStatusManager {
  static Timer? _heartbeatTimer;
  static String? _currentUserID;
  static bool _isInitialized = false;

  /// Initialiser le gestionnaire de statut en ligne
  static Future<void> initialize() async {
    if (_isInitialized) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _currentUserID = user.uid;
    _isInitialized = true;

    // Marquer l'utilisateur comme en ligne
    await _setOnlineStatus(true);

    // Démarrer le heartbeat pour maintenir le statut en ligne
    _startHeartbeat();

    // Écouter les changements d'état de l'application
    _setupAppLifecycleListener();

    debugPrint('OnlineStatusManager initialisé pour ${user.uid}');
  }

  /// Marquer l'utilisateur comme en ligne ou hors ligne
  static Future<void> _setOnlineStatus(bool isOnline) async {
    if (_currentUserID == null) return;

    try {
      // Utiliser une collection séparée pour le statut en ligne
      await FirebaseFirestore.instance
          .collection('user_status')
          .doc(_currentUserID!)
          .set({
            'user_id': _currentUserID!,
            'is_online': isOnline,
            'last_seen': DateTime.now().millisecondsSinceEpoch,
          }, SetOptions(merge: true));

      debugPrint('Statut en ligne mis à jour: $isOnline');
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du statut en ligne: $e');
    }
  }

  /// Démarrer le heartbeat pour maintenir le statut en ligne
  static void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _setOnlineStatus(true);
    });
  }

  /// Arrêter le heartbeat
  static void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Configurer l'écoute du cycle de vie de l'application
  static void _setupAppLifecycleListener() {
    // Note: Dans une vraie implémentation, vous utiliseriez WidgetsBindingObserver
    // Ici nous simulons avec la gestion de base
  }

  /// Marquer l'utilisateur comme en ligne
  static Future<void> setOnline() async {
    await _setOnlineStatus(true);
    _startHeartbeat();
  }

  /// Marquer l'utilisateur comme hors ligne
  static Future<void> setOffline() async {
    _stopHeartbeat();
    await _setOnlineStatus(false);
  }

  /// Nettoyer les ressources
  static Future<void> dispose() async {
    _stopHeartbeat();
    await _setOnlineStatus(false);
    _isInitialized = false;
    _currentUserID = null;
    debugPrint('OnlineStatusManager fermé');
  }

  /// Vérifier si un utilisateur est en ligne
  static Future<bool> isUserOnline(String userID) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('user_status')
          .doc(userID)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final isOnline = data['is_online'] ?? false;
        final lastSeen = data['last_seen'] ?? 0;

        // Si marqué comme en ligne mais pas d'activité depuis plus de 5 minutes,
        // considérer comme hors ligne
        if (isOnline) {
          final now = DateTime.now().millisecondsSinceEpoch;
          final timeDiff = now - lastSeen;
          if (timeDiff > 300000) {
            // 5 minutes en millisecondes
            return false;
          }
        }

        return isOnline;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur lors de la vérification du statut en ligne: $e');
      return false;
    }
  }

  /// Obtenir la dernière activité d'un utilisateur
  static Future<DateTime?> getLastSeen(String userID) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('user_status')
          .doc(userID)
          .get();

      if (doc.exists) {
        final lastSeen = doc.data()?['last_seen'];
        if (lastSeen != null) {
          return DateTime.fromMillisecondsSinceEpoch(lastSeen);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la dernière activité: $e');
      return null;
    }
  }

  /// Obtenir les utilisateurs en ligne parmi une liste d'IDs
  static Future<List<String>> getOnlineUsers(List<String> userIDs) async {
    if (userIDs.isEmpty) return [];

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final fiveMinutesAgo = now - 300000; // 5 minutes

      // Firestore limite les requêtes whereIn à 10 éléments
      final List<String> onlineUsers = [];

      for (int i = 0; i < userIDs.length; i += 10) {
        final batch = userIDs.skip(i).take(10).toList();

        final query = await FirebaseFirestore.instance
            .collection('user_status')
            .where(FieldPath.documentId, whereIn: batch)
            .where('is_online', isEqualTo: true)
            .where('last_seen', isGreaterThan: fiveMinutesAgo)
            .get();

        for (final doc in query.docs) {
          onlineUsers.add(doc.id);
        }
      }

      return onlineUsers;
    } catch (e) {
      debugPrint(
        'Erreur lors de la récupération des utilisateurs en ligne: $e',
      );
      return [];
    }
  }

  /// Stream pour écouter le statut en ligne d'un utilisateur
  static Stream<bool> watchUserOnlineStatus(String userID) {
    return FirebaseFirestore.instance
        .collection('user_status')
        .doc(userID)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            final data = doc.data()!;
            final isOnline = data['is_online'] ?? false;
            final lastSeen = data['last_seen'] ?? 0;

            if (isOnline) {
              final now = DateTime.now().millisecondsSinceEpoch;
              final timeDiff = now - lastSeen;
              return timeDiff <= 300000; // Moins de 5 minutes
            }

            return false;
          }
          return false;
        });
  }
}
