import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FloatingGiftWidget extends StatefulWidget {
  final String giftType;
  final VoidCallback onAnimationComplete;

  const FloatingGiftWidget({
    super.key,
    required this.giftType,
    required this.onAnimationComplete,
  });

  @override
  State<FloatingGiftWidget> createState() => _FloatingGiftWidgetState();
}

class _FloatingGiftWidgetState extends State<FloatingGiftWidget>
    with TickerProviderStateMixin {
  late AnimationController _moveController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late Animation<Offset> _moveAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _moveController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Animation de mouvement en courbe
    _moveAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0),
          end: const Offset(0, -1),
        ).animate(
          CurvedAnimation(parent: _moveController, curve: Curves.easeOutCubic),
        );

    // Animation d'échelle (apparition puis disparition)
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Animation de rotation
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    // Animation d'opacité
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _moveController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInCubic),
      ),
    );

    // Démarrer les animations
    _scaleController.forward();
    _moveController.forward();
    _rotationController.repeat();

    // Déclencher le callback quand l'animation est terminée
    _moveController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete();
      }
    });
  }

  @override
  void dispose() {
    _moveController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Widget _buildGiftIcon() {
    IconData icon;
    Color color;

    switch (widget.giftType) {
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _moveController,
        _scaleController,
        _rotationController,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            sin(_moveController.value * 4 * pi) * 50,
            _moveAnimation.value.dy * 300,
          ),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: _buildGiftIcon(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class GiftSelectorWidget extends StatelessWidget {
  final Function(String) onGiftSelected;

  const GiftSelectorWidget({super.key, required this.onGiftSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Envoyer un cadeau',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGiftOption('heart', Icons.favorite, Colors.red, '1'),
              _buildGiftOption('star', Icons.star, Colors.amber, '5'),
              _buildGiftOption('diamond', Icons.diamond, Colors.cyan, '10'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGiftOption(
    String giftType,
    IconData icon,
    Color color,
    String points,
  ) {
    return GestureDetector(
      onTap: () => onGiftSelected(giftType),
      child: Container(
        width: 80,
        height: 100,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              '$points pts',
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
  }
}

class LiveStatsWidget extends StatelessWidget {
  final int totalGifts;
  final int totalValue;
  final int viewerCount;

  const LiveStatsWidget({
    super.key,
    required this.totalGifts,
    required this.totalValue,
    required this.viewerCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatItem(
            Icons.visibility,
            viewerCount.toString(),
            Colors.white,
          ),
          const SizedBox(width: 12),
          _buildStatItem(
            Icons.card_giftcard,
            totalGifts.toString(),
            Colors.amber,
          ),
          const SizedBox(width: 12),
          _buildStatItem(Icons.diamond, totalValue.toString(), Colors.cyan),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class FloatingHeartWidget extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const FloatingHeartWidget({super.key, required this.onAnimationComplete});

  @override
  State<FloatingHeartWidget> createState() => _FloatingHeartWidgetState();
}

class _FloatingHeartWidgetState extends State<FloatingHeartWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;

  final Random _random = Random();
  late double _startX;

  @override
  void initState() {
    super.initState();

    _startX = _random.nextDouble() * 100;

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _positionAnimation = Tween<double>(
      begin: 0,
      end: -300,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.7, 1.0)),
    );

    _rotationAnimation = Tween<double>(
      begin: -0.5,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _startX + sin(_controller.value * 2 * pi) * 30,
            _positionAnimation.value,
          ),
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Icon(
                Icons.favorite,
                color: Colors.red,
                size: 20 + _random.nextDouble() * 15,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Widget pour les interactions en temps réel
class LiveInteractionOverlay extends StatefulWidget {
  final String liveID;
  final String hostId;
  final VoidCallback onHeartTap;
  final VoidCallback onGiftTap;

  const LiveInteractionOverlay({
    super.key,
    required this.liveID,
    required this.hostId,
    required this.onHeartTap,
    required this.onGiftTap,
  });

  @override
  State<LiveInteractionOverlay> createState() => _LiveInteractionOverlayState();
}

class _LiveInteractionOverlayState extends State<LiveInteractionOverlay> {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Stats du live en haut
              Row(
                children: [
                  Expanded(
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.hostId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();

                        final data =
                            snapshot.data!.data() as Map<String, dynamic>?;
                        final liveStats =
                            data?['liveStats'] as Map<String, dynamic>? ?? {};

                        return LiveStatsWidget(
                          totalGifts: liveStats['totalGifts'] ?? 0,
                          totalValue: liveStats['totalGiftValue'] ?? 0,
                          viewerCount: liveStats['totalViewers'] ?? 0,
                        );
                      },
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Boutons d'interaction en bas à droite
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildInteractionButton(
                        icon: Icons.favorite,
                        color: Colors.red,
                        onTap: widget.onHeartTap,
                      ),
                      const SizedBox(height: 12),
                      _buildInteractionButton(
                        icon: Icons.card_giftcard,
                        color: Colors.purple,
                        onTap: widget.onGiftTap,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
