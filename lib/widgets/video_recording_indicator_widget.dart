import 'package:flutter/material.dart';

import '../utils/video_recording_manager.dart';

class VideoRecordingIndicatorWidget extends StatefulWidget {
  final String liveID;
  final bool isHost;

  const VideoRecordingIndicatorWidget({
    super.key,
    required this.liveID,
    required this.isHost,
  });

  @override
  State<VideoRecordingIndicatorWidget> createState() =>
      _VideoRecordingIndicatorWidgetState();
}

class _VideoRecordingIndicatorWidgetState
    extends State<VideoRecordingIndicatorWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  late Animation<Color?> _colorAnimation;

  bool _isRecording = false;
  int _recordingDuration = 0;

  @override
  void initState() {
    super.initState();

    // Animation de pulsation pour l'indicateur principal
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Animation d'onde pour l'effet de diffusion
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _waveController, curve: Curves.easeOut));

    _colorAnimation = ColorTween(
      begin: Colors.red,
      end: Colors.red.withOpacity(0.3),
    ).animate(_waveController);

    _checkRecordingStatus();

    // Démarrer les animations si enregistrement en cours
    if (_isRecording) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    _pulseController.repeat(reverse: true);
    _waveController.repeat();
  }

  void _stopAnimations() {
    _pulseController.stop();
    _waveController.stop();
  }

  void _checkRecordingStatus() {
    setState(() {
      _isRecording =
          VideoRecordingManager.isRecording() &&
          VideoRecordingManager.getCurrentRecordingLiveId() == widget.liveID;
      _recordingDuration = VideoRecordingManager.getRecordingDuration();
    });

    if (_isRecording) {
      _startAnimations();
    } else {
      _stopAnimations();
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
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
        animation: Listenable.merge([_pulseAnimation, _waveAnimation]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Onde de diffusion externe
              Transform.scale(
                scale: 1.0 + (_waveAnimation.value * 0.8),
                child: Container(
                  width: 80,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _colorAnimation.value,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              // Onde de diffusion intermédiaire
              Transform.scale(
                scale: 1.0 + (_waveAnimation.value * 0.4),
                child: Container(
                  width: 70,
                  height: 35,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(
                      0.4 * (1 - _waveAnimation.value),
                    ),
                    borderRadius: BorderRadius.circular(17.5),
                  ),
                ),
              ),

              // Indicateur principal avec pulsation
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF3B30), // Rouge vif
                        Color(0xFFFF6B6B), // Rouge plus doux
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Point rouge clignotant
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.6),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Texte REC
                      const Text(
                        'REC',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Durée
                      Text(
                        _formatDuration(_recordingDuration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Widget d'indicateur de statut d'enregistrement pour l'interface utilisateur
class RecordingStatusBadge extends StatelessWidget {
  final bool isRecording;
  final String statusText;
  final VoidCallback? onTap;

  const RecordingStatusBadge({
    super.key,
    required this.isRecording,
    required this.statusText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isRecording
              ? Colors.red.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isRecording ? Colors.red : Colors.grey,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isRecording ? Colors.red : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              statusText,
              style: TextStyle(
                color: isRecording ? Colors.red : Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget d'informations détaillées sur l'enregistrement
class RecordingInfoPanel extends StatelessWidget {
  final Map<String, dynamic> recordingStats;

  const RecordingInfoPanel({super.key, required this.recordingStats});

  @override
  Widget build(BuildContext context) {
    final isRecording = recordingStats['isRecording'] ?? false;
    final duration = recordingStats['duration'] ?? 0;
    final hasVideo = recordingStats['hasVideo'] ?? false;
    final hasAudio = recordingStats['hasAudio'] ?? false;
    final quality = recordingStats['quality'] ?? 'Unknown';
    final format = recordingStats['format'] ?? 'Unknown';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRecording ? Icons.videocam : Icons.videocam_off,
                color: isRecording ? Colors.red : Colors.grey,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                isRecording
                    ? 'Enregistrement en cours'
                    : 'Enregistrement arrêté',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isRecording ? Colors.red : Colors.grey.shade700,
                ),
              ),
            ],
          ),

          if (isRecording) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              'Durée',
              _formatDuration(duration),
              Icons.access_time,
            ),
            _buildInfoRow('Qualité', quality, Icons.high_quality),
            _buildInfoRow('Format', format, Icons.video_library),

            const SizedBox(height: 12),
            Row(
              children: [
                _buildFeatureBadge('Vidéo HD', hasVideo, Icons.videocam),
                const SizedBox(width: 8),
                _buildFeatureBadge('Audio sync', hasAudio, Icons.mic),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(String label, bool enabled, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: enabled
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? Colors.green : Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: enabled ? Colors.green : Colors.grey),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: enabled ? Colors.green : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
