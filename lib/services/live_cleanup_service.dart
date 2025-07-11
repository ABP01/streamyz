import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LiveCleanupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Nettoie tous les statuts de live obsolètes
  static Future<void> cleanupStaleLives() async {
    try {
      print('🧹 Début du nettoyage des lives obsolètes...');

      // Récupérer tous les utilisateurs marqués comme "en live"
      final liveUsersQuery = await _firestore
          .collection('users')
          .where('isLive', isEqualTo: true)
          .get();

      print(
        '📊 ${liveUsersQuery.docs.length} utilisateurs trouvés avec isLive: true',
      );

      int cleanedCount = 0;

      for (final userDoc in liveUsersQuery.docs) {
        final userData = userDoc.data();
        final userId = userDoc.id;
        final username = userData['username'] ?? userId;

        // Vérifier si le live a un timestamp récent (moins de 2 heures)
        final liveStartTime = userData['liveStartTime'] as Timestamp?;
        final now = DateTime.now();

        bool shouldCleanup = false;
        String reason = '';

        if (liveStartTime == null) {
          shouldCleanup = true;
          reason = 'Pas de timestamp de début';
        } else {
          final startTime = liveStartTime.toDate();
          final difference = now.difference(startTime);

          // Si le live dure depuis plus de 2 heures, c'est probablement obsolète
          if (difference.inHours > 2) {
            shouldCleanup = true;
            reason = 'Live actif depuis ${difference.inHours}h (trop long)';
          }
        }

        if (shouldCleanup) {
          print('🧽 Nettoyage de $username ($userId): $reason');

          await _firestore.collection('users').doc(userId).update({
            'isLive': false,
            'liveStartTime': FieldValue.delete(),
            'liveEndTime': FieldValue.serverTimestamp(),
            'lastCleanup': FieldValue.serverTimestamp(),
          });

          cleanedCount++;
        } else {
          print('✅ $username ($userId): Live valide');
        }
      }

      print('🎉 Nettoyage terminé: $cleanedCount lives obsolètes supprimés');
    } catch (e) {
      print('❌ Erreur lors du nettoyage: $e');
    }
  }

  /// Force le nettoyage d'un utilisateur spécifique
  static Future<void> forceCleanupUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isLive': false,
        'liveStartTime': FieldValue.delete(),
        'liveEndTime': FieldValue.serverTimestamp(),
        'forceCleanup': FieldValue.serverTimestamp(),
      });

      print('🧽 Force cleanup effectué pour l\'utilisateur: $userId');
    } catch (e) {
      print('❌ Erreur lors du force cleanup: $e');
    }
  }

  /// Vérifie si un live est réellement actif
  static Future<bool> isLiveReallyActive(String userId, String liveId) async {
    try {
      // Vérifier dans Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>;
      final isLive = userData['isLive'] == true;

      if (!isLive) return false;

      // Vérifier le timestamp
      final liveStartTime = userData['liveStartTime'] as Timestamp?;
      if (liveStartTime == null) return false;

      final startTime = liveStartTime.toDate();
      final now = DateTime.now();
      final difference = now.difference(startTime);

      // Si le live dure depuis plus de 2 heures, on considère qu'il n'est plus actif
      if (difference.inHours > 2) {
        print(
          '⚠️ Live de $userId actif depuis ${difference.inHours}h - Considéré comme inactif',
        );
        return false;
      }

      return true;
    } catch (e) {
      print('❌ Erreur lors de la vérification du live: $e');
      return false;
    }
  }

  /// Nettoie automatiquement au démarrage de l'app
  static Future<void> autoCleanupOnAppStart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    print('🚀 Auto-nettoyage au démarrage de l\'app...');
    await cleanupStaleLives();
  }
}
