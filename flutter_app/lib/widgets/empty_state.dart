import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme/app_tokens.dart';

/// Premium empty state — animated aurora orb illustration behind the
/// icon, gentle bob, fade in, optional CTAs.
class EmptyState extends StatefulWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.tone,
    this.cta,
    this.onCta,
    this.tertiary,
    this.onTertiary,
  });

  final String title;
  final String message;
  final IconData? icon;
  final Color? tone;
  final String? cta;
  final VoidCallback? onCta;
  final String? tertiary;
  final VoidCallback? onTertiary;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.tone ?? theme.colorScheme.primary;
    return Semantics(
      container: true,
      liveRegion: true,
      label: '${widget.title}. ${widget.message}',
      child: ExcludeSemantics(
        excluding: widget.cta == null && widget.tertiary == null,
        child: Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => SizedBox(
                width: 132,
                height: 132,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Animated aurora orb
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _AuroraPainter(
                          color: color,
                          progress: _ctrl.value,
                        ),
                      ),
                    ),
                    // Floating icon
                    Transform.translate(
                      offset:
                          Offset(0, math.sin(_ctrl.value * math.pi * 2) * 3),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: 0.18),
                          border:
                              Border.all(color: color.withValues(alpha: 0.36)),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.20),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.icon ?? Icons.auto_awesome_rounded,
                          color: color,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTokens.space5),
            Text(widget.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center),
            const SizedBox(height: AppTokens.space2),
            Text(widget.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  height: 1.4,
                ),
                textAlign: TextAlign.center),
            if (widget.cta != null) ...[
              const SizedBox(height: AppTokens.space5),
              FilledButton(onPressed: widget.onCta, child: Text(widget.cta!)),
            ],
            if (widget.tertiary != null) ...[
              const SizedBox(height: AppTokens.space2),
              TextButton(
                  onPressed: widget.onTertiary, child: Text(widget.tertiary!)),
            ],
          ],
        ),
      ),
        ),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({required this.color, required this.progress});
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2;

    // Outer glow
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.32),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, glow);

    // Two rotating arcs
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.6);

    for (var i = 0; i < 2; i++) {
      final start = (progress * 2 * math.pi) + i * math.pi;
      final radius = r * (0.7 - i * 0.12);
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: radius),
        start,
        math.pi * 0.85,
        false,
        arcPaint
          ..color = color.withValues(alpha: 0.55 - i * 0.18)
          ..strokeWidth = 1.4 - i * 0.4,
      );
    }

    // Sparkle dots
    final sparkle = Paint()..color = color.withValues(alpha: 0.7);
    for (var i = 0; i < 6; i++) {
      final theta = (progress * 2 * math.pi) + i * (math.pi / 3);
      final dotR = r * (0.85 + 0.05 * math.sin(progress * 2 * math.pi + i));
      final p = c + Offset(math.cos(theta), math.sin(theta)) * dotR;
      canvas.drawCircle(p, 1.6, sparkle);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) =>
      old.progress != progress || old.color != color;
}
