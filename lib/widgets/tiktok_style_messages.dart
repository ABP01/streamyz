import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/chat.dart';

class TikTokStyleMessages extends StatefulWidget {
  final String liveID;

  const TikTokStyleMessages({super.key, required this.liveID});

  @override
  State<TikTokStyleMessages> createState() => _TikTokStyleMessagesState();
}

class _TikTokStyleMessagesState extends State<TikTokStyleMessages>
    with TickerProviderStateMixin {
  final List<Widget> _floatingMessages = [];
  final List<Widget> _floatingLikes = [];
  final List<Widget> _floatingRoses = [];

  @override
  void initState() {
    super.initState();
    _listenToMessages();
    _listenToLikes();
    _listenToRoses();
  }

  void _listenToMessages() {
    FirebaseFirestore.instance
        .collection('chats')
        .where('live_id', isEqualTo: widget.liveID)
        .orderBy('time', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added && mounted) {
              final chat = Chat.fromMap(change.doc.data()!);
              _addFloatingMessage(chat);
            }
          }
        });
  }

  void _listenToLikes() {
    FirebaseFirestore.instance
        .collection('lives')
        .doc(widget.liveID)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && mounted) {
            final data = snapshot.data()!;
            final currentLikes = data['stats']?['likes'] ?? 0;

            // Déclencher animation si nouveaux likes
            if (currentLikes > 0) {
              _addFloatingLike();
            }
          }
        });
  }

  void _listenToRoses() {
    FirebaseFirestore.instance
        .collection('lives')
        .doc(widget.liveID)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && mounted) {
            final data = snapshot.data()!;
            final gifters = data['stats']?['gifters'] as List<dynamic>? ?? [];

            // Déclencher animation si nouveaux cadeaux
            if (gifters.isNotEmpty) {
              _addFloatingRose();
            }
          }
        });
  }

  void _addFloatingMessage(Chat chat) {
    final random = Random();
    final startX = random.nextDouble() * 200 + 20; // Position X aléatoire

    final messageWidget = TikTokFloatingMessage(
      chat: chat,
      startX: startX,
      onAnimationComplete: () {
        if (mounted) {
          setState(() {
            _floatingMessages.removeWhere(
              (element) => element is TikTokFloatingMessage,
            );
          });
        }
      },
    );

    setState(() {
      _floatingMessages.add(messageWidget);
    });

    // Retirer automatiquement après 8 secondes
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          _floatingMessages.remove(messageWidget);
        });
      }
    });
  }

  void _addFloatingLike() {
    final random = Random();
    final startX = random.nextDouble() * 100 + 20;

    final likeWidget = TikTokFloatingReaction(
      icon: Icons.favorite,
      color: Colors.red,
      startX: startX,
      onAnimationComplete: () {
        if (mounted) {
          setState(() {
            _floatingLikes.removeWhere(
              (element) => element is TikTokFloatingReaction,
            );
          });
        }
      },
    );

    setState(() {
      _floatingLikes.add(likeWidget);
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _floatingLikes.remove(likeWidget);
        });
      }
    });
  }

  void _addFloatingRose() {
    final random = Random();
    final startX = random.nextDouble() * 100 + 20;

    final roseWidget = TikTokFloatingReaction(
      icon: Icons.local_florist,
      color: Colors.pink,
      startX: startX,
      size: 32,
      onAnimationComplete: () {
        if (mounted) {
          setState(() {
            _floatingRoses.removeWhere(
              (element) => element is TikTokFloatingReaction,
            );
          });
        }
      },
    );

    setState(() {
      _floatingRoses.add(roseWidget);
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _floatingRoses.remove(roseWidget);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Messages flottants (côté gauche)
        ..._floatingMessages,

        // Likes flottants (côté droit)
        ..._floatingLikes,

        // Roses flottantes (côté droit)
        ..._floatingRoses,
      ],
    );
  }
}

class TikTokFloatingMessage extends StatefulWidget {
  final Chat chat;
  final double startX;
  final VoidCallback onAnimationComplete;

  const TikTokFloatingMessage({
    super.key,
    required this.chat,
    required this.startX,
    required this.onAnimationComplete,
  });

  @override
  State<TikTokFloatingMessage> createState() => _TikTokFloatingMessageState();
}

class _TikTokFloatingMessageState extends State<TikTokFloatingMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: -400.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.2)),
    );

    _controller.forward().then((_) {
      widget.onAnimationComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isHost = widget.chat.idUser == widget.chat.idHost;

    return Positioned(
      left: widget.startX,
      bottom: 200,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: isHost
                      ? Border.all(color: Colors.red, width: 1)
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isHost)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'HOST',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (isHost) const SizedBox(width: 6),
                    Flexible(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${widget.chat.idUser}: ',
                              style: TextStyle(
                                color: isHost ? Colors.red : Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            TextSpan(
                              text: widget.chat.message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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

class TikTokFloatingReaction extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double startX;
  final double size;
  final VoidCallback onAnimationComplete;

  const TikTokFloatingReaction({
    super.key,
    required this.icon,
    required this.color,
    required this.startX,
    this.size = 28,
    required this.onAnimationComplete,
  });

  @override
  State<TikTokFloatingReaction> createState() => _TikTokFloatingReactionState();
}

class _TikTokFloatingReactionState extends State<TikTokFloatingReaction>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: -350.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3)),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0)),
    );

    _controller.forward().then((_) {
      widget.onAnimationComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: widget.startX,
      bottom: 180,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              sin(_controller.value * 2 * pi) * 20, // Mouvement sinusoïdal
              _slideAnimation.value,
            ),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Icon(
                  widget.icon,
                  color: widget.color,
                  size: widget.size,
                  shadows: [
                    Shadow(
                      color: widget.color.withOpacity(0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
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
