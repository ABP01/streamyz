import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';

class LiveControlsWidget extends StatefulWidget {
  final bool isHost;
  final VoidCallback? onEndLive;
  final VoidCallback? onInvite;

  const LiveControlsWidget({
    super.key,
    required this.isHost,
    this.onEndLive,
    this.onInvite,
  });

  @override
  State<LiveControlsWidget> createState() => _LiveControlsWidgetState();
}

class _LiveControlsWidgetState extends State<LiveControlsWidget> {
  bool _isCameraOn = true;
  bool _isMicrophoneOn = true;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Bouton caméra (host seulement)
            if (widget.isHost)
              _buildControlButton(
                icon: _isCameraOn
                    ? Icons.camera_alt
                    : Icons.camera_alt_outlined,
                color: _isCameraOn ? Colors.white : Colors.grey,
                onTap: _toggleCamera,
              ),

            // Bouton microphone (host seulement)
            if (widget.isHost)
              _buildControlButton(
                icon: _isMicrophoneOn ? Icons.mic : Icons.mic_off,
                color: _isMicrophoneOn ? Colors.white : Colors.grey,
                onTap: _toggleMicrophone,
              ),

            // Bouton retourner caméra (host seulement)
            if (widget.isHost)
              _buildControlButton(
                icon: Icons.flip_camera_ios,
                color: Colors.white,
                onTap: _switchCamera,
              ),

            // Bouton inviter
            _buildControlButton(
              icon: Icons.share,
              color: Colors.white,
              onTap: widget.onInvite,
            ),

            // Bouton terminer le live (host seulement)
            if (widget.isHost)
              _buildControlButton(
                icon: Icons.call_end,
                color: Colors.red,
                onTap: widget.onEndLive,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  void _toggleCamera() {
    setState(() {
      _isCameraOn = !_isCameraOn;
    });
    // Utiliser l'API ZegoUIKit pour contrôler la caméra
    ZegoUIKit().turnCameraOn(!_isCameraOn);
  }

  void _toggleMicrophone() {
    setState(() {
      _isMicrophoneOn = !_isMicrophoneOn;
    });
    // Utiliser l'API ZegoUIKit pour contrôler le microphone
    ZegoUIKit().turnMicrophoneOn(!_isMicrophoneOn);
  }

  void _switchCamera() {
    // Note: La méthode exacte peut varier selon la version de ZegoUIKit
    // Pour l'instant, on affiche juste un message
    debugPrint('Changement de caméra demandé');
  }
}
