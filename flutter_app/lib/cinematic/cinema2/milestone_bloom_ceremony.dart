import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';

/// Phase 15b — Trip "milestone bloom" cinematic.
///
/// 2.8 s cinematic that fires when a trip phase advances to the next
/// milestone:
///   • 0.00-0.40 s — substrate dim, milestone ring traces in
///   • 0.40-1.10 s — gold petals radiate from the milestone marker
///     (6 petals · spiral · scale 0.0 → 1.0)
///   • 1.10-1.60 s — central bloom pulses (scale 0.92 → 1.18 ·
///     signature haptic on apex)
///   • 1.60-2.80 s — petals settle into a halo · milestone name
///     etches in · watermark drifts
///
/// Phases are deterministic — callers use `MilestoneBloomFrames.phaseAt`
/// to sync chrome / haptics / audio.
enum MilestoneBloomPhase {
  idle,
  ring,
  petals,
  pulse,
  settle,
  complete,
}

class MilestoneBloomFrames {
  MilestoneBloomFrames._();

  static const Duration ringStart = Duration.zero;
  static const Duration petalsStart = Duration(milliseconds: 400);
  static const Duration pulseStart = Duration(milliseconds: 1100);
  static const Duration settleStart = Duration(milliseconds: 1600);
  static const Duration completeAt = Duration(milliseconds: 2800);

  static MilestoneBloomPhase phaseAt(Duration elapsed) {
    if (elapsed < ringStart) return MilestoneBloomPhase.idle;
    if (elapsed < petalsStart) return MilestoneBloomPhase.ring;
    if (elapsed < pulseStart) return MilestoneBloomPhase.petals;
    if (elapsed < settleStart) return MilestoneBloomPhase.pulse;
    if (elapsed < completeAt) return MilestoneBloomPhase.settle;
    return MilestoneBloomPhase.complete;
  }
}

class MilestoneBloomCeremony extends StatefulWidget {
  const MilestoneBloomCeremony({
    super.key,
    required this.milestoneLabel,
    required this.phaseLabel,
    this.onComplete,
    this.autoPlay = true,
  });

  /// e.g. 'BARCELONA · ARRIVAL'
  final String milestoneLabel;

  /// e.g. 'PHASE · 03 / 06'
  final String phaseLabel;

  final VoidCallback? onComplete;
  final bool autoPlay;

  @override
  State<MilestoneBloomCeremony> createState() =>
      _MilestoneBloomCeremonyState();
}

class _MilestoneBloomCeremonyState extends State<MilestoneBloomCeremony>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _hapticFired = false;
  bool _completionFired = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: MilestoneBloomFrames.completeAt,
    )..addListener(_tick);
    if (widget.autoPlay) {
      _ctrl.forward();
    }
  }

  void _tick() {
    final elapsed = _ctrl.duration! * _ctrl.value;
    final phase = MilestoneBloomFrames.phaseAt(elapsed);
    if (!_hapticFired && phase == MilestoneBloomPhase.pulse) {
      _hapticFired = true;
      HapticFeedback.heavyImpact();
    }
    if (!_completionFired && phase == MilestoneBloomPhase.complete) {
      _completionFired = true;
      HapticFeedback.lightImpact();
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    _ctrl
      ..removeListener(_tick)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final elapsed = _ctrl.duration! * _ctrl.value;
        final phase = MilestoneBloomFrames.phaseAt(elapsed);
        return SizedBox.expand(
          child: CustomPaint(
            painter: _BloomPainter(
              elapsed: elapsed,
              phase: phase,
              milestoneLabel: widget.milestoneLabel,
              phaseLabel: widget.phaseLabel,
            ),
          ),
        );
      },
    );
  }
}

class _BloomPainter extends CustomPainter {
  _BloomPainter({
    required this.elapsed,
    required this.phase,
    required this.milestoneLabel,
    required this.phaseLabel,
  });

  final Duration elapsed;
  final MilestoneBloomPhase phase;
  final String milestoneLabel;
  final String phaseLabel;

  static const Color _foil = Color(0xFFD4AF37);
  static const Color _foilLight = Color(0xFFE9C75D);

  double _phaseProgress(Duration start, Duration end) {
    final span = (end - start).inMilliseconds;
    if (span <= 0) return 1;
    final ms = elapsed.inMilliseconds - start.inMilliseconds;
    if (ms <= 0) return 0;
    if (ms >= span) return 1;
    return ms / span;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF050505),
    );
    final center = Offset(size.width / 2, size.height * 0.42);

    // Ring traces in.
    final ringP = _phaseProgress(
      MilestoneBloomFrames.ringStart,
      MilestoneBloomFrames.petalsStart,
    );
    if (ringP > 0) {
      final ringRadius = 84.0;
      final start = -math.pi / 2;
      final sweep = 2 * math.pi *
          Curves.easeOutCubic.transform(ringP);
      final ringPaint = Paint()
        ..color = _foil.withValues(alpha: 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        start,
        sweep,
        false,
        ringPaint,
      );
    }

    // Petals radiate.
    final petalP = _phaseProgress(
      MilestoneBloomFrames.petalsStart,
      MilestoneBloomFrames.pulseStart,
    );
    if (petalP > 0) {
      const petalCount = 6;
      for (var i = 0; i < petalCount; i++) {
        // Staggered, so each petal starts slightly later.
        final stagger = i / (petalCount * 1.4);
        final local = ((petalP - stagger) / (1 - stagger))
            .clamp(0.0, 1.0);
        if (local <= 0) continue;
        final angle = (i * (2 * math.pi / petalCount)) -
            math.pi / 2 +
            (petalP * 0.6);
        final dist = 84 + 54 * Curves.easeOutCubic.transform(local);
        final petalCenter = Offset(
          center.dx + dist * math.cos(angle),
          center.dy + dist * math.sin(angle),
        );
        final petalRadius = 8.0 + 14 * Curves.easeOutCubic.transform(local);
        final petalAlpha = 0.42 + 0.5 * local;
        final petalPaint = Paint()
          ..color = _foilLight.withValues(alpha: petalAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(petalCenter, petalRadius, petalPaint);
      }
    }

    // Central pulse.
    final pulseP = _phaseProgress(
      MilestoneBloomFrames.pulseStart,
      MilestoneBloomFrames.settleStart,
    );
    if (pulseP > 0) {
      final pulseScale = 0.92 + 0.26 * _pulseCurve(pulseP);
      final pulseRadius = 36.0 * pulseScale;
      final pulsePaint = Paint()
        ..color = _foil.withValues(alpha: 0.86)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
      canvas.drawCircle(center, pulseRadius, pulsePaint);
      // Hairline ring at apex.
      final ring = Paint()
        ..color = _foilLight.withValues(alpha: 0.86)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      canvas.drawCircle(center, pulseRadius, ring);
    }

    // Settle — petals into halo, milestone name etches in.
    final settleP = _phaseProgress(
      MilestoneBloomFrames.settleStart,
      MilestoneBloomFrames.completeAt,
    );
    if (settleP > 0) {
      // Halo (settling fade).
      final haloPaint = Paint()
        ..color = _foil.withValues(alpha: 0.36 * (1 - 0.6 * settleP));
      canvas.drawCircle(center, 96, haloPaint);

      // Milestone name etches in below center.
      final nameOpacity = settleP.clamp(0.0, 1.0);
      _drawTextCentered(
        canvas,
        milestoneLabel.toUpperCase(),
        Offset(center.dx, center.dy + 124),
        14,
        Colors.white.withValues(alpha: 0.92 * nameOpacity),
        weight: FontWeight.w900,
        spacing: 1.8,
      );
      _drawTextCentered(
        canvas,
        phaseLabel.toUpperCase(),
        Offset(center.dx, center.dy + 150),
        9,
        _foil.withValues(alpha: 0.78 * nameOpacity),
        weight: FontWeight.w800,
        spacing: 1.6,
      );

      // GLOBE · ID watermark bottom right.
      _drawTextRight(
        canvas,
        'GLOBE \u00b7 ID',
        Offset(size.width - 16, size.height - 16),
        9,
        Colors.white.withValues(alpha: 0.42 * nameOpacity),
        weight: FontWeight.w800,
        spacing: 1.8,
      );
    }
  }

  /// 0..1 → 0..1..0 (pulse).
  double _pulseCurve(double t) {
    if (t < 0.55) {
      return Curves.easeOutCubic.transform(t / 0.55);
    }
    return 1 - Curves.easeInCubic.transform((t - 0.55) / 0.45);
  }

  void _drawTextCentered(
    Canvas canvas,
    String text,
    Offset center,
    double size,
    Color color, {
    FontWeight weight = FontWeight.w800,
    double spacing = 0,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: spacing,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  void _drawTextRight(
    Canvas canvas,
    String text,
    Offset rightCenter,
    double size,
    Color color, {
    FontWeight weight = FontWeight.w800,
    double spacing = 0,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: spacing,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(rightCenter.dx - tp.width, rightCenter.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_BloomPainter old) =>
      old.elapsed != elapsed || old.phase != phase;
}

class MilestoneBloomCeremonyScreen extends StatefulWidget {
  const MilestoneBloomCeremonyScreen({super.key});

  @override
  State<MilestoneBloomCeremonyScreen> createState() =>
      _MilestoneBloomCeremonyScreenState();
}

class _MilestoneBloomCeremonyScreenState
    extends State<MilestoneBloomCeremonyScreen> {
  int _generation = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: MilestoneBloomCeremony(
                key: ValueKey<int>(_generation),
                milestoneLabel: 'BARCELONA \u00b7 ARRIVAL',
                phaseLabel: 'PHASE \u00b7 03 / 06',
              ),
            ),
            Positioned(
              top: 24,
              left: 24,
              child: Os2Text.monoCap(
                'CINEMA \u00b7 15B',
                color: const Color(0xFFD4AF37),
                size: Os2.textTiny,
              ),
            ),
            Positioned(
              top: 22,
              right: 24,
              child: IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 32,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _generation++),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37)
                            .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFD4AF37)
                              .withValues(alpha: 0.62),
                          width: 0.6,
                        ),
                      ),
                      child: Os2Text.monoCap(
                        'REPLAY \u00b7 BLOOM',
                        color: const Color(0xFFD4AF37),
                        size: Os2.textTiny,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
