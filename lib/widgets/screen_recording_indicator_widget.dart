import 'package:flutter/material.dart';

import '../utils/screen_recording_manager.dart';

class ScreenRecordingIndicatorWidget extends StatefulWidget {
  final String liveID;
  final bool isHost;

  const ScreenRecordingIndicatorWidget({
    super.key,
    required this.liveID,
    required this.isHost,
  });

  @override
  State<ScreenRecordingIndicatorWidget> createState() =>
      _ScreenRecordingIndicatorWidgetState();
}

class _ScreenRecordingIndicatorWidgetState
    extends State<ScreenRecordingIndicatorWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _checkRecordingStatus();
    _animationController.repeat(reverse: true);
  }

  void _checkRecordingStatus() {
    setState(() {
      _isRecording =
          ScreenRecordingManager.isRecording() &&
          ScreenRecordingManager.getCurrentRecordingLiveId() == widget.liveID;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRecording || !widget.isHost) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    ScreenRecordingManager.getRecordingStatusText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
