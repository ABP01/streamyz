import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';

const int appID = 1145966523;
const String appSign =
    "718e87c3fe2843726ed28a6dd25197aac29eb8016d442cc84151c07b65e95d2d";

class LiveStreamBasePage extends StatefulWidget {
  const LiveStreamBasePage({super.key});

  @override
  State<LiveStreamBasePage> createState() => _LiveStreamBasePageState();
}

class _LiveStreamBasePageState extends State<LiveStreamBasePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ZegoLiveStream(
                    uid: '111111',
                    userName: 'Start',
                    liveID: 'live111',
                  ),
                ),
              );
            },
            child: const Text("Démarrer le live"),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ZegoLiveStream(
                    uid: '222222',
                    userName: 'Joiner',
                    liveID: 'live111',
                  ),
                ),
              );
            },
            child: const Text("Rejoindre un live"),
          ),
        ],
      ),
    );
  }
}

class ZegoLiveStream extends StatefulWidget {
  const ZegoLiveStream({super.key, required this.uid, required this.userName, required this.liveID});
  final String uid;
  final String userName;
  final String liveID;

  @override
  State<ZegoLiveStream> createState() => _ZegoLiveStreamState();
}

class _ZegoLiveStreamState extends State<ZegoLiveStream> {
  @override
  Widget build(BuildContext context) {
    return ZegoUIKitPrebuiltLiveStreaming(
      appID: appID,
      appSign: appSign,
      userID: widget.uid,
      userName: widget.userName,
      liveID: widget.liveID,
      config: widget.uid == '111111' ? 
          ZegoUIKitPrebuiltLiveStreamingConfig.host() :
          ZegoUIKitPrebuiltLiveStreamingConfig.audience(),
    );
  }
}
