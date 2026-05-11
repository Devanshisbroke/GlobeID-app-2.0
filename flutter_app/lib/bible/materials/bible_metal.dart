import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../bible_tokens.dart';

/// GlobeID — **Metal** material (§4.3).
///
/// Brushed-aluminium gradient with an anisotropic highlight. Used for
/// chip indicators, kiosk frames, embossed seals.
///
/// Unlike `BibleFoil`, metal renders a *static* directional brushed
/// pattern (no gyro tracking by default). Metal is more honest than
/// foil — it lives at the rim, not on the hero.
class BibleMetal extends StatelessWidget {
  const BibleMetal({
    super.key,
    required this.child,
    this.radius = B.rTile,
    this.padding = const EdgeInsets.all(B.space3),
    this.tone = const Color(0xFFB6BAC0),
    this.lightAngleDeg = 60,
    this.brushDensity = 16,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;

  /// Base metal tone — silver, brass, gun-metal.
  final Color tone;

  /// Light source angle in degrees.
  final double lightAngleDeg;

  /// Number of brushed-streak passes.
  final int brushDensity;

  @override
  Widget build(BuildContext context) {
    final radii = BorderRadius.circular(radius);
    final lightRad = lightAngleDeg * math.pi / 180.0;
    final highlight = Alignment(math.cos(lightRad), -math.sin(lightRad));

    return ClipRRect(
      borderRadius: radii,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _shade(tone, -0.18),
                  tone,
                  _shade(tone, 0.10),
                  _shade(tone, -0.12),
                ],
                stops: const [0, 0.45, 0.6, 1],
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _BrushPainter(
                  density: brushDensity,
                  tone: tone,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: highlight,
                    radius: 0.9,
                    colors: [
                      Colors.white.withValues(alpha: 0.30),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: radii,
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.12),
                    width: 0.6,
                  ),
                ),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }

  Color _shade(Color base, double delta) {
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withLightness((hsl.lightness + delta).clamp(0.0, 1.0))
        .toColor();
  }
}

class _BrushPainter extends CustomPainter {
  _BrushPainter({required this.density, required this.tone});
  final int density;
  final Color tone;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;
    final step = size.height / density;
    for (var i = 0; i < density; i++) {
      final y = i * step + (i % 2 == 0 ? 0 : step * 0.18);
      final alpha = 0.04 + ((i * 13) % 17) / 17.0 * 0.05;
      paint
        ..strokeWidth = 0.5
        ..color = Colors.white.withValues(alpha: alpha);
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 0.2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BrushPainter old) =>
      old.density != density || old.tone != tone;
}
