import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';

/// Widget de test pour vérifier le fonctionnement des boutons ZegoUIKit
class ZegoButtonsTest extends StatelessWidget {
  final String userID;
  final String userName;
  final String liveID;
  final bool isHost;

  const ZegoButtonsTest({
    super.key,
    required this.userID,
    required this.userName,
    required this.liveID,
    required this.isHost,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Boutons ZegoUIKit'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: ZegoUIKitPrebuiltLiveStreaming(
        appID: 1635546276,
        appSign:
            'f8a71bf0e57d934cda48369c059ea936375a67f088be3a5183b8efb147b28d3d',
        userID: userID,
        userName: userName,
        liveID: liveID,
        config: isHost ? _getHostConfig() : _getAudienceConfig(),
      ),
    );
  }

  ZegoUIKitPrebuiltLiveStreamingConfig _getHostConfig() {
    final config = ZegoUIKitPrebuiltLiveStreamingConfig.host();

    // Configuration de base
    config.turnOnCameraWhenJoining = true;
    config.turnOnMicrophoneWhenJoining = true;
    config.useSpeakerWhenJoining = true;

    // Configuration de la barre du haut
    config.topMenuBar.showCloseButton = true;

    // Configuration de la barre du bas - TOUS les boutons disponibles
    config.bottomMenuBar.showInRoomMessageButton = true;
    config.bottomMenuBar.hostButtons = [
      ZegoLiveStreamingMenuBarButtonName.toggleMicrophoneButton,
      ZegoLiveStreamingMenuBarButtonName.toggleCameraButton,
      ZegoLiveStreamingMenuBarButtonName.switchCameraButton,
      ZegoLiveStreamingMenuBarButtonName.leaveButton,
    ];
    config.bottomMenuBar.maxCount = 4;

    // Style des boutons
    config.bottomMenuBar.backgroundColor = Colors.black.withOpacity(0.5);

    return config;
  }

  ZegoUIKitPrebuiltLiveStreamingConfig _getAudienceConfig() {
    final config = ZegoUIKitPrebuiltLiveStreamingConfig.audience();

    // Configuration de base
    config.turnOnCameraWhenJoining = false;
    config.turnOnMicrophoneWhenJoining = false;
    config.useSpeakerWhenJoining = true;

    // Configuration de la barre du haut
    config.topMenuBar.showCloseButton = true;

    // Configuration de la barre du bas
    config.bottomMenuBar.showInRoomMessageButton = true;
    config.bottomMenuBar.audienceButtons = [
      ZegoLiveStreamingMenuBarButtonName.leaveButton,
    ];
    config.bottomMenuBar.maxCount = 1;

    // Style des boutons
    config.bottomMenuBar.backgroundColor = Colors.black.withOpacity(0.5);

    return config;
  }
}
