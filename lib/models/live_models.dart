import 'package:cloud_firestore/cloud_firestore.dart';

class Gift {
  final String id;
  final String senderId;
  final String senderName;
  final String giftType;
  final DateTime timestamp;
  final String hostId;

  Gift({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.giftType,
    required this.timestamp,
    required this.hostId,
  });

  factory Gift.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Gift(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      giftType: data['giftType'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hostId: data['hostId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'giftType': giftType,
      'timestamp': Timestamp.fromDate(timestamp),
      'hostId': hostId,
    };
  }
}

enum GiftType { heart, star, diamond }

extension GiftTypeExtension on GiftType {
  String get name {
    switch (this) {
      case GiftType.heart:
        return 'heart';
      case GiftType.star:
        return 'star';
      case GiftType.diamond:
        return 'diamond';
    }
  }

  String get displayName {
    switch (this) {
      case GiftType.heart:
        return 'Cœur';
      case GiftType.star:
        return 'Étoile';
      case GiftType.diamond:
        return 'Diamant';
    }
  }

  int get value {
    switch (this) {
      case GiftType.heart:
        return 1;
      case GiftType.star:
        return 5;
      case GiftType.diamond:
        return 10;
    }
  }
}
