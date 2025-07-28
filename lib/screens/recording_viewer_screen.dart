import 'dart:io';

import 'package:flutter/material.dart';

class RecordingViewerScreen extends StatefulWidget {
  final Map<String, dynamic> liveData;

  const RecordingViewerScreen({super.key, required this.liveData});

  @override
  State<RecordingViewerScreen> createState() => _RecordingViewerScreenState();
}

class _RecordingViewerScreenState extends State<RecordingViewerScreen> {
  bool _isLoading = true;
  String? _localContent;

  @override
  void initState() {
    super.initState();
    _loadRecordingContent();
  }

  Future<void> _loadRecordingContent() async {
    try {
      final localPath = widget.liveData['local_recording_path'] ?? '';

      if (localPath.isNotEmpty) {
        final file = File(localPath);
        if (await file.exists()) {
          final content = await file.readAsString();
          setState(() {
            _localContent = content;
            _isLoading = false;
          });
          return;
        }
      }

      // Si pas de fichier local, afficher les informations directement
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement contenu: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(int timestamp) {
    if (timestamp == 0) return 'Non disponible';
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} à ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int startTime, int endTime) {
    if (startTime == 0 || endTime == 0) return 'Durée inconnue';
    final duration = Duration(milliseconds: endTime - startTime);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}min';
    } else {
      return '${duration.inMinutes}min ${duration.inSeconds.remainder(60)}s';
    }
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.liveData['desc'] ?? 'Live enregistré';
    final hostName = widget.liveData['name_host'] ?? 'Host inconnu';
    final hostAvatar = widget.liveData['avatar_host'] ?? '';
    final thumbnail = widget.liveData['thumbnail'] ?? '';
    final startTime = widget.liveData['livestarttime'] ?? 0;
    final endTime = widget.liveData['liveendtime'] ?? 0;
    final stats = widget.liveData['stats'] ?? {};
    final viewers = stats['account'] ?? 0;
    final likes = stats['likes'] ?? 0;
    final gifts = widget.liveData['totalgift'] ?? 0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header avec bouton retour
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Recap du Live',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Partager le live
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Fonctionnalité de partage bientôt disponible',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.share, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Contenu principal
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Chargement du recap...'),
                            ],
                          ),
                        )
                      : _buildRecapContent(
                          title,
                          hostName,
                          hostAvatar,
                          thumbnail,
                          startTime,
                          endTime,
                          viewers,
                          likes,
                          gifts,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecapContent(
    String title,
    String hostName,
    String hostAvatar,
    String thumbnail,
    int startTime,
    int endTime,
    int viewers,
    int likes,
    int gifts,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header du live
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar du host
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: ClipOval(
                        child: hostAvatar.isNotEmpty
                            ? Image.network(
                                hostAvatar,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: Colors.white,
                                      child: const Icon(Icons.person, size: 30),
                                    ),
                              )
                            : Container(
                                color: Colors.white,
                                child: const Icon(Icons.person, size: 30),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hostName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Créateur',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '✅ Live terminé',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Statistiques
          const Text(
            '📊 Statistiques du live',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.visibility,
                  value: _formatCount(viewers),
                  label: 'Spectateurs max',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.favorite,
                  value: _formatCount(likes),
                  label: 'Likes totaux',
                  color: Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.card_giftcard,
                  value: _formatCount(gifts),
                  label: 'Cadeaux reçus',
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.schedule,
                  value: _formatDuration(startTime, endTime),
                  label: 'Durée',
                  color: Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Informations temporelles
          const Text(
            '🕒 Informations temporelles',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 16),

          _buildInfoCard(
            'Début du live',
            _formatDateTime(startTime),
            Icons.play_circle_filled,
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildInfoCard(
            'Fin du live',
            _formatDateTime(endTime),
            Icons.stop_circle,
            Colors.red,
          ),
          const SizedBox(height: 8),
          _buildInfoCard(
            'Pic d\'audience',
            '$viewers spectateurs simultanés',
            Icons.trending_up,
            Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildInfoCard(
            'Engagement total',
            '${likes + gifts} interactions',
            Icons.thumb_up,
            Colors.orange,
          ),

          const SizedBox(height: 32),

          // Bouton d'action principal
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('🎬 Moments forts'),
                    content: const Text(
                      'Cette fonctionnalité affichera bientôt les moments les plus intéressants de votre live basés sur les pics d\'engagement !\n\nPour l\'instant, ce recap contient toutes les statistiques importantes.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text(
                'Voir les moments forts',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Streamyz',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF667eea),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Recap généré automatiquement le ${_formatDateTime(DateTime.now().millisecondsSinceEpoch)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
