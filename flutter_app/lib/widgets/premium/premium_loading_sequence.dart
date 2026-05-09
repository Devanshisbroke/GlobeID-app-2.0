import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// Cinematic global loading — replaces bare CircularProgressIndicator.
///
/// Three layered effects:
///   1. an arc sweep around a central halo
///   2. a radial glow that breathes
///   3. three breathing dots beneath an optional caption
class PremiumLoadingSequence extends StatefulWidget {
  const PremiumLoadingSequence({
    super.key,
    this.size = 64,
    this.tone,
    this.caption,
    this.intensity = 1.0,
  });

  final double size;
  final Color? tone;
  final String? caption;
  final double intensity;

  @override
  State<PremiumLoadingSequence> createState() => _PremiumLoadingSequenceState();
}

class _PremiumLoadingSequenceState extends State<PremiumLoadingSequence>
    with TickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();
  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _sweep.dispose();
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = widget.tone ?? theme.colorScheme.primary;
    final reduce = MediaQuery.of(context).disableAnimations;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.size,
          width: widget.size,
          child: AnimatedBuilder(
            animation: Listenable.merge([_sweep, _breathe]),
            builder: (_, __) {
              return CustomPaint(
                painter: _PremiumLoadingPainter(
                  sweep: reduce ? 0 : _sweep.value,
                  breathe: reduce ? 0.5 : _breathe.value,
                  tone: tone,
                  intensity: widget.intensity.clamp(0.0, 1.5),
                ),
              );
            },
          ),
        ),
        if (widget.caption != null) ...[
          const SizedBox(height: AppTokens.space3),
          Text(
            widget.caption!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTokens.space2),
          _BreathingDots(tone: tone),
        ],
      ],
    );
  }
}

class _PremiumLoadingPainter extends CustomPainter {
  _PremiumLoadingPainter({
    required this.sweep,
    required this.breathe,
    required this.tone,
    required this.intensity,
  });
  final double sweep;
  final double breathe;
  final Color tone;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 4;
    // Halo
    final halo = Paint()
      ..shader = RadialGradient(
        colors: [
          tone.withValues(alpha: 0.30 * intensity * (0.5 + breathe * 0.5)),
          tone.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, halo);

    // Track ring
    final track = Paint()
      ..color = tone.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(c, r * 0.6, track);

    // Sweep arc
    final start = sweep * 2 * math.pi;
    final arc = Paint()
      ..color = tone.withValues(alpha: 0.95 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.6),
      start,
      math.pi * 0.65,
      false,
      arc,
    );

    // Trailing comet head
    final head = Paint()
      ..color = Colors.white.withValues(alpha: 0.85);
    final hx = c.dx + math.cos(start + math.pi * 0.65) * (r * 0.6);
    final hy = c.dy + math.sin(start + math.pi * 0.65) * (r * 0.6);
    canvas.drawCircle(Offset(hx, hy), 3.6, head);
  }

  @override
  bool shouldRepaint(covariant _PremiumLoadingPainter old) =>
      old.sweep != sweep ||
      old.breathe != breathe ||
      old.tone != tone ||
      old.intensity != intensity;
}

class _BreathingDots extends StatefulWidget {
  const _BreathingDots({required this.tone});
  final Color tone;
  @override
  State<_BreathingDots> createState() => _BreathingDotsState();
}

class _BreathingDotsState extends State<_BreathingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              _Dot(
                phase: reduce ? 0 : (_ctrl.value + i / 3) % 1,
                tone: widget.tone,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.phase, required this.tone});
  final double phase;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    final t = (math.sin(phase * 2 * math.pi) + 1) / 2;
    final size = 5.0 + 3.0 * t;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.4 + 0.5 * t),
        shape: BoxShape.circle,
      ),
    );
  }
}
