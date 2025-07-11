/// Configuration Zego pour l'application Streamyz
class ZegoConfig {
  // Configuration pour le live streaming (ZegoUIKit)
  static const int liveStreamingAppID = 1145966523;
  static const String liveStreamingAppSign =
      "718e87c3fe2843726ed28a6dd25197aac29eb8016d442cc84151c07b65e95d2d";

  // Configuration pour le signaling (ZIM)
  static const int signalingAppID = 646767905;
  static const String signalingAppSign =
      'e344270b3a92a09da043bb179a9642f3827bd0d35d6caf4553fa22d4a8419e26';

  // Validation des configurations
  static bool get isLiveStreamingConfigValid =>
      liveStreamingAppID > 0 && liveStreamingAppSign.isNotEmpty;

  static bool get isSignalingConfigValid =>
      signalingAppID > 0 && signalingAppSign.isNotEmpty;
}
