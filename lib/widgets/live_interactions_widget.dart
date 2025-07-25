import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LiveInteractionsWidget extends StatefulWidget {
  final String liveID;
  final String userID;

  const LiveInteractionsWidget({
    super.key,
    required this.liveID,
    required this.userID,
  });

  @override
  State<LiveInteractionsWidget> createState() => _LiveInteractionsWidgetState();
}

class _LiveInteractionsWidgetState extends State<LiveInteractionsWidget>
    with TickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late AnimationController _roseAnimationController;
  final List<Widget> _floatingLikes = [];
  final List<Widget> _floatingRoses = [];

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _roseAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
  }

  Future<void> _sendLike() async {
    try {
      // Mettre à jour les stats du live
      await FirebaseFirestore.instance
          .collection('lives')
          .doc(widget.liveID)
          .update({
            'stats.likes': FieldValue.increment(1),
            'stats.tab_likes': FieldValue.arrayUnion([widget.userID]),
          });

      // Ajouter animation de like
      _addFloatingLike();
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi du like: $e');
    }
  }

  Future<void> _sendRose() async {
    try {
      // Mettre à jour les stats du live
      await FirebaseFirestore.instance
          .collection('lives')
          .doc(widget.liveID)
          .update({
            'stats.gifters': FieldValue.arrayUnion([
              {
                'user_id': widget.userID,
                'username': widget.userID,
                'user_avatar': '',
                'count': 1,
              },
            ]),
            'totalgift': FieldValue.increment(1),
          });

      // Ajouter animation de rose
      _addFloatingRose();
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi de la rose: $e');
    }
  }

  void _addFloatingLike() {
    final random = Random();
    final startX = random.nextDouble() * 100;

    final like = FloatingIcon(
      icon: Icons.favorite,
      color: Colors.red,
      startX: startX,
      onAnimationComplete: () {
        setState(() {
          _floatingLikes.removeWhere((element) => element is FloatingIcon);
        });
      },
    );

    setState(() {
      _floatingLikes.add(like);
    });

    // Retirer automatiquement après 3 secondes
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _floatingLikes.remove(like);
        });
      }
    });
  }

  void _addFloatingRose() {
    final random = Random();
    final startX = random.nextDouble() * 100;

    final rose = FloatingIcon(
      icon: Icons.local_florist,
      color: Colors.pink,
      startX: startX,
      onAnimationComplete: () {
        setState(() {
          _floatingRoses.removeWhere((element) => element is FloatingIcon);
        });
      },
    );

    setState(() {
      _floatingRoses.add(rose);
    });

    // Retirer automatiquement après 3 secondes
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _floatingRoses.remove(rose);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Likes flottants
        ..._floatingLikes,
        // Roses flottantes
        ..._floatingRoses,
        // Boutons d'interaction
        Positioned(
          right: 16,
          bottom: 120,
          child: Column(
            children: [
              // Bouton Like
              GestureDetector(
                onTap: _sendLike,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 28,
                  ),
                ),
              ),
              // Bouton Rose
              GestureDetector(
                onTap: _sendRose,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_florist,
                    color: Colors.pink,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _roseAnimationController.dispose();
    super.dispose();
  }
}

class FloatingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double startX;
  final VoidCallback onAnimationComplete;

  const FloatingIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.startX,
    required this.onAnimationComplete,
  });

  @override
  State<FloatingIcon> createState() => _FloatingIconState();
}

class _FloatingIconState extends State<FloatingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: -300.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0)),
    );

    _controller.forward().then((_) {
      widget.onAnimationComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: widget.startX,
      bottom: 200,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _animation.value),
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Icon(widget.icon, color: widget.color, size: 32),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
