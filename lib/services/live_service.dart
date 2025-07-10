import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/live_models.dart';

class LiveService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Envoyer un cadeau
  static Future<void> sendGift(
    String liveID,
    String hostId,
    GiftType giftType,
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Utilisateur non connecté');

    final gift = Gift(
      id: '',
      senderId: currentUser.uid,
      senderName: currentUser.displayName ?? currentUser.email ?? 'Anonyme',
      giftType: giftType.name,
      timestamp: DateTime.now(),
      hostId: hostId,
    );

    // Enregistrer dans la collection globale des cadeaux
    await _firestore
        .collection('gifts')
        .add(gift.toFirestore()..['liveID'] = liveID);

    // Mettre à jour les statistiques du streamer
    await updateLiveStats(hostId, giftType.value);
  }

  // Obtenir les cadeaux en temps réel
  static Stream<List<Gift>> getGiftsStream(String liveID) {
    return _firestore
        .collection('gifts')
        .where('liveID', isEqualTo: liveID)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Gift.fromFirestore(doc)).toList(),
        );
  }

  // Obtenir la liste des lives actifs
  static Stream<List<Map<String, dynamic>>> getActiveLiveStreams() {
    return _firestore
        .collection('users')
        .where('isLive', isEqualTo: true)
        // Temporarily remove orderBy to avoid index requirement
        .snapshots()
        .map((snapshot) {
          // Sort in memory instead
          final docs = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();

          // Sort by liveStartTime in descending order
          docs.sort((a, b) {
            final aTime = a['liveStartTime'] as Timestamp?;
            final bTime = b['liveStartTime'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime); // Descending order
          });

          return docs;
        });
  }

  // Mettre à jour les statistiques live (rendu public)
  static Future<void> updateLiveStats(String hostId, int giftValue) async {
    final userRef = _firestore.collection('users').doc(hostId);

    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final currentStats =
            userData['liveStats'] as Map<String, dynamic>? ?? {};
        final currentGifts = currentStats['totalGifts'] as int? ?? 0;
        final currentValue = currentStats['totalGiftValue'] as int? ?? 0;

        transaction.update(userRef, {
          'liveStats.totalGifts': currentGifts + 1,
          'liveStats.totalGiftValue': currentValue + giftValue,
          'liveStats.lastGiftReceived': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // Mettre à jour le nombre de spectateurs
  static Future<void> updateViewerCount(String hostId, int viewerCount) async {
    await _firestore.collection('users').doc(hostId).update({
      'liveStats.totalViewers': viewerCount,
    });
  }

  // Démarrer un live
  static Future<void> startLive(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isLive': true,
      'liveStartTime': FieldValue.serverTimestamp(),
      'liveStats': {'totalGifts': 0, 'totalGiftValue': 0, 'totalViewers': 0},
    });
  }

  // Arrêter un live
  static Future<void> stopLive(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isLive': false,
      'liveEndTime': FieldValue.serverTimestamp(),
    });
  }

  // Nettoyer les anciens cadeaux
  static Future<void> cleanupLiveData(String liveID) async {
    final batch = _firestore.batch();

    // Supprimer les cadeaux associés au live
    final giftsQuery = await _firestore
        .collection('gifts')
        .where('liveID', isEqualTo: liveID)
        .get();

    for (final doc in giftsQuery.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Obtenir les statistiques globales des lives
  static Future<Map<String, int>> getGlobalLiveStats() async {
    final giftsSnapshot = await _firestore.collection('gifts').get();
    final usersSnapshot = await _firestore
        .collection('users')
        .where('liveStats.totalGifts', isGreaterThan: 0)
        .get();

    int totalGifts = 0;
    int totalValue = 0;
    int totalStreamers = usersSnapshot.docs.length;

    for (final doc in giftsSnapshot.docs) {
      final data = doc.data();
      final giftType = data['giftType'] as String? ?? 'heart';
      int value = 1;

      switch (giftType) {
        case 'star':
          value = 5;
          break;
        case 'diamond':
          value = 10;
          break;
      }

      totalGifts++;
      totalValue += value;
    }

    return {
      'totalGifts': totalGifts,
      'totalValue': totalValue,
      'totalStreamers': totalStreamers,
    };
  }
}
