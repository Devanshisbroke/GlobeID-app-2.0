import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';

/// Phase 16a — Wallet "investment milestone" cinematic.
///
/// 3.0 s ceremony that fires when a savings / investment goal is
/// crossed (e.g. portfolio crosses €100k, an emergency fund hits
/// 6 months of runway, a recurring deposit hits its anniversary).
///
/// Phases:
///   • 0.00-0.40 s — substrate dim, baseline bar lays in (left)
///   • 0.40-1.30 s — value bar rises from 0 → 100% (ease-out cubic),
///     rolling digits chase the bar
///   • 1.30-1.80 s — target tick on the right glows (mediumImpact),
///     bar overshoots 2 px then settles
///   • 1.80-2.40 s — crown medal materializes above (heavyImpact),
///     hairline radial fans out
///   • 2.40-3.00 s — milestone label etches in + watermark
///     (lightImpact on complete)
enum InvestmentMilestonePhase {
  idle,
  baseline,
  fill,
  target,
  crown,
  settle,
  complete,
}

class InvestmentMilestoneFrames {
  InvestmentMilestoneFrames._();

  static const Duration baselineStart = Duration.zero;
  static const Duration fillStart = Duration(milliseconds: 400);
  static const Duration targetStart = Duration(milliseconds: 1300);
  static const Duration crownStart = Duration(milliseconds: 1800);
  static const Duration settleStart = Duration(milliseconds: 2400);
  static const Duration completeAt = Duration(milliseconds: 3000);

  static InvestmentMilestonePhase phaseAt(Duration elapsed) {
    if (elapsed < baselineStart) return InvestmentMilestonePhase.idle;
    if (elapsed < fillStart) return InvestmentMilestonePhase.baseline;
    if (elapsed < targetStart) return InvestmentMilestonePhase.fill;
    if (elapsed < crownStart) return InvestmentMilestonePhase.target;
    if (elapsed < settleStart) return InvestmentMilestonePhase.crown;
    if (elapsed < completeAt) return InvestmentMilestonePhase.settle;
    return InvestmentMilestonePhase.complete;
  }
}

class InvestmentMilestoneCeremony extends StatefulWidget {
  const InvestmentMilestoneCeremony({
    super.key,
    required this.label,
    required this.amount,
    this.onComplete,
    this.autoPlay = true,
  });

  /// e.g. 'EMERGENCY FUND · 6 MO'
  final String label;

  /// e.g. '€100,000'
  final String amount;

  final VoidCallback? onComplete;
  final bool autoPlay;

  @override
  State<InvestmentMilestoneCeremony> createState() =>
      _InvestmentMilestoneCeremonyState();
}

class _InvestmentMilestoneCeremonyState
    extends State<InvestmentMilestoneCeremony>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _targetHaptic = false;
  bool _crownHaptic = false;
  bool _completionFired = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: InvestmentMilestoneFrames.completeAt,
    )..addListener(_tick);
    if (widget.autoPlay) {
      _ctrl.forward();
    }
  }

  void _tick() {
    final elapsed = _ctrl.duration! * _ctrl.value;
    final phase = InvestmentMilestoneFrames.phaseAt(elapsed);
    if (!_targetHaptic && phase == InvestmentMilestonePhase.target) {
      _targetHaptic = true;
      HapticFeedback.mediumImpact();
    }
    if (!_crownHaptic && phase == InvestmentMilestonePhase.crown) {
      _crownHaptic = true;
      HapticFeedback.heavyImpact();
    }
    if (!_completionFired && phase == InvestmentMilestonePhase.complete) {
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
        final phase = InvestmentMilestoneFrames.phaseAt(elapsed);
        return SizedBox.expand(
          child: CustomPaint(
            painter: _InvestmentMilestonePainter(
              elapsed: elapsed,
              phase: phase,
              label: widget.label,
              amount: widget.amount,
            ),
          ),
        );
      },
    );
  }
}

class _InvestmentMilestonePainter extends CustomPainter {
  _InvestmentMilestonePainter({
    required this.elapsed,
    required this.phase,
    required this.label,
    required this.amount,
  });

  final Duration elapsed;
  final InvestmentMilestonePhase phase;
  final String label;
  final String amount;

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
    final centerY = size.height * 0.5;
    final barWidth = size.width * 0.66;
    final barLeft = (size.width - barWidth) / 2;
    final barRight = barLeft + barWidth;
    final barTop = centerY - 6;
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(barLeft, barTop, barWidth, 12),
      const Radius.circular(6),
    );

    final baselineP = _phaseProgress(
      InvestmentMilestoneFrames.baselineStart,
      InvestmentMilestoneFrames.fillStart,
    );
    final fillP = _phaseProgress(
      InvestmentMilestoneFrames.fillStart,
      InvestmentMilestoneFrames.targetStart,
    );
    final targetP = _phaseProgress(
      InvestmentMilestoneFrames.targetStart,
      InvestmentMilestoneFrames.crownStart,
    );
    final crownP = _phaseProgress(
      InvestmentMilestoneFrames.crownStart,
      InvestmentMilestoneFrames.settleStart,
    );
    final settleP = _phaseProgress(
      InvestmentMilestoneFrames.settleStart,
      InvestmentMilestoneFrames.completeAt,
    );

    // Baseline channel.
    final channel = Paint()
      ..color = Colors.white.withValues(alpha: 0.12 * baselineP);
    canvas.drawRRect(barRect, channel);
    final channelStroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.18 * baselineP)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    canvas.drawRRect(barRect, channelStroke);

    // Fill bar (rises from 0 → 1, slight overshoot in target phase).
    var fillRatio = Curves.easeOutCubic.transform(fillP.clamp(0.0, 1.0));
    if (targetP > 0 && targetP < 1) {
      // tiny overshoot 1.04 → 1.0
      final overshoot = math.sin(targetP * math.pi) * 0.04;
      fillRatio = (1 + overshoot).clamp(0.0, 1.04);
    } else if (phase.index >= InvestmentMilestonePhase.crown.index) {
      fillRatio = 1.0;
    }
    final fillWidth = (barWidth * fillRatio).clamp(0.0, barWidth);
    if (fillWidth > 1) {
      final fillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(barLeft, barTop, fillWidth, 12),
        const Radius.circular(6),
      );
      final foilPaint = Paint()
        ..shader = LinearGradient(
          colors: const [_foil, _foilLight, _foil],
          stops: const [0, 0.5, 1],
        ).createShader(fillRect.outerRect);
      canvas.drawRRect(fillRect, foilPaint);
    }

    // Target tick on the right (glows during target phase).
    final tickAlpha = (0.42 + targetP * 0.62).clamp(0.42, 1.0);
    final tick = Paint()
      ..color = _foilLight.withValues(alpha: tickAlpha)
      ..strokeWidth = 2.2;
    canvas.drawLine(
      Offset(barRight, barTop - 12),
      Offset(barRight, barTop + 24),
      tick,
    );

    // Rolling digit readout above the bar.
    if (fillP > 0) {
      final percent = (fillRatio * 100).clamp(0, 100).round();
      _drawTextCentered(
        canvas,
        '$percent%',
        Offset(size.width / 2, barTop - 36),
        20,
        Colors.white.withValues(alpha: 0.92),
        weight: FontWeight.w900,
        spacing: 1.2,
      );
    }

    // Crown medal materializes above center.
    if (crownP > 0 || settleP > 0) {
      final ringAlpha = crownP.clamp(0.0, 1.0);
      _drawCrown(
        canvas,
        Offset(size.width / 2, barTop - 96),
        16 + 14 * ringAlpha,
        ringAlpha,
      );
    }

    // Hairline radial fans from crown center.
    if (crownP > 0) {
      final cx = size.width / 2;
      final cy = barTop - 96;
      final rays = Paint()
        ..color = _foil.withValues(alpha: 0.42 * (1 - crownP))
        ..strokeWidth = 0.6;
      for (var i = 0; i < 8; i++) {
        final angle = -math.pi / 2 + i * (math.pi / 4);
        final inn = Offset(
          cx + 28 * math.cos(angle),
          cy + 28 * math.sin(angle),
        );
        final out = Offset(
          cx + (60 + crownP * 16) * math.cos(angle),
          cy + (60 + crownP * 16) * math.sin(angle),
        );
        canvas.drawLine(inn, out, rays);
      }
    }

    // Milestone copy + amount.
    if (settleP > 0) {
      _drawTextCentered(
        canvas,
        amount,
        Offset(size.width / 2, barTop + 56),
        26,
        Colors.white.withValues(alpha: 0.92 * settleP),
        weight: FontWeight.w900,
        spacing: 0.4,
      );
      _drawTextCentered(
        canvas,
        label.toUpperCase(),
        Offset(size.width / 2, barTop + 92),
        11,
        _foil.withValues(alpha: 0.86 * settleP),
        weight: FontWeight.w800,
        spacing: 1.8,
      );
      _drawTextCentered(
        canvas,
        'MILESTONE \u00b7 ACHIEVED',
        Offset(size.width / 2, barTop + 112),
        9,
        _foilLight.withValues(alpha: 0.72 * settleP),
        weight: FontWeight.w800,
        spacing: 1.8,
      );
      _drawTextRight(
        canvas,
        'GLOBE \u00b7 ID',
        Offset(size.width - 16, size.height - 16),
        9,
        Colors.white.withValues(alpha: 0.42 * settleP),
        weight: FontWeight.w800,
        spacing: 1.8,
      );
    }
  }

  void _drawCrown(Canvas canvas, Offset center, double radius, double alpha) {
    final halo = Paint()
      ..color = _foilLight.withValues(alpha: 0.32 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, radius * 1.5, halo);

    final body = Paint()..color = const Color(0xFF11141C);
    canvas.drawCircle(center, radius, body);

    final ring = Paint()
      ..color = _foil.withValues(alpha: 0.92 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, radius, ring);

    // Three crown peaks.
    final peak = Path();
    final peakHeight = radius * 0.5;
    peak.moveTo(center.dx - radius * 0.6, center.dy - radius * 0.1);
    peak.lineTo(center.dx - radius * 0.4, center.dy - peakHeight);
    peak.lineTo(center.dx - radius * 0.2, center.dy - radius * 0.2);
    peak.lineTo(center.dx, center.dy - peakHeight - 2);
    peak.lineTo(center.dx + radius * 0.2, center.dy - radius * 0.2);
    peak.lineTo(center.dx + radius * 0.4, center.dy - peakHeight);
    peak.lineTo(center.dx + radius * 0.6, center.dy - radius * 0.1);
    final peakPaint = Paint()
      ..color = _foilLight.withValues(alpha: 0.92 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(peak, peakPaint);

    // Inner gem dot.
    final gem = Paint()..color = _foilLight.withValues(alpha: alpha);
    canvas.drawCircle(center, 2.4, gem);
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
  bool shouldRepaint(_InvestmentMilestonePainter old) =>
      old.elapsed != elapsed || old.phase != phase;
}

class InvestmentMilestoneCeremonyScreen extends StatefulWidget {
  const InvestmentMilestoneCeremonyScreen({super.key});

  @override
  State<InvestmentMilestoneCeremonyScreen> createState() =>
      _InvestmentMilestoneCeremonyScreenState();
}

class _InvestmentMilestoneCeremonyScreenState
    extends State<InvestmentMilestoneCeremonyScreen> {
  int _generation = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InvestmentMilestoneCeremony(
                key: ValueKey<int>(_generation),
                label: 'EMERGENCY FUND \u00b7 6 MO',
                amount: '\u20ac100,000',
              ),
            ),
            Positioned(
              top: 24,
              left: 24,
              child: Os2Text.monoCap(
                'CINEMA \u00b7 16A',
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
                        'REPLAY \u00b7 MILESTONE',
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
