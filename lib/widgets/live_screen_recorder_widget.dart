import 'dart:async';

import 'package:flutter/material.dart';
import 'package:screen_recorder/screen_recorder.dart';

import '../utils/screen_recording_service.dart';

/// Widget d'enregistrement d'écran intégré dans l'interface du live
class LiveScreenRecorderWidget extends StatefulWidget {
  final String liveId;
  final Widget child;
  final bool autoStart;
  final VoidCallback? onRecordingStart;
  final VoidCallback? onRecordingStop;

  const LiveScreenRecorderWidget({
    Key? key,
    required this.liveId,
    required this.child,
    this.autoStart = false,
    this.onRecordingStart,
    this.onRecordingStop,
  }) : super(key: key);

  @override
  State<LiveScreenRecorderWidget> createState() =>
      _LiveScreenRecorderWidgetState();
}

class _LiveScreenRecorderWidgetState extends State<LiveScreenRecorderWidget> {
  final ScreenRecorderController _controller = ScreenRecorderController(
    pixelRatio: 1.0,
    skipFramesBetweenCaptures: 2,
  );

  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startRecording();
      });
    }
  }

  @override
  void dispose() {
    if (_isRecording) {
      _stopRecording();
    }
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;

    try {
      final success = await ScreenRecordingService.startScreenRecording(
        widget.liveId,
        GlobalKey(),
      );

      if (success) {
        setState(() {
          _isRecording = true;
        });
        widget.onRecordingStart?.call();

        // Démarrer l'enregistrement du widget
        _controller.start();
      }
    } catch (e) {
      debugPrint('Erreur démarrage enregistrement widget: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      // Arrêter l'enregistrement du widget
      _controller.stop();

      final success = await ScreenRecordingService.stopScreenRecording(
        widget.liveId,
      );

      if (success) {
        setState(() {
          _isRecording = false;
        });
        widget.onRecordingStop?.call();
      }
    } catch (e) {
      debugPrint('Erreur arrêt enregistrement widget: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenRecorder(
      controller: _controller,
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: [
          widget.child,
          // Indicateur d'enregistrement
          if (_isRecording)
            Positioned(
              top: 50,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
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
                    const SizedBox(width: 8),
                    const Text(
                      'REC',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Bouton de contrôle manuel (optionnel)
          if (!widget.autoStart)
            Positioned(
              top: 50,
              right: 20,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: _isRecording ? Colors.red : Colors.blue,
                onPressed: _isRecording ? _stopRecording : _startRecording,
                child: Icon(
                  _isRecording ? Icons.stop : Icons.fiber_manual_record,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget simple pour afficher le statut d'enregistrement
class RecordingStatusWidget extends StatefulWidget {
  final String liveId;

  const RecordingStatusWidget({Key? key, required this.liveId})
    : super(key: key);

  @override
  State<RecordingStatusWidget> createState() => _RecordingStatusWidgetState();
}

class _RecordingStatusWidgetState extends State<RecordingStatusWidget> {
  String _statusText = '';

  @override
  void initState() {
    super.initState();
    _updateStatus();

    // Mettre à jour le statut toutes les secondes
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateStatus();
      } else {
        timer.cancel();
      }
    });
  }

  void _updateStatus() {
    setState(() {
      _statusText = ScreenRecordingService.getRecordingStatusText();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = ScreenRecordingService.isRecording();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isRecording
            ? Colors.red.withOpacity(0.9)
            : Colors.grey.withOpacity(0.7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        _statusText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
