import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// Aurora — slow, layered colour fields that drift across the
/// background. Sits *between* AtmosphereLayer and the page content
/// to add cinematic depth. Pure-paint, GPU friendly, single ticker.
class AuroraLayer extends StatefulWidget {
  const AuroraLayer({
    super.key,
    this.intensity = 1.0,
    this.colors,
  });

  /// 0..1 — how strong the aurora reads. Lower for brighter scaffolds.
  final double intensity;

  /// Optional colour set. Defaults to scheme.primary / .secondary mix.
  final List<Color>? colors;

  @override
  State<AuroraLayer> createState() => _AuroraLayerState();
}

class _AuroraLayerState extends State<AuroraLayer>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 36),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) == true;
    final palette = widget.colors ??
        [
          theme.colorScheme.primary,
          theme.colorScheme.secondary,
          theme.colorScheme.tertiary,
        ];

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          size: Size.infinite,
          painter: _AuroraPainter(
            t: reduce ? 0.0 : _ctrl.value,
            colors: palette,
            isDark: isDark,
            intensity: widget.intensity,
          ),
        ),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({
    required this.t,
    required this.colors,
    required this.isDark,
    required this.intensity,
  });

  final double t;
  final List<Color> colors;
  final bool isDark;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final base = isDark ? 0.16 : 0.08;
    final alpha = (base * intensity).clamp(0.0, 1.0);

    for (var i = 0; i < colors.length; i++) {
      final c = colors[i];
      final phase = t * 2 * math.pi + i * 1.3;
      final cx = w * (0.3 + 0.45 * math.sin(phase * 0.7));
      final cy = h * (0.25 + 0.35 * math.cos(phase * 0.5 + i));
      final radius = math.max(w, h) * (0.55 + 0.18 * math.sin(phase + i));

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            c.withValues(alpha: alpha),
            c.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius))
        ..blendMode = BlendMode.plus
        ..imageFilter = ImageFilter.blur(sigmaX: 60, sigmaY: 60);
      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) =>
      old.t != t ||
      old.intensity != intensity ||
      old.isDark != isDark ||
      old.colors != colors;
}
