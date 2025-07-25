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
              appID: 1635546276,
              appSign:
                  'f8a71bf0e57d934cda48369c059ea936375a67f088be3a5183b8efb147b28d3d',
              userID: widget.userID,
              userName: widget.userName,
              liveID: widget.liveID,
              config: ZegoUIKitPrebuiltLiveStreamingConfig.host(),
            )
          : ZegoUIKitPrebuiltLiveStreaming(
              appID: 1635546276,
              appSign:
                  'f8a71bf0e57d934cda48369c059ea936375a67f088be3a5183b8efb147b28d3d',
              userID: widget.userID,
              userName: widget.userName,
              liveID: widget.liveID,
              config: ZegoUIKitPrebuiltLiveStreamingConfig.audience(),
            ),
    );
  }
}
