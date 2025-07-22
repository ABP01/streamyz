import 'donateur.dart';

class Livestats {
  final String liveId;
  final String liveUrl;
  final String idHost;
  final List<String> tabLikes;
  final List<dynamic> emojis;
  final int account;
  final int likes;
  final List<Donateur> gifters;

  Livestats({
    required this.liveId,
    required this.liveUrl,
    required this.idHost,
    required this.tabLikes,
    required this.emojis,
    required this.account,
    required this.likes,
    required this.gifters,
  });

  factory Livestats.fromMap(Map<String, dynamic> map) => Livestats(
    liveId: map['live_id'] ?? '',
    liveUrl: map['live_url'] ?? '',
    idHost: map['id_host'] ?? '',
    tabLikes: List<String>.from(map['tab_likes'] ?? []),
    emojis: List<dynamic>.from(map['emojis'] ?? []),
    account: map['account'] ?? 0,
    likes: map['likes'] ?? 0,
    gifters: (map['gifters'] as List<dynamic>? ?? [])
        .map((e) => Donateur.fromMap(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toMap() => {
    'live_id': liveId,
    'live_url': liveUrl,
    'id_host': idHost,
    'tab_likes': tabLikes,
    'emojis': emojis,
    'account': account,
    'likes': likes,
    'gifters': gifters.map((d) => d.toMap()).toList(),
  };
}
