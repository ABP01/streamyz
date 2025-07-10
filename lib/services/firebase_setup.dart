import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseSetup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialise les statistiques live pour un utilisateur
  static Future<void> initializeUserLiveStats(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;

        // Vérifie si les statistiques live existent déjà
        if (!data.containsKey('liveStats')) {
          await _firestore.collection('users').doc(userId).update({
            'liveStats': {
              'totalGifts': 0,
              'totalGiftValue': 0,
              'totalViewers': 0,
              'lastGiftReceived': null,
            },
            'isLive': false,
            'liveStartTime': null,
            'liveEndTime': null,
          });
        }
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation des stats live: $e');
    }
  }

  /// Nettoie les anciens lives qui ne sont plus actifs
  static Future<void> cleanupOldLives() async {
    try {
      // Trouve tous les utilisateurs marqués comme live
      final liveUsers = await _firestore
          .collection('users')
          .where('isLive', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      final now = DateTime.now();

      for (final doc in liveUsers.docs) {
        final data = doc.data();
        final liveStartTime = data['liveStartTime'] as Timestamp?;

        // Si le live a commencé il y a plus de 24h, le marquer comme terminé
        if (liveStartTime != null) {
          final startTime = liveStartTime.toDate();
          final timeDifference = now.difference(startTime);

          if (timeDifference.inHours > 24) {
            batch.update(doc.reference, {
              'isLive': false,
              'liveEndTime': FieldValue.serverTimestamp(),
            });
          }
        }
      }

      await batch.commit();
    } catch (e) {
      print('Erreur lors du nettoyage des anciens lives: $e');
    }
  }
}
