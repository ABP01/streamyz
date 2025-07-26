import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TapToLikeOverlay extends StatefulWidget {
  final String liveID;
  final String userID;
  final Widget child;

  const TapToLikeOverlay({
    super.key,
    required this.liveID,
    required this.userID,
    required this.child,
  });

  @override
  State<TapToLikeOverlay> createState() => _TapToLikeOverlayState();
}

class _TapToLikeOverlayState extends State<TapToLikeOverlay>
    with TickerProviderStateMixin {
  final List<Widget> _floatingHearts = [];
  DateTime? _lastTapTime;

  Future<void> _sendLike(Offset tapPosition) async {
    // Limiter la fréquence des likes (max 1 par seconde)
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds < 1000) {
      // Créer seulement l'animation sans envoyer à la base
      _addFloatingHeart(tapPosition);
      return;
    }

    _lastTapTime = now;

    try {
      // Mettre à jour les stats du live dans Firestore
      await FirebaseFirestore.instance
          .collection('lives')
          .doc(widget.liveID)
          .update({
            'stats.likes': FieldValue.increment(1),
            'stats.tab_likes': FieldValue.arrayUnion([widget.userID]),
          });

      // Mettre à jour la sous-collection livestats
      await FirebaseFirestore.instance
          .collection('lives')
          .doc(widget.liveID)
          .collection('livestats')
          .doc(widget.liveID)
          .update({
            'likes': FieldValue.increment(1),
            'tab_likes': FieldValue.arrayUnion([widget.userID]),
          });

      // Ajouter animation de cœur à la position du tap
      _addFloatingHeart(tapPosition);
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi du like: $e');
      // Même en cas d'erreur, montrer l'animation pour une meilleure UX
      _addFloatingHeart(tapPosition);
    }
  }

  void _addFloatingHeart(Offset position) {
    final random = Random();
    final heartWidget = FloatingHeart(
      startPosition: position,
      onAnimationComplete: () {
        if (mounted) {
          setState(() {
            _floatingHearts.removeWhere((heart) => heart is FloatingHeart);
          });
        }
      },
    );

    setState(() {
      _floatingHearts.add(heartWidget);
    });

    // Retirer automatiquement après l'animation
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _floatingHearts.remove(heartWidget);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        // Détecter le tap et envoyer un like
        _sendLike(details.localPosition);
      },
      child: Stack(
        children: [
          // Contenu principal
          widget.child,
          // Cœurs flottants
          ..._floatingHearts,
        ],
      ),
    );
  }
}

class FloatingHeart extends StatefulWidget {
  final Offset startPosition;
  final VoidCallback onAnimationComplete;

  const FloatingHeart({
    super.key,
    required this.startPosition,
    required this.onAnimationComplete,
  });

  @override
  State<FloatingHeart> createState() => _FloatingHeartState();
}

class _FloatingHeartState extends State<FloatingHeart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _moveAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late double _randomOffset;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    final random = Random();
    _randomOffset = (random.nextDouble() - 0.5) * 100; // -50 à +50 pixels

    _moveAnimation = Tween<double>(
      begin: 0,
      end: -200, // Monter de 200 pixels
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3)),
    );

    _controller.forward().then((_) => widget.onAnimationComplete());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.startPosition.dx + _randomOffset,
          top: widget.startPosition.dy + _moveAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: const Icon(Icons.favorite, color: Colors.red, size: 30),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
