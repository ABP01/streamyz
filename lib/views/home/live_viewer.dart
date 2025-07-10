import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';

import '../../models/live_models.dart';
import '../../services/live_service.dart';
import '../../widgets/live_widgets.dart';
import 'live_stream.dart';

class LiveViewerPage extends StatefulWidget {
  final String hostId;
  final String hostName;
  final String liveID;
  final bool isActive;

  const LiveViewerPage({
    super.key,
    required this.hostId,
    required this.hostName,
    required this.liveID,
    required this.isActive,
  });

  @override
  State<LiveViewerPage> createState() => _LiveViewerPageState();
}

class _LiveViewerPageState extends State<LiveViewerPage>
    with TickerProviderStateMixin {
  late AnimationController _giftAnimationController;
  late AnimationController _heartController;
  List<Widget> _floatingGifts = [];
  List<Widget> _floatingHearts = [];

  @override
  void initState() {
    super.initState();
    _giftAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _giftAnimationController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  Future<void> _sendGift(GiftType giftType) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showMessage('Vous devez être connecté pour envoyer des cadeaux');
      return;
    }

    try {
      await LiveService.sendGift(widget.liveID, widget.hostId, giftType);
      _showGiftAnimation(giftType);
      _showMessage('Cadeau envoyé ! 🎁');
    } catch (e) {
      _showMessage('Erreur lors de l\'envoi du cadeau');
    }
  }

  void _showGiftAnimation(GiftType giftType) {
    final giftKey = UniqueKey();
    final giftWidget = FloatingGiftWidget(
      key: giftKey,
      giftType: giftType.name,
      onAnimationComplete: () {
        if (mounted) {
          setState(() {
            _floatingGifts.removeWhere((widget) => widget.key == giftKey);
          });
        }
      },
    );

    setState(() {
      _floatingGifts.add(giftWidget);
    });
  }

  void _addFloatingHeart() {
    final heartKey = UniqueKey();
    final heartWidget = FloatingHeartWidget(
      key: heartKey,
      onAnimationComplete: () {
        if (mounted) {
          setState(() {
            _floatingHearts.removeWhere((widget) => widget.key == heartKey);
          });
        }
      },
    );

    setState(() {
      _floatingHearts.add(heartWidget);
    });
  }

  void _showGiftSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GiftSelectorWidget(
        onGiftSelected: (giftType) {
          Navigator.pop(context);
          final giftEnum = GiftType.values.firstWhere(
            (type) => type.name == giftType,
            orElse: () => GiftType.heart,
          );
          _sendGift(giftEnum);
        },
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      // Affichage d'aperçu quand ce n'est pas la page active
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.live_tv, color: Colors.white54, size: 80),
              const SizedBox(height: 16),
              Text(
                widget.hostName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'EN DIRECT',
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
      );
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid ?? 'anonymous';
    final userName =
        currentUser?.displayName ?? currentUser?.email ?? 'Spectateur';

    return Scaffold(
      body: Stack(
        children: [
          // Streaming ZegoUIKit
          ZegoUIKitPrebuiltLiveStreaming(
            appID: appID,
            appSign: appSign,
            userID: userId,
            userName: userName,
            liveID: widget.liveID,
            config: ZegoUIKitPrebuiltLiveStreamingConfig.audience()
              ..bottomMenuBar.audienceButtons = []
              ..bottomMenuBar.hostButtons = []
              ..bottomMenuBar.maxCount = 0,
          ),

          // Overlay avec interactions
          if (widget.isActive) ...[
            // Infos streamer en haut
            Positioned(
              top: 60,
              left: 20,
              right: 20,
              child: _buildStreamerInfo(),
            ),
            // Feed cadeaux à droite
            Positioned(top: 120, right: 20, child: _buildGiftsFeed()),
            // Bouton cœur en bas à gauche
            Positioned(left: 20, bottom: 40, child: _buildHeartButton()),
            // Bouton cadeaux en bas à droite
            Positioned(right: 20, bottom: 40, child: _buildGiftButton()),
            // Cadeaux flottants
            ..._floatingGifts,
            ..._floatingHearts,
          ],
        ],
      ),
    );
  }

  Widget _buildStreamerInfo() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.hostId)
          .snapshots(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final liveStats = userData?['liveStats'] as Map<String, dynamic>? ?? {};
        final totalGifts = liveStats['totalGifts'] as int? ?? 0;
        final totalValue = liveStats['totalGiftValue'] as int? ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.red,
                child: Text(
                  widget.hostName.isNotEmpty
                      ? widget.hostName[0].toUpperCase()
                      : 'S',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.hostName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (totalGifts > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.card_giftcard,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$totalGifts cadeaux • $totalValue pts',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGiftsFeed() {
    return StreamBuilder<List<Gift>>(
      stream: LiveService.getGiftsStream(widget.liveID),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox();
        }

        final recentGifts = snapshot.data!.take(5).toList();
        return Container(
          constraints: const BoxConstraints(maxWidth: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: recentGifts.map((gift) => _buildGiftItem(gift)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildGiftItem(Gift gift) {
    IconData icon;
    Color color;

    switch (gift.giftType) {
      case 'heart':
        icon = Icons.favorite;
        color = Colors.red;
        break;
      case 'star':
        icon = Icons.star;
        color = Colors.amber;
        break;
      case 'diamond':
        icon = Icons.diamond;
        color = Colors.cyan;
        break;
      default:
        icon = Icons.favorite;
        color = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              gift.senderName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartButton() {
    return GestureDetector(
      onTap: () {
        _addFloatingHeart();
        _sendGift(GiftType.heart);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.favorite, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildGiftButton() {
    return GestureDetector(
      onTap: _showGiftSelector,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.purple, Colors.pink, Colors.red],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.card_giftcard, color: Colors.white, size: 28),
      ),
    );
  }
}
