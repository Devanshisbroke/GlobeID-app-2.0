import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../app/theme/app_tokens.dart';

/// Cinematic hero — a tall edge-to-edge banner with:
///   • Layered gradient backdrop (deep parallax depth)
///   • Soft animated noise / aurora wash
///   • Accelerometer-driven parallax (clamped, motion-aware)
///   • Optional badge cluster (rating, eta, distance, flag)
///   • Optional CTA chip in the bottom-right
///
/// Used by hotel / restaurant / flight / airport detail headers.
/// Reuses the same render pipeline so the whole ecosystem feels
/// like one cohesive surface treatment.
class CinematicHero extends StatefulWidget {
  const CinematicHero({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.badges = const [],
    this.gradient,
    this.icon,
    this.height = 252,
    this.flag,
    this.tone,
  });

  final String title;
  final String? subtitle;
  final String? eyebrow;
  final List<HeroBadge> badges;
  final Gradient? gradient;
  final IconData? icon;
  final double height;
  final String? flag;
  final Color? tone;

  @override
  State<CinematicHero> createState() => _CinematicHeroState();
}

class _CinematicHeroState extends State<CinematicHero>
    with SingleTickerProviderStateMixin {
  StreamSubscription<AccelerometerEvent>? _sub;
  double _tx = 0;
  double _ty = 0;
  late final AnimationController _aurora = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _sub = accelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).handleError((_) {}).listen((e) {
      if (!mounted) return;
      final tx = (e.x.clamp(-3, 3) / 3) * 8;
      final ty = (e.y.clamp(-3, 3) / 3) * 8;
      setState(() {
        _tx = _tx * 0.82 + tx * 0.18;
        _ty = _ty * 0.82 + ty * 0.18;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _aurora.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = widget.tone ?? theme.colorScheme.primary;
    final gradient = widget.gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tone,
            tone.withValues(alpha: 0.55),
          ],
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radius3xl),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Base gradient
            DecoratedBox(decoration: BoxDecoration(gradient: gradient)),

            // Aurora wash — slow drifting radial gradients
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _aurora,
                builder: (_, __) => CustomPaint(
                  painter: _AuroraPainter(
                    t: _aurora.value,
                    tone: tone,
                  ),
                ),
              ),
            ),

            // Star dust scatter (cheap, deterministic)
            const RepaintBoundary(
              child: CustomPaint(painter: _StarDustPainter()),
            ),

            // Parallax glyph
            if (widget.icon != null)
              Positioned(
                right: -20 + _tx,
                top: -20 + _ty,
                child: Opacity(
                  opacity: 0.18,
                  child: Icon(
                    widget.icon,
                    size: 260,
                    color: Colors.white,
                  ),
                ),
              ),

            // Bottom dim
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.32),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppTokens.space5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (widget.flag != null) ...[
                        Text(widget.flag!,
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: AppTokens.space2),
                      ],
                      if (widget.eyebrow != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusFull),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Text(
                            widget.eyebrow!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                          letterSpacing: -0.4,
                          shadows: const [
                            Shadow(
                              color: Color(0x66000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: AppTokens.space2),
                        Text(
                          widget.subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                      if (widget.badges.isNotEmpty) ...[
                        const SizedBox(height: AppTokens.space3),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final b in widget.badges) _Badge(badge: b),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HeroBadge {
  const HeroBadge({required this.label, this.icon});
  final String label;
  final IconData? icon;
}

class _Badge extends StatelessWidget {
  const _Badge({required this.badge});
  final HeroBadge badge;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(AppTokens.radiusFull),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.32),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badge.icon != null) ...[
                Icon(badge.icon, size: 13, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Text(
                badge.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  const _AuroraPainter({required this.t, required this.tone});
  final double t;
  final Color tone;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * (0.5 + math.sin(t * math.pi * 2) * 0.18),
        size.height * 0.4 + math.cos(t * math.pi * 2) * 18);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.25),
          tone.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.7))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36);
    canvas.drawCircle(center, size.width * 0.6, paint);

    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          tone.withValues(alpha: 0.30),
          tone.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.2, size.height * 0.85),
          radius: size.width * 0.5,
        ),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.85),
      size.width * 0.4,
      paint2,
    );
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) =>
      old.t != t || old.tone != tone;
}

class _StarDustPainter extends CustomPainter {
  const _StarDustPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.12);
    for (var i = 0; i < 80; i++) {
      final dx = rng.nextDouble() * size.width;
      final dy = rng.nextDouble() * size.height;
      final r = 0.4 + rng.nextDouble() * 1.4;
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarDustPainter old) => false;
}
