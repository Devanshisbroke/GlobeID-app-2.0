import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme/app_tokens.dart';

/// Pulsing halo wrapped around [child]. Use to draw the eye to a
/// primary CTA or live indicator (e.g. "scanning", "live arc").
class GlowPulse extends StatefulWidget {
  const GlowPulse({
    super.key,
    required this.child,
    this.color,
    this.size = 1.0,
    this.duration = const Duration(milliseconds: 1700),
  });

  final Widget child;
  final Color? color;
  final double size;
  final Duration duration;

  @override
  State<GlowPulse> createState() => _GlowPulseState();
}

class _GlowPulseState extends State<GlowPulse>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) == true;
    final accent = widget.color ?? Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, c) {
        if (reduce) {
          return Stack(alignment: Alignment.center, children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.30),
                    blurRadius: 18 * widget.size,
                    spreadRadius: 4 * widget.size,
                  ),
                ],
              ),
              child: c,
            ),
          ]);
        }
        // Two staggered ripples behind child.
        return Stack(alignment: Alignment.center, children: [
          for (var i = 0; i < 2; i++) _ripple(accent, i),
          c!,
        ]);
      },
      child: widget.child,
    );
  }

  Widget _ripple(Color color, int i) {
    final offset = (i * 0.5);
    final v = ((_ctrl.value + offset) % 1.0);
    final scale = 1.0 + v * 0.9 * widget.size;
    final alpha = (1 - v).clamp(0.0, 1.0) * 0.32;
    return IgnorePointer(
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: alpha,
          child: Container(
            width: 56 * widget.size,
            height: 56 * widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

/// Live-feed dot indicator with a subtle pulse — used in HUDs.
class LiveDot extends StatefulWidget {
  const LiveDot({super.key, this.color, this.size = 8});
  final Color? color;
  final double size;

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: AppTokens.duration2xl,
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
        final v = math.sin(_ctrl.value * 2 * math.pi).abs();
        return SizedBox(
          width: widget.size * 2,
          height: widget.size * 2,
          child: Stack(alignment: Alignment.center, children: [
            Opacity(
              opacity: v * 0.35,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                ),
              ),
            ),
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent,
                boxShadow: [
                  BoxShadow(
                      color: accent.withValues(alpha: 0.7), blurRadius: 6),
                ],
              ),
            ),
          ]),
        );
      },
    );
  }
}
