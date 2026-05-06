import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/theme_prefs_provider.dart';

/// Cinematic atmosphere layer — a port of `src/cinematic/AtmosphereLayer.tsx`.
///
/// Renders three drifting blurred glow orbs, an animated diagonal ambient
/// ray, and a sparse floating-particle field. Fixed full-screen layer that
/// sits behind every screen so the background reads as alive and layered
/// rather than a flat colour wash.
///
/// Reduced effects: when [ThemePrefs.reduceTransparency] is on, OR the
/// user has system-level reduce-motion preferences, we render only two
/// static blurred orbs — same look, zero animation cost.
class AtmosphereLayer extends ConsumerStatefulWidget {
  const AtmosphereLayer({super.key});

  @override
  ConsumerState<AtmosphereLayer> createState() => _AtmosphereLayerState();
}

class _AtmosphereLayerState extends ConsumerState<AtmosphereLayer>
    with TickerProviderStateMixin {
  // Single long-running controller drives every animation — no React-style
  // per-particle timeline, just one ticker the GPU can pipeline.
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 30),
  )..repeat();

  static final List<_Particle> _particles = List.generate(
    18,
    (i) {
      final r = math.Random(i * 31 + 7);
      return _Particle(
        x: r.nextDouble(),
        y: r.nextDouble(),
        size: 2 + r.nextDouble() * 3,
        delay: r.nextDouble(),
        durationScale: 0.7 + r.nextDouble() * 1.3,
        opacity: 0.16 + r.nextDouble() * 0.22,
      );
    },
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    final reduce = ref.watch(themePrefsProvider).reduceTransparency ||
        MediaQuery.maybeDisableAnimationsOf(context) == true;

    if (reduce) {
      return _staticFallback(isDark, accent, secondary);
    }

    return IgnorePointer(
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final t = _ctrl.value; // 0..1 over 30s
              return CustomPaint(
                size: Size.infinite,
                painter: _AtmospherePainter(
                  t: t,
                  particles: _particles,
                  isDark: isDark,
                  accent: accent,
                  secondary: secondary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _staticFallback(bool isDark, Color accent, Color secondary) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: _StaticOrb(
              size: 360,
              color: accent.withValues(alpha: isDark ? 0.10 : 0.06),
            ),
          ),
          Positioned(
            bottom: -160,
            right: -100,
            child: _StaticOrb(
              size: 420,
              color: secondary.withValues(alpha: isDark ? 0.08 : 0.05),
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.delay,
    required this.durationScale,
    required this.opacity,
  });
  final double x;
  final double y;
  final double size;
  final double delay;
  final double durationScale;
  final double opacity;
}

class _AtmospherePainter extends CustomPainter {
  _AtmospherePainter({
    required this.t,
    required this.particles,
    required this.isDark,
    required this.accent,
    required this.secondary,
  });

  final double t;
  final List<_Particle> particles;
  final bool isDark;
  final Color accent;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Base canvas — vertical ambient gradient that matches scaffold.
    final base = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF05060A), Color(0xFF080B15), Color(0xFF03050B)]
            : const [Color(0xFFF6F7FB), Color(0xFFEFF3FA), Color(0xFFE5ECF6)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), base);

    // 3 drifting glow orbs.
    final orbAlpha = isDark ? 0.18 : 0.10;
    _drawOrb(
      canvas: canvas,
      cx: w * (0.06 + math.sin(t * 2 * math.pi) * 0.04),
      cy: h * (-0.08 + math.cos(t * 2 * math.pi) * 0.03),
      r: math.min(w, h) * 0.55,
      color: accent.withValues(alpha: orbAlpha),
      blurSigma: 60,
    );
    _drawOrb(
      canvas: canvas,
      cx: w * (1.05 + math.sin((t + 0.33) * 2 * math.pi) * 0.05),
      cy: h * (0.85 + math.cos((t + 0.33) * 2 * math.pi) * 0.04),
      r: math.min(w, h) * 0.50,
      color: secondary.withValues(alpha: orbAlpha * 0.85),
      blurSigma: 60,
    );
    _drawOrb(
      canvas: canvas,
      cx: w * (0.40 + math.sin((t + 0.66) * 2 * math.pi) * 0.06),
      cy: h * (0.45 + math.cos((t + 0.66) * 2 * math.pi) * 0.05),
      r: math.min(w, h) * 0.40,
      color: HSLColor.fromColor(accent)
          .withSaturation(0.4)
          .withLightness(0.55)
          .toColor()
          .withValues(alpha: orbAlpha * 0.5),
      blurSigma: 50,
    );

    // Ambient diagonal ray — subtle pulsing.
    final rayPulse = 0.30 + (math.sin(t * 4 * math.pi) * 0.5 + 0.5) * 0.30;
    final rayPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          accent.withValues(alpha: 0.04 * rayPulse),
          secondary.withValues(alpha: 0.06 * rayPulse),
          accent.withValues(alpha: 0.04 * rayPulse),
          Colors.transparent,
        ],
        stops: const [0.0, 0.30, 0.50, 0.70, 1.0],
      ).createShader(Rect.fromLTWH(-w * 0.5, h * 0.20, w * 2, 2))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.save();
    canvas.translate(w / 2, h * 0.25);
    canvas.rotate(-5 * math.pi / 180);
    canvas.translate(-w, 0);
    canvas.drawRect(Rect.fromLTWH(0, 0, w * 2, 2), rayPaint);
    canvas.restore();

    // Particles — float upward + fade.
    for (final p in particles) {
      // Each particle has its own sub-cycle (drift + fade) keyed off `t`.
      final cycle = ((t / p.durationScale) + p.delay) % 1.0;
      // Quadratic float — fast rise, slow fade.
      final localY = p.y * h - cycle * 60;
      final localX = p.x * w + math.sin(cycle * 2 * math.pi) * 6;
      // Triangle envelope: 0 → opacity → 0.
      final env = cycle < 0.5 ? cycle * 2 : (1 - cycle) * 2;
      final scale = cycle < 0.5 ? cycle * 2 : (1.0 - (cycle - 0.5));
      final alpha = (env * p.opacity).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = accent.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(
        Offset(localX, localY),
        p.size * scale * 0.5 + p.size * 0.5,
        paint,
      );
    }
  }

  void _drawOrb({
    required Canvas canvas,
    required double cx,
    required double cy,
    required double r,
    required Color color,
    required double blurSigma,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
    canvas.drawCircle(Offset(cx, cy), r, paint);
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter old) =>
      old.t != t ||
      old.isDark != isDark ||
      old.accent != accent ||
      old.secondary != secondary;
}

class _StaticOrb extends StatelessWidget {
  const _StaticOrb({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}


