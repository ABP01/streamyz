import 'package:flutter/material.dart';

class LiveConnectionIndicator extends StatefulWidget {
  final bool isConnected;
  final VoidCallback? onTap;

  const LiveConnectionIndicator({
    super.key,
    required this.isConnected,
    this.onTap,
  });

  @override
  State<LiveConnectionIndicator> createState() =>
      _LiveConnectionIndicatorState();
}

class _LiveConnectionIndicatorState extends State<LiveConnectionIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isConnected) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(LiveConnectionIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConnected != oldWidget.isConnected) {
      if (widget.isConnected) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: widget.isConnected ? Colors.green : Colors.red,
              shape: BoxShape.circle,
              boxShadow: widget.isConnected
                  ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.6),
                        blurRadius: 8 * _pulseAnimation.value,
                        spreadRadius: 2 * _pulseAnimation.value,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
            ),
          );
        },
      ),
    );
  }
}

class LiveQualityIndicator extends StatelessWidget {
  final int quality; // 1-5 (5 = excellent, 1 = poor)

  const LiveQualityIndicator({super.key, required this.quality});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isActive = index < quality;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          width: 3,
          height: 8 + (index * 2),
          decoration: BoxDecoration(
            color: isActive
                ? _getQualityColor(quality)
                : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  Color _getQualityColor(int quality) {
    if (quality >= 4) return Colors.green;
    if (quality >= 3) return Colors.orange;
    return Colors.red;
  }
}

class LiveStreamingBadge extends StatefulWidget {
  final String status; // 'LIVE', 'STARTING', 'ENDING'

  const LiveStreamingBadge({super.key, required this.status});

  @override
  State<LiveStreamingBadge> createState() => _LiveStreamingBadgeState();
}

class _LiveStreamingBadgeState extends State<LiveStreamingBadge>
    with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _blinkAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    if (widget.status == 'LIVE') {
      _blinkController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(LiveStreamingBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status != oldWidget.status) {
      if (widget.status == 'LIVE') {
        _blinkController.repeat(reverse: true);
      } else {
        _blinkController.stop();
        _blinkController.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    switch (widget.status) {
      case 'LIVE':
        return Colors.red;
      case 'STARTING':
        return Colors.orange;
      case 'ENDING':
        return Colors.grey;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _blinkAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(
              widget.status == 'LIVE' ? _blinkAnimation.value : 1.0,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: Text(
            widget.status,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}

class ViewerJoinAnimation extends StatefulWidget {
  final String username;
  final VoidCallback onComplete;

  const ViewerJoinAnimation({
    super.key,
    required this.username,
    required this.onComplete,
  });

  @override
  State<ViewerJoinAnimation> createState() => _ViewerJoinAnimationState();
}

class _ViewerJoinAnimationState extends State<ViewerJoinAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) => widget.onComplete());
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
        return Positioned(
          right: 16,
          top: 100,
          child: Transform.translate(
            offset: Offset(_slideAnimation.value * 300, 0),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.cyan],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_add, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.username} a rejoint',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SwipeIndicator extends StatefulWidget {
  final String direction; // 'up' or 'down'

  const SwipeIndicator({super.key, required this.direction});

  @override
  State<SwipeIndicator> createState() => _SwipeIndicatorState();
}

class _SwipeIndicatorState extends State<SwipeIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat();
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
        return Positioned(
          right: 8,
          top: MediaQuery.of(context).size.height * 0.5 - 40,
          child: Transform.translate(
            offset: Offset(
              0,
              widget.direction == 'up'
                  ? -_animation.value * 20
                  : _animation.value * 20,
            ),
            child: Opacity(
              opacity: 1.0 - _animation.value,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Icon(
                      widget.direction == 'up'
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 24,
                    ),
                    Icon(
                      widget.direction == 'up'
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.white.withOpacity(0.7),
                      size: 20,
                    ),
                    Icon(
                      widget.direction == 'up'
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.white.withOpacity(0.4),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
