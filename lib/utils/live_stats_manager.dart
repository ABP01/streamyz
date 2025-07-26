import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LiveStatsManager {
  /// Met à jour les statistiques quand un live commence
  static Future<void> onLiveStart(String liveID, String hostID) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Mettre à jour le document principal du live
      await FirebaseFirestore.instance.collection('lives').doc(liveID).update({
        'is_live': true,
        'livestarttime': timestamp,
        'stats.account': 0,
        'stats.likes': 0,
        'stats.tab_likes': [],
        'totalgift': 0,
      });

      // Initialiser la sous-collection livestats
      await FirebaseFirestore.instance
          .collection('lives')
          .doc(liveID)
          .collection('livestats')
          .doc(liveID)
          .set({
            'live_id': liveID,
            'live_url': '',
            'id_host': hostID,
            'tab_likes': [],
            'emojis': [],
            'account': 0,
            'likes': 0,
            'gifters': [],
            'start_time': timestamp,
          });

      debugPrint('Statistiques de live initialisées pour $liveID');
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation des stats du live: $e');
    }
  }

  /// Met à jour les statistiques quand un live se termine
  static Future<void> onLiveEnd(String liveID) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Récupérer les statistiques finales
      final liveDoc = await FirebaseFirestore.instance
          .collection('lives')
          .doc(liveID)
          .get();

      if (liveDoc.exists) {
        final data = liveDoc.data()!;
        final totalLikes = data['stats']?['likes'] ?? 0;
        final totalViewers = data['stats']?['account'] ?? 0;
        final totalGifts = data['totalgift'] ?? 0;
        final hostID = data['id_host'] ?? '';

        // Mettre à jour le document principal
        await FirebaseFirestore.instance.collection('lives').doc(liveID).update(
          {'is_live': false, 'liveendtime': timestamp},
        );

        // Mettre à jour les statistiques finales dans livestats
        await FirebaseFirestore.instance
            .collection('lives')
            .doc(liveID)
            .collection('livestats')
            .doc(liveID)
            .update({
              'end_time': timestamp,
              'final_likes': totalLikes,
              'final_viewers': totalViewers,
              'final_gifts': totalGifts,
            });

        // Mettre à jour les statistiques globales de l'utilisateur host
        if (hostID.isNotEmpty) {
          await _updateUserStats(hostID, totalLikes, totalViewers, totalGifts);
        }

        debugPrint('Statistiques de live finalisées pour $liveID');
      }
    } catch (e) {
      debugPrint('Erreur lors de la finalisation des stats du live: $e');
    }
  }

  /// Met à jour les statistiques globales de l'utilisateur
  static Future<void> _updateUserStats(
    String userID,
    int likes,
    int viewers,
    int gifts,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userID).update({
        'totallivegift': FieldValue.increment(gifts),
        'total_likes_received': FieldValue.increment(likes),
        'total_viewers': FieldValue.increment(viewers),
        'total_lives': FieldValue.increment(1),
      });

      debugPrint('Statistiques utilisateur mises à jour pour $userID');
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour des stats utilisateur: $e');
    }
  }

  /// Ajoute un spectateur au live
  static Future<void> addViewer(String liveID, String userID) async {
    try {
      await FirebaseFirestore.instance.collection('lives').doc(liveID).update({
        'stats.account': FieldValue.increment(1),
      });

      await FirebaseFirestore.instance
          .collection('lives')
          .doc(liveID)
          .collection('livestats')
          .doc(liveID)
          .update({'account': FieldValue.increment(1)});
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout du spectateur: $e');
    }
  }

  /// Retire un spectateur du live
  static Future<void> removeViewer(String liveID, String userID) async {
    try {
      await FirebaseFirestore.instance.collection('lives').doc(liveID).update({
        'stats.account': FieldValue.increment(-1),
      });

      await FirebaseFirestore.instance
          .collection('lives')
          .doc(liveID)
          .collection('livestats')
          .doc(liveID)
          .update({'account': FieldValue.increment(-1)});
    } catch (e) {
      debugPrint('Erreur lors de la suppression du spectateur: $e');
    }
  }

  /// Ajoute un like au live
  static Future<void> addLike(String liveID, String userID) async {
    try {
      await FirebaseFirestore.instance.collection('lives').doc(liveID).update({
        'stats.likes': FieldValue.increment(1),
        'stats.tab_likes': FieldValue.arrayUnion([userID]),
      });

      await FirebaseFirestore.instance
          .collection('lives')
          .doc(liveID)
          .collection('livestats')
          .doc(liveID)
          .update({
            'likes': FieldValue.increment(1),
            'tab_likes': FieldValue.arrayUnion([userID]),
          });
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout du like: $e');
    }
  }

  /// Ajoute un cadeau au live
  static Future<void> addGift(
    String liveID,
    String userID,
    String userName,
    String userAvatar,
  ) async {
    try {
      final giftData = {
        'user_id': userID,
        'username': userName,
        'user_avatar': userAvatar,
        'count': 1,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await FirebaseFirestore.instance.collection('lives').doc(liveID).update({
        'totalgift': FieldValue.increment(1),
        'stats.gifters': FieldValue.arrayUnion([giftData]),
      });

      await FirebaseFirestore.instance
          .collection('lives')
          .doc(liveID)
          .collection('livestats')
          .doc(liveID)
          .update({
            'gifters': FieldValue.arrayUnion([giftData]),
          });
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout du cadeau: $e');
    }
  }
}
