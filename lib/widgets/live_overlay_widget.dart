import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/live.dart';
import '../models/user.dart';

class LiveOverlayWidget extends StatefulWidget {
  final String liveID;
  final String userID;
  final String hostID;
  final bool isHost;
  final VoidCallback? onEndLive;
  final VoidCallback? onInvite;

  const LiveOverlayWidget({
    super.key,
    required this.liveID,
    required this.userID,
    required this.hostID,
    required this.isHost,
    this.onEndLive,
    this.onInvite,
  });

  @override
  State<LiveOverlayWidget> createState() => _LiveOverlayWidgetState();
}

class _LiveOverlayWidgetState extends State<LiveOverlayWidget> {
  bool _isFollowing = false;
  User? _hostUser;
  Live? _liveData;
  int _viewerCount = 0;

  @override
  void initState() {
    super.initState();
    _loadHostData();
    _loadLiveData();
    _checkFollowStatus();
    _listenToViewerCount();
  }

  Future<void> _loadHostData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.hostID)
          .get();

      if (doc.exists) {
        setState(() {
          _hostUser = User.fromMap(doc.data()!);
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des données du host: $e');
    }
  }

  Future<void> _loadLiveData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('lives')
          .doc(widget.liveID)
          .get();

      if (doc.exists) {
        setState(() {
          _liveData = Live.fromMap(doc.data()!);
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des données du live: $e');
    }
  }

  Future<void> _checkFollowStatus() async {
    if (widget.isHost) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.hostID)
          .get();

      if (doc.exists) {
        final hostData = User.fromMap(doc.data()!);
        setState(() {
          _isFollowing = hostData.followers.contains(widget.userID);
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification du statut de suivi: $e');
    }
  }

  void _listenToViewerCount() {
    FirebaseFirestore.instance
        .collection('lives')
        .doc(widget.liveID)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && mounted) {
            final data = snapshot.data()!;
            setState(() {
              _viewerCount = data['stats']?['account'] ?? 0;
            });
          }
        });
  }

  Future<void> _toggleFollow() async {
    if (widget.isHost) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final hostRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.hostID);

      if (_isFollowing) {
        // Unfollow
        batch.update(hostRef, {
          'followers': FieldValue.arrayRemove([widget.userID]),
        });
      } else {
        // Follow
        batch.update(hostRef, {
          'followers': FieldValue.arrayUnion([widget.userID]),
        });
      }

      await batch.commit();

      setState(() {
        _isFollowing = !_isFollowing;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFollowing
                  ? 'Vous suivez maintenant ${_hostUser?.username}'
                  : 'Vous ne suivez plus ${_hostUser?.username}',
            ),
            backgroundColor: _isFollowing ? Colors.green : Colors.grey,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors du suivi/désuivi: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'action'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reportLive() async {
    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'live_id': widget.liveID,
        'reported_by': widget.userID,
        'reported_user': widget.hostID,
        'type': 'live',
        'reason': 'Contenu inapproprié',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Live signalé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors du signalement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du signalement'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareLive() async {
    try {
      final liveUrl = 'streamyz://live/${widget.liveID}';
      final hostName = _hostUser?.username ?? 'un streamer';
      await Share.share(
        'Rejoignez le live de $hostName sur Streamyz! 🔴\n$liveUrl',
        subject: 'Live en cours sur Streamyz',
      );
    } catch (e) {
      debugPrint('Erreur lors du partage: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du partage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showHostProfile() {
    if (_hostUser == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Profile info
            CircleAvatar(
              radius: 50,
              backgroundImage: _hostUser!.avatar.isNotEmpty
                  ? NetworkImage(_hostUser!.avatar)
                  : null,
              backgroundColor: Colors.grey[300],
              child: _hostUser!.avatar.isEmpty
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 16),

            Text(
              _hostUser!.username,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (_hostUser!.isPremium)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PREMIUM',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn('${_hostUser!.followers.length}', 'Followers'),
                _buildStatColumn('${_hostUser!.totalLiveGift}', 'Cadeaux'),
                _buildStatColumn('$_viewerCount', 'En live'),
              ],
            ),
            const SizedBox(height: 30),

            // Action buttons
            if (!widget.isHost) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _toggleFollow,
                      icon: Icon(
                        _isFollowing ? Icons.person_remove : Icons.person_add,
                      ),
                      label: Text(_isFollowing ? 'Ne plus suivre' : 'Suivre'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFollowing
                            ? Colors.grey
                            : Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _shareLive,
                      icon: const Icon(Icons.share),
                      label: const Text('Partager'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _shareLive,
                icon: const Icon(Icons.share),
                label: const Text('Partager mon live'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            if (widget.isHost) ...[
              ListTile(
                leading: const Icon(Icons.stop, color: Colors.red),
                title: const Text('Arrêter le live'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onEndLive?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add, color: Colors.blue),
                title: const Text('Inviter des amis'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onInvite?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.green),
                title: const Text('Partager le live'),
                onTap: () {
                  Navigator.pop(context);
                  _shareLive();
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.share, color: Colors.green),
                title: const Text('Partager ce live'),
                onTap: () {
                  Navigator.pop(context);
                  _shareLive();
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag, color: Colors.red),
                title: const Text('Signaler ce live'),
                onTap: () {
                  Navigator.pop(context);
                  _reportLive();
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.grey),
              title: const Text('Annuler'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Row(
        children: [
          // Profil du host
          GestureDetector(
            onTap: _showHostProfile,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: _hostUser?.avatar.isNotEmpty == true
                        ? NetworkImage(_hostUser!.avatar)
                        : null,
                    backgroundColor: Colors.grey[300],
                    child: _hostUser?.avatar.isEmpty != false
                        ? const Icon(
                            Icons.person,
                            size: 20,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _hostUser?.username ?? 'Host',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '$_viewerCount spectateurs',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (!widget.isHost) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _toggleFollow,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _isFollowing ? Colors.grey : Colors.blue,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          _isFollowing ? 'Suivi' : 'Suivre',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Spacer(),
          // Bouton de fermeture pour l'audience
          if (!widget.isHost) ...[
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Menu options
          GestureDetector(
            onTap: _showMoreOptions,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.more_vert, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
