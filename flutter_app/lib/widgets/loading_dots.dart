import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Three-dot loading affordance with staggered bob animation. Used
/// in hero loading states where a CircularProgressIndicator would
/// feel too utilitarian.
class LoadingDots extends StatefulWidget {
  const LoadingDots({
    super.key,
    this.color,
    this.size = 8,
    this.gap = 6,
  });

  final Color? color;
  final double size;
  final double gap;

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.color ?? Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              _dot(accent, i),
              if (i < 2) SizedBox(width: widget.gap),
            ],
          ],
        );
      },
    );
  }

  Widget _dot(Color color, int i) {
    final phase = (_ctrl.value + i * 0.18) % 1.0;
    final wave = math.sin(phase * 2 * math.pi);
    final t = (wave + 1) / 2; // 0..1
    return Transform.translate(
      offset: Offset(0, -t * widget.size * 0.6),
      child: Opacity(
        opacity: 0.55 + t * 0.45,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
