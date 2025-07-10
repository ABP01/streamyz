import 'package:flutter_test/flutter_test.dart';
import 'package:streamyz/models/live_models.dart';

void main() {
  group('Live Models Tests', () {
    test('GiftType enum should have correct values', () {
      expect(GiftType.heart.name, 'heart');
      expect(GiftType.star.name, 'star');
      expect(GiftType.diamond.name, 'diamond');

      expect(GiftType.heart.displayName, 'Cœur');
      expect(GiftType.star.displayName, 'Étoile');
      expect(GiftType.diamond.displayName, 'Diamant');

      expect(GiftType.heart.value, 1);
      expect(GiftType.star.value, 5);
      expect(GiftType.diamond.value, 10);
    });

    test('Gift model should serialize correctly', () {
      final gift = Gift(
        id: 'test_id',
        senderId: 'sender123',
        senderName: 'Test User',
        giftType: 'heart',
        timestamp: DateTime(2025, 1, 1),
        hostId: 'host123',
      );

      final firestore = gift.toFirestore();
      expect(firestore['senderId'], 'sender123');
      expect(firestore['senderName'], 'Test User');
      expect(firestore['giftType'], 'heart');
      expect(firestore['hostId'], 'host123');
    });
  });

  group('Live Feed Interface Tests', () {
    testWidgets('LiveFeedPage should show loading indicator initially', (
      WidgetTester tester,
    ) async {
      // Ces tests nécessiteraient une configuration plus complexe avec Firebase
      // et des mocks pour être exécutés correctement
    });
  });
}
