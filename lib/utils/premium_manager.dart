import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class PremiumManager {
  static const int PREMIUM_THRESHOLD =
      100; // 100 cadeaux minimum pour être premium
  static const int PREMIUM_MAX_INVITES = 5;
  static const int REGULAR_MAX_INVITES = 2;

  /// Vérifier et mettre à jour le statut premium d'un utilisateur
  static Future<bool> checkAndUpdatePremiumStatus(String userID) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final totalGifts = userData['totallivegift'] ?? 0;
      final currentPremiumStatus = userData['is_premium'] ?? false;

      final shouldBePremium = totalGifts >= PREMIUM_THRESHOLD;

      // Mettre à jour le statut si nécessaire
      if (currentPremiumStatus != shouldBePremium) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userID)
            .update({
              'is_premium': shouldBePremium,
              'premium_updated_at': DateTime.now().millisecondsSinceEpoch,
            });

        // Créer une notification si l'utilisateur devient premium
        if (shouldBePremium && !currentPremiumStatus) {
          await _createPremiumNotification(userID);
        }

        debugPrint('Statut premium mis à jour pour $userID: $shouldBePremium');
      }

      return shouldBePremium;
    } catch (e) {
      debugPrint('Erreur lors de la vérification du statut premium: $e');
      return false;
    }
  }

  /// Créer une notification pour féliciter l'utilisateur devenu premium
  static Future<void> _createPremiumNotification(String userID) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'to_user_id': userID,
        'type': 'premium_upgrade',
        'title': 'Félicitations ! 🎉',
        'message':
            'Vous êtes maintenant un utilisateur Premium ! Vous pouvez inviter jusqu\'à 5 personnes dans vos lives.',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'read': false,
      });
    } catch (e) {
      debugPrint('Erreur lors de la création de la notification premium: $e');
    }
  }

  /// Obtenir le nombre maximum d'invitations pour un utilisateur
  static Future<int> getMaxInvites(String userID) async {
    try {
      final isPremium = await isPremiumUser(userID);
      return isPremium ? PREMIUM_MAX_INVITES : REGULAR_MAX_INVITES;
    } catch (e) {
      debugPrint(
        'Erreur lors de la récupération des limites d\'invitation: $e',
      );
      return REGULAR_MAX_INVITES;
    }
  }

  /// Vérifier si un utilisateur est premium
  static Future<bool> isPremiumUser(String userID) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final totalGifts = userData['totallivegift'] ?? 0;
        return totalGifts >= PREMIUM_THRESHOLD;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur lors de la vérification du statut premium: $e');
      return false;
    }
  }

  /// Obtenir les informations premium d'un utilisateur
  static Future<Map<String, dynamic>> getPremiumInfo(String userID) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final totalGifts = userData['totallivegift'] ?? 0;
        final isPremium = totalGifts >= PREMIUM_THRESHOLD;
        final giftsNeeded = isPremium ? 0 : PREMIUM_THRESHOLD - totalGifts;

        return {
          'is_premium': isPremium,
          'total_gifts': totalGifts,
          'gifts_needed': giftsNeeded,
          'premium_threshold': PREMIUM_THRESHOLD,
          'max_invites': isPremium ? PREMIUM_MAX_INVITES : REGULAR_MAX_INVITES,
          'premium_percentage': (totalGifts / PREMIUM_THRESHOLD * 100)
              .clamp(0, 100)
              .toInt(),
        };
      }

      return {
        'is_premium': false,
        'total_gifts': 0,
        'gifts_needed': PREMIUM_THRESHOLD,
        'premium_threshold': PREMIUM_THRESHOLD,
        'max_invites': REGULAR_MAX_INVITES,
        'premium_percentage': 0,
      };
    } catch (e) {
      debugPrint('Erreur lors de la récupération des infos premium: $e');
      return {
        'is_premium': false,
        'total_gifts': 0,
        'gifts_needed': PREMIUM_THRESHOLD,
        'premium_threshold': PREMIUM_THRESHOLD,
        'max_invites': REGULAR_MAX_INVITES,
        'premium_percentage': 0,
      };
    }
  }

  /// Vérifier si un utilisateur peut inviter plus de personnes
  static Future<bool> canInviteMore(String userID, String liveID) async {
    try {
      final liveDoc = await FirebaseFirestore.instance
          .collection('lives')
          .doc(liveID)
          .get();

      if (!liveDoc.exists) return false;

      final liveData = liveDoc.data()!;
      final invites = List<String>.from(liveData['invites'] ?? []);
      final maxInvites = await getMaxInvites(userID);

      return invites.length < maxInvites;
    } catch (e) {
      debugPrint('Erreur lors de la vérification des invitations: $e');
      return false;
    }
  }

  /// Ajouter une invitation à un live
  static Future<bool> addInviteToLive(
    String userID,
    String liveID,
    String invitedUserID,
  ) async {
    try {
      // Vérifier si l'utilisateur peut inviter plus de personnes
      final canInvite = await canInviteMore(userID, liveID);
      if (!canInvite) {
        debugPrint('Limite d\'invitations atteinte pour $userID');
        return false;
      }

      // Ajouter l'invitation
      await FirebaseFirestore.instance.collection('lives').doc(liveID).update({
        'invites': FieldValue.arrayUnion([invitedUserID]),
      });

      // Créer une notification d'invitation
      await FirebaseFirestore.instance.collection('notifications').add({
        'from_user_id': userID,
        'to_user_id': invitedUserID,
        'type': 'live_invite',
        'live_id': liveID,
        'message': 'vous a invité à rejoindre son live',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'read': false,
      });

      debugPrint('Invitation ajoutée: $invitedUserID au live $liveID');
      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout de l\'invitation: $e');
      return false;
    }
  }

  /// Obtenir les utilisateurs premium
  static Future<List<Map<String, dynamic>>> getPremiumUsers({
    int limit = 20,
  }) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('totallivegift', isGreaterThanOrEqualTo: PREMIUM_THRESHOLD)
          .orderBy('totallivegift', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des utilisateurs premium: $e');
      return [];
    }
  }

  /// Mettre à jour le statut premium après réception d'un cadeau
  static Future<void> onGiftReceived(String userID, int giftCount) async {
    try {
      // Mettre à jour le total des cadeaux
      await FirebaseFirestore.instance.collection('users').doc(userID).update({
        'totallivegift': FieldValue.increment(giftCount),
      });

      // Vérifier et mettre à jour le statut premium
      await checkAndUpdatePremiumStatus(userID);
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour après réception de cadeau: $e');
    }
  }
}
