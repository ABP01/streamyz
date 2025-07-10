import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/live_models.dart';

class StreamingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtenir la liste des lives actifs
  static Stream<List<Map<String, dynamic>>> getActiveLiveStreams() {
    return _firestore
        .collection('users')
        .where('isLive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'username': data['username'] ?? 'Streamer',
              'displayName': data['displayName'],
              'avatarUrl': data['avatarUrl'],
              'liveStartTime': data['liveStartTime'],
              'liveStats':
                  data['liveStats'] ??
                  {'totalGifts': 0, 'totalGiftValue': 0, 'totalViewers': 0},
            };
          }).toList();
        });
  }

  // Démarrer un live
  static Future<void> startLive(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isLive': true,
        'liveStartTime': FieldValue.serverTimestamp(),
        'liveStats': {
          'totalGifts': 0,
          'totalGiftValue': 0,
          'totalViewers': 0,
          'lastGiftReceived': null,
        },
      });

      // Créer une session live
      await _firestore.collection('live_sessions').doc('live_$userId').set({
        'hostId': userId,
        'startTime': FieldValue.serverTimestamp(),
        'isActive': true,
        'viewerCount': 0,
        'totalGifts': 0,
        'totalGiftValue': 0,
      });
    } catch (e) {
      throw Exception('Impossible de démarrer le live: $e');
    }
  }

  // Arrêter un live
  static Future<void> stopLive(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isLive': false,
        'liveEndTime': FieldValue.serverTimestamp(),
      });

      // Mettre à jour la session live
      await _firestore.collection('live_sessions').doc('live_$userId').update({
        'endTime': FieldValue.serverTimestamp(),
        'isActive': false,
      });
    } catch (e) {
      throw Exception('Impossible d\'arrêter le live: $e');
    }
  }

  // Rejoindre un live (spectateur)
  static Future<void> joinLiveAsViewer(String liveId, String hostId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Incrémenter le nombre de spectateurs
      await _firestore.collection('live_sessions').doc(liveId).update({
        'viewerCount': FieldValue.increment(1),
      });

      // Ajouter le spectateur à la liste
      await _firestore
          .collection('live_sessions')
          .doc(liveId)
          .collection('viewers')
          .doc(currentUser.uid)
          .set({
            'userId': currentUser.uid,
            'userName':
                currentUser.displayName ?? currentUser.email ?? 'Spectateur',
            'joinedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Erreur lors de la connexion au live: $e');
    }
  }

  // Quitter un live (spectateur)
  static Future<void> leaveLiveAsViewer(String liveId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Décrémenter le nombre de spectateurs
      await _firestore.collection('live_sessions').doc(liveId).update({
        'viewerCount': FieldValue.increment(-1),
      });

      // Supprimer le spectateur de la liste
      await _firestore
          .collection('live_sessions')
          .doc(liveId)
          .collection('viewers')
          .doc(currentUser.uid)
          .delete();
    } catch (e) {
      print('Erreur lors de la déconnexion du live: $e');
    }
  }

  // Envoyer un cadeau avec animations
  static Future<void> sendGiftWithAnimation(
    String liveId,
    String hostId,
    GiftType giftType,
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Utilisateur non connecté');

    try {
      final gift = Gift(
        id: '',
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? currentUser.email ?? 'Anonyme',
        giftType: giftType.name,
        timestamp: DateTime.now(),
        hostId: hostId,
      );

      // Enregistrer le cadeau
      await _firestore
          .collection('gifts')
          .doc(liveId)
          .collection('gifts')
          .add(gift.toFirestore());

      // Mettre à jour les statistiques du live
      await _firestore.collection('live_sessions').doc(liveId).update({
        'totalGifts': FieldValue.increment(1),
        'totalGiftValue': FieldValue.increment(giftType.value),
      });

      // Mettre à jour les statistiques du streamer
      await _firestore.collection('users').doc(hostId).update({
        'liveStats.totalGifts': FieldValue.increment(1),
        'liveStats.totalGiftValue': FieldValue.increment(giftType.value),
        'liveStats.lastGiftReceived': FieldValue.serverTimestamp(),
      });

      // Créer une notification de cadeau en temps réel
      await _firestore
          .collection('live_notifications')
          .doc(liveId)
          .collection('notifications')
          .add({
            'type': 'gift',
            'senderId': currentUser.uid,
            'senderName': gift.senderName,
            'giftType': giftType.name,
            'giftValue': giftType.value,
            'timestamp': FieldValue.serverTimestamp(),
            'hostId': hostId,
          });
    } catch (e) {
      throw Exception('Impossible d\'envoyer le cadeau: $e');
    }
  }

  // Obtenir les notifications en temps réel
  static Stream<List<Map<String, dynamic>>> getLiveNotifications(
    String liveId,
  ) {
    return _firestore
        .collection('live_notifications')
        .doc(liveId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList();
        });
  }

  // Obtenir les spectateurs connectés
  static Stream<List<Map<String, dynamic>>> getLiveViewers(String liveId) {
    return _firestore
        .collection('live_sessions')
        .doc(liveId)
        .collection('viewers')
        .orderBy('joinedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList();
        });
  }

  // Obtenir les statistiques du live
  static Stream<Map<String, dynamic>?> getLiveStats(String liveId) {
    return _firestore.collection('live_sessions').doc(liveId).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        return doc.data();
      }
      return null;
    });
  }

  // Nettoyer les données du live (appelé quand le live se termine)
  static Future<void> cleanupLiveData(String liveId) async {
    try {
      // Supprimer les notifications
      final notificationsQuery = await _firestore
          .collection('live_notifications')
          .doc(liveId)
          .collection('notifications')
          .get();

      final batch = _firestore.batch();
      for (var doc in notificationsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Supprimer les spectateurs
      final viewersQuery = await _firestore
          .collection('live_sessions')
          .doc(liveId)
          .collection('viewers')
          .get();

      for (var doc in viewersQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Erreur lors du nettoyage des données du live: $e');
    }
  }

  // Signaler un live
  static Future<void> reportLive(String liveId, String reason) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore.collection('live_reports').add({
        'liveId': liveId,
        'reporterId': currentUser.uid,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Impossible de signaler le live: $e');
    }
  }
}
