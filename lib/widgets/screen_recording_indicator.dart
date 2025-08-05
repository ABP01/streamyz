import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/screen_recording_service.dart';

/// Widget qui affiche l'indicateur d'enregistrement d'écran
class ScreenRecordingIndicator extends StatefulWidget {
  final String liveId;

  const ScreenRecordingIndicator({Key? key, required this.liveId})
    : super(key: key);

  @override
  State<ScreenRecordingIndicator> createState() =>
      _ScreenRecordingIndicatorState();
}

class _ScreenRecordingIndicatorState extends State<ScreenRecordingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  Timer? _updateTimer;
  bool _isRecording = false;
  String _statusText = '';
  Duration _recordingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();

    // Animation de pulsation pour l'indicateur REC
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Démarrer la surveillance du statut
    _startStatusMonitoring();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startStatusMonitoring() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateStatus();
      } else {
        timer.cancel();
      }
    });
  }

  void _updateStatus() {
    final isRecording = ScreenRecordingService.isRecording();
    final statusText = ScreenRecordingService.getRecordingStatusText();
    final duration =
        ScreenRecordingService.getCurrentRecordingDuration() ?? Duration.zero;

    setState(() {
      _isRecording = isRecording;
      _statusText = statusText;
      _recordingDuration = duration;
    });

    // Gérer l'animation de pulsation
    if (isRecording && !_animationController.isAnimating) {
      _animationController.repeat(reverse: true);
    } else if (!isRecording && _animationController.isAnimating) {
      _animationController.stop();
      _animationController.reset();
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRecording) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 50,
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
                  // Point rouge qui pulse
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Texte REC
                  const Text(
                    'REC',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Durée d'enregistrement
                  Text(
                    _formatDuration(_recordingDuration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
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

/// Widget de statut d'enregistrement plus discret pour l'overlay
class CompactRecordingStatus extends StatefulWidget {
  final String liveId;

  const CompactRecordingStatus({Key? key, required this.liveId})
    : super(key: key);

  @override
  State<CompactRecordingStatus> createState() => _CompactRecordingStatusState();
}

class _CompactRecordingStatusState extends State<CompactRecordingStatus> {
  Timer? _updateTimer;
  bool _isRecording = false;
  String _statusText = '';

  @override
  void initState() {
    super.initState();
    _startStatusMonitoring();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startStatusMonitoring() {
    _updateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _updateStatus();
      } else {
        timer.cancel();
      }
    });
  }

  void _updateStatus() {
    final isRecording = ScreenRecordingService.isRecording();
    final statusText = ScreenRecordingService.getRecordingStatusText();

    setState(() {
      _isRecording = isRecording;
      _statusText = statusText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _isRecording
            ? Colors.red.withOpacity(0.8)
            : Colors.grey.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isRecording
                ? Icons.fiber_manual_record
                : Icons.pause_circle_outline,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            _isRecording ? 'ÉCRAN' : 'ARRÊTÉ',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
