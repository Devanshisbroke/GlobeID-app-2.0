import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../bible_tokens.dart';

/// GlobeID — **Paper** material (§4.3).
///
/// Vellum-bone or snowfield-white surface for boarding passes,
/// receipts, journal pages, and recap cards. Paper absorbs light — it
/// has NO blur, a *very* subtle drop shadow, and a procedural grain
/// noise overlay so the surface reads as fibre.
///
/// Paper never tints behind it (unlike glass). It is opaque.
class BiblePaper extends StatelessWidget {
  const BiblePaper({
    super.key,
    required this.child,
    this.radius = B.rCard,
    this.padding = const EdgeInsets.all(B.space5),
    this.substrate = B.snowfieldWhite,
    this.grainIntensity = 0.06,
    this.lightAngleDeg = 30,
    this.elevation = 1.0,
  });

  /// Subject placed on the paper.
  final Widget child;

  /// Continuous-curve radius.
  final double radius;

  /// Inset between paper edge and subject.
  final EdgeInsets padding;

  /// Paper substrate colour. Use `B.vellumBone` for diplomatic /
  /// premium documents and `B.snowfieldWhite` for utility documents.
  final Color substrate;

  /// Procedural grain intensity (0..0.15 typical).
  final double grainIntensity;

  /// Light source angle (degrees) — controls drop shadow direction
  /// and the gentle gradient bias on the paper.
  final double lightAngleDeg;

  /// Drop shadow strength multiplier (0..2).
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final radii = BorderRadius.circular(radius);
    final lightRad = lightAngleDeg * math.pi / 180.0;
    final shadowOff = Offset(
      -math.cos(lightRad) * 4 * elevation,
      math.sin(lightRad) * 6 * elevation,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radii,
        boxShadow: [
          BoxShadow(
            color: const Color(0x33000000).withValues(
              alpha: 0.10 * elevation.clamp(0.0, 2.0),
            ),
            blurRadius: 18 * elevation.clamp(0.5, 2.0),
            spreadRadius: 0,
            offset: shadowOff,
          ),
          BoxShadow(
            color: const Color(0x11000000),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radii,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Base substrate.
            ColoredBox(color: substrate),
            // Subtle warm-cool gradient bias driven by light angle.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(
                        -math.cos(lightRad),
                        -math.sin(lightRad),
                      ),
                      end: Alignment(
                        math.cos(lightRad),
                        math.sin(lightRad),
                      ),
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.04),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Procedural grain.
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _GrainPainter(intensity: grainIntensity),
                ),
              ),
            ),
            // Hairline border.
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: radii,
                    border: Border.all(
                      color: B.hairlineDarkSoft,
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            // Subject.
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter({required this.intensity});
  final double intensity;
  static const int _grains = 360;

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0) return;
    // Deterministic pseudo-random grain (seeded by index, not time).
    final paint = Paint();
    for (var i = 0; i < _grains; i++) {
      final px = ((i * 9301 + 49297) % 233280) / 233280.0 * size.width;
      final py = ((i * 4096 + 7919) % 233280) / 233280.0 * size.height;
      final alpha = (((i * 7) % 100) / 100.0) * intensity;
      paint.color = Colors.black.withValues(alpha: alpha * 0.5);
      canvas.drawCircle(Offset(px, py), 0.45, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GrainPainter old) =>
      old.intensity != intensity;
}
