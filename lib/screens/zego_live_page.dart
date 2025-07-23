import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';

class ZegoLivePage extends StatelessWidget {
  final String liveID;
  final String userID;
  final String userName;
  final bool isHost;

  const ZegoLivePage({
    super.key,
    required this.liveID,
    required this.userID,
    required this.userName,
    required this.isHost,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ZegoUIKitPrebuiltLiveStreaming(
        appID: 1145966523,
        appSign:
            '718e87c3fe2843726ed28a6dd25197aac29eb8016d442cc84151c07b65e95d2d',
        userID: userID,
        userName: userName,
        liveID: liveID,
        config: isHost
            ? ZegoUIKitPrebuiltLiveStreamingConfig.host()
            : ZegoUIKitPrebuiltLiveStreamingConfig.audience(),
      ),
    );
  }
}
