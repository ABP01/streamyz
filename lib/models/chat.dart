import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String liveId;
  final String idChat;
  final String idHost;
  final String message;
  final String idUser;
  final DateTime? time;

  Chat({
    required this.liveId,
    required this.idChat,
    required this.idHost,
    required this.message,
    required this.idUser,
    this.time,
  });

  factory Chat.fromMap(Map<String, dynamic> map) => Chat(
    liveId: map['live_id'] ?? '',
    idChat: map['id_chat'] ?? '',
    idHost: map['id_host'] ?? '',
    message: map['message'] ?? '',
    idUser: map['id_user'] ?? '',
    time: map['time'] != null ? (map['time'] as Timestamp).toDate() : null,
  );

  Map<String, dynamic> toMap() => {
    'live_id': liveId,
    'id_chat': idChat,
    'id_host': idHost,
    'message': message,
    'id_user': idUser,
    'time': time,
  };
}
