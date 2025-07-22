class Donateur {
  final String userId;
  final String username;
  final String userAvatar;
  final int count;

  Donateur({
    required this.userId,
    required this.username,
    required this.userAvatar,
    required this.count,
  });

  factory Donateur.fromMap(Map<String, dynamic> map) => Donateur(
    userId: map['user_id'] ?? '',
    username: map['username'] ?? '',
    userAvatar: map['user_avatar'] ?? '',
    count: map['count'] ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'username': username,
    'user_avatar': userAvatar,
    'count': count,
  };
}
