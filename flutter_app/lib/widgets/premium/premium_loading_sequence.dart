import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../nexus/nexus_tokens.dart';

/// Cinematic global loading — **Nexus-aligned restrained sweep.**
///
/// Was a triple-layered loader: radial halo glow that breathed +
/// saturated comet head + brand-tinted track. After the Travel-OS /
/// Wallet migration this primitive renders the Lovable canonical
/// "thinking" affordance — a thin champagne arc sweeping a hairline
/// track ring on the OLED substrate, with no halo glow and no white
/// comet head.
///
/// Anatomy:
///   1. Hairline track ring (`N.hairline`, 1.4px)
///   2. Champagne sweep arc (`tone` default = `N.tierGold`, 1.4px,
///      round caps, 0.65 π span)
///   3. Optional eyebrow caption + three restrained breathing dots
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tone = widget.tone ?? N.tierGold;
    final reduce = MediaQuery.of(context).disableAnimations;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.size,
          width: widget.size,
          child: AnimatedBuilder(
            animation: _sweep,
            builder: (_, __) {
              return CustomPaint(
                painter: _PremiumLoadingPainter(
                  sweep: reduce ? 0 : _sweep.value,
                  tone: tone,
                ),
              );
            },
          ),
        ),
        if (widget.caption != null) ...[
          const SizedBox(height: AppTokens.space3),
          Text(
            widget.caption!.toUpperCase(),
            style: const TextStyle(
              color: N.inkMid,
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
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
    required this.tone,
  });
  final double sweep;
  final Color tone;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 4;

    // Hairline track ring.
    final track = Paint()
      ..color = N.hairline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(c, r * 0.62, track);

    // Champagne sweep arc (no halo, no comet head).
    final start = sweep * 2 * math.pi;
    final arc = Paint()
      ..color = tone
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.62),
      start,
      math.pi * 0.65,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _PremiumLoadingPainter old) =>
      old.sweep != sweep || old.tone != tone;
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
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.30 + 0.55 * t),
        shape: BoxShape.circle,
      ),
    );
  }
}
