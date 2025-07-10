import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';

import '../../models/live_models.dart';
import '../../services/live_service.dart';
import '../../widgets/live_indicators.dart';
import '../../widgets/live_widgets.dart';
import 'live_stream.dart';

class ImmersiveLiveViewerPage extends StatefulWidget {
  final String hostId;
  final String hostName;
  final String liveID;
  final bool isActive;
  final Map<String, dynamic> userData;
  final VoidCallback? onDispose;

  const ImmersiveLiveViewerPage({
    super.key,
    required this.hostId,
    required this.hostName,
    required this.liveID,
    required this.isActive,
    required this.userData,
    this.onDispose,
  });

  @override
  State<ImmersiveLiveViewerPage> createState() =>
      _ImmersiveLiveViewerPageState();
}

class _ImmersiveLiveViewerPageState extends State<ImmersiveLiveViewerPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // Animations
  late AnimationController _heartController;
  late AnimationController _giftController;
  late AnimationController _uiController;

  // États et données
  List<Widget> _floatingHearts = [];
  List<Widget> _floatingGifts = [];
  Timer? _heartTimer;
  Timer? _giftTimer;
  String? _currentUserId;
  String? _currentUserName;

  // Streams
  StreamSubscription<QuerySnapshot>? _giftsSubscription;
  StreamSubscription<DocumentSnapshot>? _liveStatsSubscription;

  // Stats live
  int _totalViewers = 0;
  int _totalGifts = 0;

  @override
  bool get wantKeepAlive => widget.isActive;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _initializeAnimations();
    if (widget.isActive) {
      _startListeningToLive();
    }
  }

  void _initializeUser() {
    final user = FirebaseAuth.instance.currentUser;
    _currentUserId = user?.uid ?? '';
    _currentUserName = user?.displayName ?? user?.email ?? _currentUserId;
  }

  void _initializeAnimations() {
    _heartController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _giftController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _uiController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _uiController.forward();
  }

  void _startListeningToLive() {
    _listenToGifts();
    _listenToLiveStats();
  }

  void _stopListeningToLive() {
    _giftsSubscription?.cancel();
    _liveStatsSubscription?.cancel();
    _heartTimer?.cancel();
    _giftTimer?.cancel();
  }

  void _listenToGifts() {
    _giftsSubscription = FirebaseFirestore.instance
        .collection('gifts')
        .where('liveID', isEqualTo: widget.liveID)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final gift = Gift.fromFirestore(change.doc);
              _animateNewGift(gift);
            }
          }
        });
  }

  void _listenToLiveStats() {
    _liveStatsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.hostId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data() as Map<String, dynamic>;
            final liveStats = data['liveStats'] as Map<String, dynamic>? ?? {};

            setState(() {
              _totalViewers = liveStats['totalViewers'] ?? 0;
              _totalGifts = liveStats['totalGifts'] ?? 0;
            });
          }
        });
  }

  @override
  void didUpdateWidget(ImmersiveLiveViewerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _startListeningToLive();
      } else {
        _stopListeningToLive();
      }
    }
  }

  @override
  void dispose() {
    _stopListeningToLive();
    _heartController.dispose();
    _giftController.dispose();
    _uiController.dispose();
    widget.onDispose?.call();
    super.dispose();
  }

  Future<void> _sendGift(GiftType giftType) async {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      _showMessage('Connectez-vous pour envoyer des cadeaux');
      return;
    }

    try {
      final gift = Gift(
        id: '',
        senderId: _currentUserId!,
        senderName: _currentUserName ?? 'Anonyme',
        giftType: giftType.name,
        timestamp: DateTime.now(),
        hostId: widget.hostId,
      );

      // Enregistrer dans Firestore
      await FirebaseFirestore.instance
          .collection('gifts')
          .add(gift.toFirestore()..['liveID'] = widget.liveID);

      // Mettre à jour les stats du streamer
      await LiveService.updateLiveStats(widget.hostId, giftType.value);

      _showMessage('${giftType.displayName} envoyé ! 🎁');
      HapticFeedback.mediumImpact();
    } catch (e) {
      _showMessage('Erreur lors de l\'envoi du cadeau');
      debugPrint('Erreur envoi cadeau: $e');
    }
  }

  void _animateNewGift(Gift gift) {
    // Utiliser le nouveau widget d'animation amélioré
    final giftKey = UniqueKey();
    final giftWidget = EnhancedFloatingGiftWidget(
      key: giftKey,
      giftType: gift.giftType,
      onAnimationComplete: () {
        if (mounted) {
          setState(() {
            _floatingGifts.removeWhere((w) => w.key == giftKey);
          });
        }
      },
    );

    setState(() {
      _floatingGifts.add(giftWidget);
    });

    // Animation de vibration pour un feedback tactile
    HapticFeedback.mediumImpact();
  }

  void _addFloatingHeart() {
    final heartWidget = _buildFloatingHeart();
    setState(() {
      _floatingHearts.add(heartWidget);
    });

    // Animer le cœur
    _heartController.reset();
    _heartController.forward();

    // Auto-envoi du cadeau cœur
    _sendGift(GiftType.heart);

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _floatingHearts.removeWhere((w) => w.key == heartWidget.key);
        });
      }
    });
  }

  void _showGiftSelector() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildGiftSelector(),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!widget.isActive) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Streaming vidéo ZegoUIKit intégré
          _buildZegoLiveStream(),

          // Overlay avec interactions intégrées
          _buildLiveInteractions(),

          // Animations flottantes
          ..._floatingHearts,
          ..._floatingGifts,
        ],
      ),
    );
  }

  Widget _buildZegoLiveStream() {
    return ZegoUIKitPrebuiltLiveStreaming(
      appID: appID,
      appSign: appSign,
      userID: _currentUserId ?? 'anonymous',
      userName: _currentUserName ?? 'Viewer',
      liveID: widget.liveID,
      config: ZegoUIKitPrebuiltLiveStreamingConfig.audience()
        // Configuration pour intégration native
        ..audioVideoView.showAvatarInAudioMode = false
        ..audioVideoView.showSoundWavesInAudioMode = false
        ..audioVideoView.useVideoViewAspectFill = true
        // Masquer les éléments UI par défaut
        ..bottomMenuBar.audienceButtons = []
        ..bottomMenuBar.hostButtons = []
        ..bottomMenuBar.maxCount = 0
        // Configuration pour performances optimales
        ..audioVideoView.backgroundBuilder = (context, size, user, streamList) {
          return Container(
            width: size.width,
            height: size.height,
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        },
    );
  }

  Widget _buildLiveInteractions() {
    return AnimatedBuilder(
      animation: _uiController,
      builder: (context, child) {
        return Opacity(
          opacity: _uiController.value,
          child: SafeArea(
            child: Column(
              children: [
                // Header avec infos du streamer
                _buildStreamHeader(),

                const Spacer(),

                // Section d'interaction en bas
                _buildInteractionSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStreamHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.4),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar du streamer avec indicateur de statut
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: widget.userData['avatarUrl'] != null
                    ? NetworkImage(widget.userData['avatarUrl'])
                    : null,
                backgroundColor: Colors.deepPurple,
                child: widget.userData['avatarUrl'] == null
                    ? Text(
                        widget.hostName.isNotEmpty
                            ? widget.hostName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // Infos du streamer
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
                    const LiveStreamingBadge(status: 'LIVE'),
                  ],
                ),

                const SizedBox(height: 6),

                // Stats live avec indicateurs visuels
                Row(
                  children: [
                    LiveConnectionIndicator(isConnected: true),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.visibility,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$_totalViewers',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.card_giftcard,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$_totalGifts',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Flux des derniers cadeaux
          Expanded(child: _buildRecentGiftsDisplay()),

          const SizedBox(width: 16),

          // Boutons d'interaction
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bouton cœur
              _buildHeartButton(),

              const SizedBox(height: 12),

              // Bouton cadeau
              _buildGiftButton(),

              const SizedBox(height: 12),

              // Bouton partage
              _buildShareButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentGiftsDisplay() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('gifts')
          .where('liveID', isEqualTo: widget.liveID)
          .orderBy('timestamp', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final gifts = snapshot.data!.docs
            .map((doc) => Gift.fromFirestore(doc))
            .toList();

        return Container(
          height: 120,
          child: ListView.builder(
            reverse: true,
            itemCount: gifts.length,
            itemBuilder: (context, index) {
              final gift = gifts[index];
              return _buildGiftMessage(gift);
            },
          ),
        );
      },
    );
  }

  Widget _buildGiftMessage(Gift gift) {
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
        icon = Icons.card_giftcard;
        color = Colors.purple;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${gift.senderName} a envoyé ${_getGiftDisplayName(gift.giftType)}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getGiftDisplayName(String giftType) {
    switch (giftType) {
      case 'heart':
        return 'un cœur';
      case 'star':
        return 'une étoile';
      case 'diamond':
        return 'un diamant';
      default:
        return 'un cadeau';
    }
  }

  Widget _buildHeartButton() {
    return GestureDetector(
      onTap: () {
        _addFloatingHeart();
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.red, Colors.pink],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 3,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.purple, Colors.deepPurple, Colors.indigo],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ],
        ),
        child: const Icon(Icons.card_giftcard, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildShareButton() {
    return GestureDetector(
      onTap: () {
        // Fonction de partage
        HapticFeedback.lightImpact();
        _showMessage('Partagez ce live avec vos amis ! 🎥');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.cyan],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ],
        ),
        child: const Icon(Icons.share, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildGiftSelector() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f1419)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // Handle indicator
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Barre de titre
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.card_giftcard, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Envoyer un cadeau',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Montrez votre appréciation au streamer !',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Grille des cadeaux
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildGiftOption(
                    GiftType.heart,
                    Icons.favorite,
                    Colors.red,
                    '1 pt',
                    'Gratuit',
                  ),
                  _buildGiftOption(
                    GiftType.star,
                    Icons.star,
                    Colors.amber,
                    '5 pts',
                    'Populaire',
                  ),
                  _buildGiftOption(
                    GiftType.diamond,
                    Icons.diamond,
                    Colors.cyan,
                    '10 pts',
                    'Premium',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGiftOption(
    GiftType giftType,
    IconData icon,
    Color color,
    String points,
    String label,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _sendGift(giftType);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 8),
            Text(
              giftType.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              points,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: color.withOpacity(0.8), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingHeart() {
    final random = Random();
    final startX =
        MediaQuery.of(context).size.width * 0.8 + random.nextDouble() * 40;

    return Positioned(
      key: UniqueKey(),
      left: startX,
      bottom: 200,
      child: AnimatedBuilder(
        animation: _heartController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              sin(_heartController.value * 2 * pi) * 30,
              -_heartController.value * 200,
            ),
            child: Transform.scale(
              scale: 1.0 - _heartController.value * 0.5,
              child: Opacity(
                opacity: 1.0 - _heartController.value,
                child: Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 30 + random.nextDouble() * 20,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
