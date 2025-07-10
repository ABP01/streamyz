import 'dart:math';

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
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Animation de mouvement en courbe
    _moveAnimation =
        Tween<Offset>(
          begin: const Offset(0.8, 1.0),
          end: Offset(-0.2 + Random().nextDouble() * 0.4, -0.5),
        ).animate(
          CurvedAnimation(parent: _moveController, curve: Curves.easeOutQuart),
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
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
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
        icon = Icons.favorite;
        color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 24),
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
        return SlideTransition(
          position: _moveAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
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
      height: 250,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1a1a1a), Color(0xFF2d2d2d)],
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

          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Choisir un cadeau',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildGiftOption(
                    'heart',
                    Icons.favorite,
                    Colors.red,
                    'Cœur',
                    '1 point',
                  ),
                  _buildGiftOption(
                    'star',
                    Icons.star,
                    Colors.amber,
                    'Étoile',
                    '5 points',
                  ),
                  _buildGiftOption(
                    'diamond',
                    Icons.diamond,
                    Colors.cyan,
                    'Diamant',
                    '10 points',
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
    String giftType,
    IconData icon,
    Color color,
    String label,
    String points,
  ) {
    return GestureDetector(
      onTap: () => onGiftSelected(giftType),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(points, style: TextStyle(color: Colors.white70, fontSize: 12)),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatItem(Icons.visibility, viewerCount.toString(), Colors.blue),
          const SizedBox(width: 16),
          _buildStatItem(
            Icons.card_giftcard,
            totalGifts.toString(),
            Colors.red,
          ),
          const SizedBox(width: 16),
          _buildStatItem(Icons.diamond, totalValue.toString(), Colors.amber),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
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
    _startX = _random.nextDouble() * 200 - 100; // Position X aléatoire

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _positionAnimation = Tween<double>(
      begin: 0.0,
      end: -400.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0)),
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(_controller);

    _controller.forward().then((_) {
      widget.onAnimationComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: MediaQuery.of(context).size.width / 2 + _startX,
      bottom: 100,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _positionAnimation.value),
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: const Icon(Icons.favorite, color: Colors.red, size: 25),
              ),
            ),
          );
        },
      ),
    );
  }
}

class EnhancedFloatingGiftWidget extends StatefulWidget {
  final String giftType;
  final VoidCallback onAnimationComplete;

  const EnhancedFloatingGiftWidget({
    super.key,
    required this.giftType,
    required this.onAnimationComplete,
  });

  @override
  State<EnhancedFloatingGiftWidget> createState() =>
      _EnhancedFloatingGiftWidgetState();
}

class _EnhancedFloatingGiftWidgetState extends State<EnhancedFloatingGiftWidget>
    with TickerProviderStateMixin {
  late AnimationController _moveController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<Offset> _moveAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _opacityAnimation;

  final Random _random = Random();
  late double _startX;
  late double _endX;

  @override
  void initState() {
    super.initState();

    // Positions aléatoires pour un effet naturel
    _startX = _random.nextDouble() * 100 - 50;
    _endX = _random.nextDouble() * 200 - 100;

    _moveController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Animation de mouvement en courbe avec effet de flottaison
    _moveAnimation =
        Tween<Offset>(
          begin: Offset(_startX, 0),
          end: Offset(_endX, -400),
        ).animate(
          CurvedAnimation(parent: _moveController, curve: Curves.easeOutCirc),
        );

    // Animation d'échelle avec rebond
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Animation de pulsation
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animation d'opacité avec fade out
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _moveController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    // Séquence d'animations
    _scaleController.forward();
    _pulseController.repeat(reverse: true);

    // Délai avant le mouvement pour l'effet de surprise
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _moveController.forward().then((_) {
          widget.onAnimationComplete();
        });
      }
    });
  }

  @override
  void dispose() {
    _moveController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildGiftIcon() {
    IconData icon;
    Color primaryColor;
    Color secondaryColor;

    switch (widget.giftType) {
      case 'heart':
        icon = Icons.favorite;
        primaryColor = Colors.red;
        secondaryColor = Colors.pink;
        break;
      case 'star':
        icon = Icons.star;
        primaryColor = Colors.amber;
        secondaryColor = Colors.yellow;
        break;
      case 'diamond':
        icon = Icons.diamond;
        primaryColor = Colors.cyan;
        secondaryColor = Colors.blue;
        break;
      default:
        icon = Icons.card_giftcard;
        primaryColor = Colors.purple;
        secondaryColor = Colors.deepPurple;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: RadialGradient(colors: [primaryColor, secondaryColor]),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.6),
            blurRadius: 20,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: secondaryColor.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _moveController,
        _scaleController,
        _pulseController,
      ]),
      builder: (context, child) {
        return Positioned(
          left: MediaQuery.of(context).size.width * 0.7,
          bottom: 150,
          child: Transform.translate(
            offset: _moveAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value * _pulseAnimation.value,
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: _buildGiftIcon(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class LiveViewerCountWidget extends StatefulWidget {
  final int viewerCount;

  const LiveViewerCountWidget({super.key, required this.viewerCount});

  @override
  State<LiveViewerCountWidget> createState() => _LiveViewerCountWidgetState();
}

class _LiveViewerCountWidgetState extends State<LiveViewerCountWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _previousCount = widget.viewerCount;
  }

  @override
  void didUpdateWidget(LiveViewerCountWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.viewerCount != _previousCount) {
      _controller.forward().then((_) => _controller.reverse());
      _previousCount = widget.viewerCount;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.red, Colors.pink]),
              borderRadius: BorderRadius.circular(15),
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
                const Icon(Icons.visibility, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  widget.viewerCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
