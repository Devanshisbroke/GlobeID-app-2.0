import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Soft morphing blob — used as a backdrop element on hero panels.
/// Six harmonic ripples deform a circle to give a slow organic
/// breathing surface.
class AnimatedBlob extends StatefulWidget {
  const AnimatedBlob({
    super.key,
    required this.color,
    this.size = 220,
    this.speed = 1.0,
    this.blur = 36,
  });

  final Color color;
  final double size;
  final double speed;
  final double blur;

  @override
  State<AnimatedBlob> createState() => _AnimatedBlobState();
}

class _AnimatedBlobState extends State<AnimatedBlob>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (12000 / widget.speed).round()),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) == true;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _BlobPainter(
          t: reduce ? 0 : _ctrl.value,
          color: widget.color,
          blur: widget.blur,
        ),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter({required this.t, required this.color, required this.blur});
  final double t;
  final Color color;
  final double blur;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final base = math.min(size.width, size.height) / 2.4;
    final path = Path();
    const steps = 80;
    for (var i = 0; i <= steps; i++) {
      final theta = (i / steps) * 2 * math.pi;
      // 6 harmonic ripples to feel organic.
      final r = base +
          math.sin(theta * 3 + t * 2 * math.pi) * 12 +
          math.sin(theta * 5 - t * 2 * math.pi) * 8 +
          math.sin(theta * 2 + t * 4 * math.pi) * 6;
      final x = center.dx + r * math.cos(theta);
      final y = center.dy + r * math.sin(theta);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.55),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: base * 1.4))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BlobPainter old) =>
      old.t != t || old.color != color || old.blur != blur;
}
