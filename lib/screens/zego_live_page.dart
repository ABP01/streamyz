import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';

class ZegoLivePage extends StatefulWidget {
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
  State<ZegoLivePage> createState() => _ZegoLivePageState();
}

class _ZegoLivePageState extends State<ZegoLivePage> {
  Future<void> _endLiveIfHost() async {
    if (widget.isHost) {
      try {
        await FirebaseFirestore.instance
            .collection('lives')
            .doc(widget.liveID)
            .update({'is_live': false});
      } catch (e) {
        debugPrint('Erreur lors de la fin du live: $e');
      }
    }
  }

  @override
  void dispose() {
    _endLiveIfHost();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.isHost
          ? ZegoUIKitPrebuiltLiveStreaming(
              appID: 1145966523,
              appSign:
                  '718e87c3fe2843726ed28a6dd25197aac29eb8016d442cc84151c07b65e95d2d',
              userID: widget.userID,
              userName: widget.userName,
              liveID: widget.liveID,
              config: ZegoUIKitPrebuiltLiveStreamingConfig.host(),
            )
          : ZegoUIKitPrebuiltLiveStreaming(
              appID: 1145966523,
              appSign:
                  '718e87c3fe2843726ed28a6dd25197aac29eb8016d442cc84151c07b65e95d2d',
              userID: widget.userID,
              userName: widget.userName,
              liveID: widget.liveID,
              config: ZegoUIKitPrebuiltLiveStreamingConfig.audience(),
            ),
    );
  }
}
