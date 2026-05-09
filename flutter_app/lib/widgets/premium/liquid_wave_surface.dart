import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// Liquid wave fill — a poured-fluid animation used by multi-currency
/// conversion, wallet balance hero, and premium loading.
///
/// Renders two sine waves (slightly out of phase) over a tinted body.
/// The water level is driven by [progress] (0..1) and the waves
/// continuously oscillate via an internal ticker. Colour is derived
/// from the active accent / theme so it tints the right brand hue.
class LiquidWaveSurface extends StatefulWidget {
  const LiquidWaveSurface({
    super.key,
    this.progress = 1.0,
    this.tone,
    this.height = 120,
    this.duration = const Duration(milliseconds: 2400),
    this.amplitude = 6,
    this.radius = AppTokens.radius2xl,
    this.child,
  });

  final double progress;
  final Color? tone;
  final double height;
  final Duration duration;
  final double amplitude;
  final double radius;
  final Widget? child;

  @override
  State<LiquidWaveSurface> createState() => _LiquidWaveSurfaceState();
}

class _LiquidWaveSurfaceState extends State<LiquidWaveSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = widget.tone ?? theme.colorScheme.primary;
    final reduce = MediaQuery.of(context).disableAnimations;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _wave,
                builder: (_, __) {
                  return CustomPaint(
                    painter: _WavePainter(
                      progress: widget.progress.clamp(0.0, 1.0),
                      phase: reduce ? 0 : _wave.value * 2 * math.pi,
                      amplitude: reduce ? 0 : widget.amplitude,
                      tone: tone,
                    ),
                  );
                },
              ),
            ),
            if (widget.child != null) Positioned.fill(child: widget.child!),
          ],
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.progress,
    required this.phase,
    required this.amplitude,
    required this.tone,
  });
  final double progress;
  final double phase;
  final double amplitude;
  final Color tone;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final level = h - h * progress;
    // Base translucent body (so the surface remains visible empty).
    final body = Paint()..color = tone.withValues(alpha: 0.12);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), body);

    void paintWave(double phaseOffset, double alpha, double scale) {
      final path = Path()..moveTo(0, level);
      const segments = 32;
      for (var i = 0; i <= segments; i++) {
        final x = i / segments * w;
        final theta = (i / segments) * math.pi * 2 + phase + phaseOffset;
        final y = level + math.sin(theta) * amplitude * scale;
        path.lineTo(x, y);
      }
      path.lineTo(w, h);
      path.lineTo(0, h);
      path.close();
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            tone.withValues(alpha: alpha),
            tone.withValues(alpha: alpha * 0.5),
          ],
        ).createShader(Rect.fromLTWH(0, level, w, h - level));
      canvas.drawPath(path, paint);
    }

    paintWave(0, 0.45, 1.0);
    paintWave(math.pi / 2, 0.32, 0.7);
    paintWave(math.pi, 0.20, 1.2);

    // Top sheen line
    final sheen = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final p = Path()..moveTo(0, level - 1);
    const seg = 32;
    for (var i = 0; i <= seg; i++) {
      final x = i / seg * w;
      final theta = (i / seg) * math.pi * 2 + phase;
      final y = level + math.sin(theta) * amplitude;
      p.lineTo(x, y - 1);
    }
    canvas.drawPath(p, sheen);
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.progress != progress ||
      old.phase != phase ||
      old.amplitude != amplitude ||
      old.tone != tone;
}
