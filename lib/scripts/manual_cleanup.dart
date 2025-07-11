import 'package:cloud_firestore/cloud_firestore.dart';

/// Script pour nettoyer manuellement les faux lives
/// À exécuter une seule fois pour résoudre le problème actuel
Future<void> manualLiveCleanup() async {
  final firestore = FirebaseFirestore.instance;

  print('🧹 === NETTOYAGE MANUEL DES LIVES ===');

  // IDs des utilisateurs problématiques identifiés dans les logs
  final problematicUsers = [
    '8ckdRbFqoqPyA6m970oAmfhOhDt2', // Armel
    'C5m4mvOLKZScaUVAXkGG223Q1uA3', // Alex
    'E69ExHjI92S7NmklyCFT8liWPXl1', // Pascal
  ];

  for (final userId in problematicUsers) {
    try {
      print('🧽 Nettoyage de l\'utilisateur: $userId');

      // Récupérer les infos utilisateur
      final userDoc = await firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final username =
            userData['username'] ?? userData['displayName'] ?? userId;

        print('   👤 Utilisateur: $username');
        print('   📊 isLive avant: ${userData['isLive']}');

        // Forcer la mise à jour
        await firestore.collection('users').doc(userId).update({
          'isLive': false,
          'liveStartTime': FieldValue.delete(),
          'liveEndTime': FieldValue.serverTimestamp(),
          'manualCleanup': FieldValue.serverTimestamp(),
        });

        print('   ✅ isLive maintenant: false');
      } else {
        print('   ❌ Utilisateur non trouvé');
      }
    } catch (e) {
      print('   ❌ Erreur: $e');
    }
  }

  print('🎉 Nettoyage manuel terminé !');
}

/// Vérifier l'état après nettoyage
Future<void> verifyCleanup() async {
  final firestore = FirebaseFirestore.instance;

  print('🔍 === VÉRIFICATION POST-NETTOYAGE ===');

  final liveUsersQuery = await firestore
      .collection('users')
      .where('isLive', isEqualTo: true)
      .get();

  print('📊 Utilisateurs encore en live: ${liveUsersQuery.docs.length}');

  for (final doc in liveUsersQuery.docs) {
    final userData = doc.data();
    final username = userData['username'] ?? userData['displayName'] ?? doc.id;
    final liveStartTime = userData['liveStartTime'] as Timestamp?;

    print('   👤 $username (${doc.id})');
    if (liveStartTime != null) {
      final duration = DateTime.now().difference(liveStartTime.toDate());
      print('      🕐 En live depuis: ${duration.inMinutes} minutes');
    }
  }
}
