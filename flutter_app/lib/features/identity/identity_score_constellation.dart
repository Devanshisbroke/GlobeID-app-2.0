import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/sensor_fusion.dart';
import '../../widgets/premium/premium.dart';

/// Constellation visualization for an identity score.
///
/// Renders [score]/100 as a ring of orbiting "stars" — each star is
/// a deterministic point on a slow orbit; the central halo grows
/// brighter with the score; mascot symbols render the tier's emblem
/// in the centre. Sensor fusion is used to drift the constellation
/// off-axis so it has a tactile feel.
class IdentityScoreConstellation extends StatefulWidget {
  const IdentityScoreConstellation({
    super.key,
    required this.score,
    required this.tier,
    this.size = 220,
  });
  final int score;
  final String tier;
  final double size;

  @override
  State<IdentityScoreConstellation> createState() =>
      _IdentityScoreConstellationState();
}

class _IdentityScoreConstellationState
    extends State<IdentityScoreConstellation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 36),
  )..repeat();

  @override
  void initState() {
    super.initState();
    SensorFusion.instance.acquire();
  }

  @override
  void dispose() {
    _ticker.dispose();
    SensorFusion.instance.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduce = MediaQuery.of(context).disableAnimations;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ticker,
        builder: (_, __) {
          final sf = SensorFusion.instance;
          final tx = reduce ? 0.0 : sf.tiltY * 14;
          final ty = reduce ? 0.0 : sf.tiltX * 14;
          return Transform.translate(
            offset: Offset(tx, ty),
            child: CustomPaint(
              painter: _ConstellationPainter(
                progress: reduce ? 0 : _ticker.value,
                score: widget.score / 100,
                tone: theme.colorScheme.primary,
                glow: theme.colorScheme.secondary,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.score.toString(),
                      style: AirportFontStack.board(context, size: 52)
                          .copyWith(color: Colors.white),
                    ),
                    Text(
                      widget.tier.toUpperCase(),
                      style: AirportFontStack.gate(context, size: 11)
                          .copyWith(
                              color: Colors.white.withValues(alpha: 0.65),
                              letterSpacing: 4),
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
}

class _ConstellationPainter extends CustomPainter {
  _ConstellationPainter({
    required this.progress,
    required this.score,
    required this.tone,
    required this.glow,
  });
  final double progress;
  final double score;
  final Color tone;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 6;
    // Outer ring
    final track = Paint()
      ..color = tone.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(c, r * 0.92, track);
    // Filled arc representing score
    final arc = Paint()
      ..shader = SweepGradient(
        colors: [glow, tone, glow],
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + 2 * math.pi,
      ).createShader(Rect.fromCircle(center: c, radius: r * 0.92))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.92),
      -math.pi / 2,
      2 * math.pi * score,
      false,
      arc,
    );

    // Halo
    final halo = Paint()
      ..shader = RadialGradient(
        colors: [
          tone.withValues(alpha: 0.20 + 0.20 * score),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, halo);

    // Constellation stars
    const starCount = 48;
    for (var i = 0; i < starCount; i++) {
      final theta = (i / starCount) * 2 * math.pi + progress * 2 * math.pi;
      final radius =
          r * (0.5 + 0.4 * ((i * 137) % 100) / 100); // deterministic-ish
      final x = c.dx + math.cos(theta) * radius;
      final y = c.dy + math.sin(theta) * radius;
      final t = (i / starCount + progress) % 1;
      final alpha = (0.25 + 0.65 * (1 - (t - 0.5).abs() * 2)).clamp(0.0, 1.0);
      final size = 1.4 + (1.4 * alpha);
      final paint = Paint()
        ..color = (i % 4 == 0 ? glow : tone).withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), size, paint);
    }

    // Inner halo (deeper)
    final inner = Paint()
      ..shader = RadialGradient(
        colors: [
          glow.withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r * 0.42));
    canvas.drawCircle(c, r * 0.42, inner);
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter old) =>
      old.progress != progress ||
      old.score != score ||
      old.tone != tone ||
      old.glow != glow;
}
