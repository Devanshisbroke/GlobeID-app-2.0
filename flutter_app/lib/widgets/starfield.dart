import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A twinkling starfield — used behind the globe + onboarding canvases
/// to give an immediate "deep cinematic" read. Single ticker, pure
/// paint, deterministic seed so pattern stays consistent across
/// rebuilds and hot-reloads.
class Starfield extends StatefulWidget {
  const Starfield({
    super.key,
    this.density = 1.0,
    this.color = Colors.white,
    this.seed = 42,
  });

  /// 0..1+ — multiplier on default star count. Defaults to 1.
  final double density;
  final Color color;
  final int seed;

  @override
  State<Starfield> createState() => _StarfieldState();
}

class _StarfieldState extends State<Starfield>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    final r = math.Random(widget.seed);
    final count = (180 * widget.density).round();
    _stars = List.generate(count, (_) {
      return _Star(
        x: r.nextDouble(),
        y: r.nextDouble(),
        size: 0.4 + r.nextDouble() * 1.4,
        twinkleOffset: r.nextDouble(),
        twinkleSpeed: 0.6 + r.nextDouble() * 1.6,
        baseAlpha: 0.30 + r.nextDouble() * 0.55,
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) == true;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          size: Size.infinite,
          painter: _StarfieldPainter(
            t: reduce ? 0 : _ctrl.value,
            stars: _stars,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

class _Star {
  const _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.twinkleOffset,
    required this.twinkleSpeed,
    required this.baseAlpha,
  });
  final double x;
  final double y;
  final double size;
  final double twinkleOffset;
  final double twinkleSpeed;
  final double baseAlpha;
}

class _StarfieldPainter extends CustomPainter {
  _StarfieldPainter({
    required this.t,
    required this.stars,
    required this.color,
  });

  final double t;
  final List<_Star> stars;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (final s in stars) {
      final twinkle =
          (math.sin((t + s.twinkleOffset) * 2 * math.pi * s.twinkleSpeed) + 1) /
              2;
      final alpha = (s.baseAlpha * (0.45 + twinkle * 0.55)).clamp(0.0, 1.0);
      paint.color = color.withValues(alpha: alpha);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter old) =>
      old.t != t || old.stars != stars || old.color != color;
}
