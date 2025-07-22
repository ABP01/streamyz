class User {
  final String id;
  final String email;
  final String username;
  final String password;
  final String avatar;
  final String usernameLower;
  final bool isPremium;
  final int totalLiveGift;
  final List<String> followers;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.password,
    required this.avatar,
    required this.usernameLower,
    required this.isPremium,
    required this.totalLiveGift,
    required this.followers,
  });

  factory User.fromMap(Map<String, dynamic> map) => User(
    id: map['id'] ?? '',
    email: map['email'] ?? '',
    username: map['username'] ?? '',
    password: map['password'] ?? '',
    avatar: map['avatar'] ?? '',
    usernameLower: map['username_lower'] ?? '',
    isPremium: map['is_premium'] ?? false,
    totalLiveGift: map['totallivegift'] ?? 0,
    followers: List<String>.from(map['followers'] ?? []),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'username': username,
    'password': password,
    'avatar': avatar,
    'username_lower': usernameLower,
    'is_premium': isPremium,
    'totallivegift': totalLiveGift,
    'followers': followers,
  };
}
