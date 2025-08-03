import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Écran de visualisation des enregistrements vidéo avec video_player
class VideoRecordingViewerScreen extends StatefulWidget {
  final Map<String, dynamic> liveData;

  const VideoRecordingViewerScreen({super.key, required this.liveData});

  @override
  State<VideoRecordingViewerScreen> createState() =>
      _VideoRecordingViewerScreenState();
}

class _VideoRecordingViewerScreenState
    extends State<VideoRecordingViewerScreen> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      final recordingUrl = widget.liveData['recording_url'] as String?;

      if (recordingUrl == null || recordingUrl.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'URL d\'enregistrement non disponible';
          _isLoading = false;
        });
        return;
      }

      // Initialiser le lecteur vidéo avec l'URL de l'enregistrement
      _controller = VideoPlayerController.networkUrl(Uri.parse(recordingUrl));

      await _controller!.initialize();

      setState(() {
        _isLoading = false;
      });

      // Démarrer la lecture automatiquement
      _controller!.play();
    } catch (e) {
      debugPrint('❌ Erreur initialisation video player: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Erreur lors du chargement de la vidéo: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.liveData['title'] ?? 'Enregistrement',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_controller != null && !_isLoading && !_hasError)
            IconButton(
              icon: Icon(
                _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  if (_controller!.value.isPlaying) {
                    _controller!.pause();
                  } else {
                    _controller!.play();
                  }
                });
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Chargement de la vidéo...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Erreur inconnue',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                  _errorMessage = null;
                });
                _initializeVideoPlayer();
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: Text(
          'Vidéo non disponible',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Column(
      children: [
        // Lecteur vidéo principal
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),
        ),

        // Contrôles vidéo
        Container(
          color: Colors.black87,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Barre de progression
              VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.red,
                  bufferedColor: Colors.grey,
                  backgroundColor: Colors.black26,
                ),
              ),
              const SizedBox(height: 16),

              // Informations sur l'enregistrement
              _buildVideoInfo(),

              const SizedBox(height: 16),

              // Contrôles de lecture
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10, color: Colors.white),
                    onPressed: () {
                      final position = _controller!.value.position;
                      _controller!.seekTo(
                        Duration(
                          seconds: (position.inSeconds - 10).clamp(
                            0,
                            _controller!.value.duration.inSeconds,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: Icon(
                      _controller!.value.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: Colors.white,
                      size: 64,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_controller!.value.isPlaying) {
                          _controller!.pause();
                        } else {
                          _controller!.play();
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: const Icon(Icons.forward_10, color: Colors.white),
                    onPressed: () {
                      final position = _controller!.value.position;
                      _controller!.seekTo(
                        Duration(
                          seconds: (position.inSeconds + 10).clamp(
                            0,
                            _controller!.value.duration.inSeconds,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoInfo() {
    final title = widget.liveData['title'] ?? 'Live enregistré';
    final hostName = widget.liveData['host_name'] ?? 'Anonyme';
    final duration = _controller!.value.duration;
    final position = _controller!.value.position;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Par $hostName',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_formatDuration(position)} / ${_formatDuration(duration)}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Enregistrement d\'écran natif',
              style: const TextStyle(color: Colors.green, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }
}
