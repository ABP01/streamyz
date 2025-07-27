import 'livestats.dart';

class Live {
  final String liveId;
  final String liveUrl;
  final String idHost;
  final String thumbnail;
  final String desc;
  final String nameHost;
  final String avatarHost;
  final String idChat;
  final String srcLive;
  final int livestarttime;
  final int liveendtime;
  final bool isSignaler;
  final bool isPremiumLive;
  final int totalGift;
  final int maxConnect;
  final List<String> invites;
  final Livestats stats;
  final String recordingUrl; // URL de l'enregistrement sur Azure Blob Storage
  final bool isLive; // Statut du live (en cours ou terminé)

  Live({
    required this.liveId,
    required this.liveUrl,
    required this.idHost,
    required this.thumbnail,
    required this.desc,
    required this.nameHost,
    required this.avatarHost,
    required this.idChat,
    required this.srcLive,
    required this.livestarttime,
    required this.liveendtime,
    required this.isSignaler,
    required this.isPremiumLive,
    required this.totalGift,
    required this.maxConnect,
    required this.invites,
    required this.stats,
    this.recordingUrl = '',
    this.isLive = false,
  });

  factory Live.fromMap(Map<String, dynamic> map) => Live(
    liveId: map['live_id'] ?? '',
    liveUrl: map['live_url'] ?? '',
    idHost: map['id_host'] ?? '',
    thumbnail: map['thumbnail'] ?? '',
    desc: map['desc'] ?? '',
    nameHost: map['name_host'] ?? '',
    avatarHost: map['avatar_host'] ?? '',
    idChat: map['id_chat'] ?? '',
    srcLive: map['src_live'] ?? '',
    livestarttime: map['livestarttime'] ?? 0,
    liveendtime: map['liveendtime'] ?? 0,
    isSignaler: map['is_signaler'] ?? false,
    isPremiumLive: map['ispremiumlive'] ?? false,
    totalGift: map['totalgift'] ?? 0,
    maxConnect: map['max_connect'] ?? 0,
    invites: List<String>.from(map['invites'] ?? []),
    stats: Livestats.fromMap(map['stats'] ?? {}),
    recordingUrl: map['recording_url'] ?? '',
    isLive: map['is_live'] ?? false,
  );

  Map<String, dynamic> toMap() => {
    'live_id': liveId,
    'live_url': liveUrl,
    'id_host': idHost,
    'thumbnail': thumbnail,
    'desc': desc,
    'name_host': nameHost,
    'avatar_host': avatarHost,
    'id_chat': idChat,
    'src_live': srcLive,
    'livestarttime': livestarttime,
    'liveendtime': liveendtime,
    'is_signaler': isSignaler,
    'ispremiumlive': isPremiumLive,
    'totalgift': totalGift,
    'max_connect': maxConnect,
    'invites': invites,
    'stats': stats.toMap(),
    'recording_url': recordingUrl,
    'is_live': isLive,
  };
}
