import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';

/// Phase 15c — Identity "tier promotion" cinematic.
///
/// 3.2 s coronation animation when an identity signet tier
/// advances (e.g. STANDARD → ATELIER → PILOT):
///   • 0.00-0.40 s — substrate dim, current-tier medallion glows
///   • 0.40-1.20 s — medallion lifts up (vertical translate) +
///     light haptic on lift
///   • 1.20-1.90 s — three concentric rings expand outward + foil
///     beam sweep across the medallion
///   • 1.90-2.50 s — new tier medallion materializes below the
///     rising one (cross-fade), heavyImpact haptic on lock-in
///   • 2.50-3.20 s — both medallions hold, tier name etches in,
///     watermark drifts, lightImpact on complete
enum TierPromotionPhase {
  idle,
  glow,
  lift,
  rings,
  reveal,
  hold,
  complete,
}

class TierPromotionFrames {
  TierPromotionFrames._();

  static const Duration glowStart = Duration.zero;
  static const Duration liftStart = Duration(milliseconds: 400);
  static const Duration ringsStart = Duration(milliseconds: 1200);
  static const Duration revealStart = Duration(milliseconds: 1900);
  static const Duration holdStart = Duration(milliseconds: 2500);
  static const Duration completeAt = Duration(milliseconds: 3200);

  static TierPromotionPhase phaseAt(Duration elapsed) {
    if (elapsed < glowStart) return TierPromotionPhase.idle;
    if (elapsed < liftStart) return TierPromotionPhase.glow;
    if (elapsed < ringsStart) return TierPromotionPhase.lift;
    if (elapsed < revealStart) return TierPromotionPhase.rings;
    if (elapsed < holdStart) return TierPromotionPhase.reveal;
    if (elapsed < completeAt) return TierPromotionPhase.hold;
    return TierPromotionPhase.complete;
  }
}

class TierPromotionCeremony extends StatefulWidget {
  const TierPromotionCeremony({
    super.key,
    required this.fromTier,
    required this.toTier,
    this.onComplete,
    this.autoPlay = true,
  });

  /// e.g. 'ATELIER'
  final String fromTier;

  /// e.g. 'PILOT'
  final String toTier;

  final VoidCallback? onComplete;
  final bool autoPlay;

  @override
  State<TierPromotionCeremony> createState() => _TierPromotionCeremonyState();
}

class _TierPromotionCeremonyState extends State<TierPromotionCeremony>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _liftHaptic = false;
  bool _lockHaptic = false;
  bool _completionFired = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: TierPromotionFrames.completeAt,
    )..addListener(_tick);
    if (widget.autoPlay) {
      _ctrl.forward();
    }
  }

  void _tick() {
    final elapsed = _ctrl.duration! * _ctrl.value;
    final phase = TierPromotionFrames.phaseAt(elapsed);
    if (!_liftHaptic && phase == TierPromotionPhase.lift) {
      _liftHaptic = true;
      HapticFeedback.lightImpact();
    }
    if (!_lockHaptic && phase == TierPromotionPhase.reveal) {
      _lockHaptic = true;
      HapticFeedback.heavyImpact();
    }
    if (!_completionFired && phase == TierPromotionPhase.complete) {
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
        final phase = TierPromotionFrames.phaseAt(elapsed);
        return SizedBox.expand(
          child: CustomPaint(
            painter: _TierPromotionPainter(
              elapsed: elapsed,
              phase: phase,
              fromTier: widget.fromTier,
              toTier: widget.toTier,
            ),
          ),
        );
      },
    );
  }
}

class _TierPromotionPainter extends CustomPainter {
  _TierPromotionPainter({
    required this.elapsed,
    required this.phase,
    required this.fromTier,
    required this.toTier,
  });

  final Duration elapsed;
  final TierPromotionPhase phase;
  final String fromTier;
  final String toTier;

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
    // Substrate.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF050505),
    );

    final centerX = size.width / 2;
    final originY = size.height * 0.55;

    // Glow on the medallion.
    final glowP = _phaseProgress(
      TierPromotionFrames.glowStart,
      TierPromotionFrames.liftStart,
    );
    final glowAlpha = 0.42 + 0.5 * Curves.easeOutCubic.transform(glowP);

    // Lift translation (from-medallion rises from originY → originY - 96).
    final liftP = _phaseProgress(
      TierPromotionFrames.liftStart,
      TierPromotionFrames.ringsStart,
    );
    final ringsP = _phaseProgress(
      TierPromotionFrames.ringsStart,
      TierPromotionFrames.revealStart,
    );
    final revealP = _phaseProgress(
      TierPromotionFrames.revealStart,
      TierPromotionFrames.holdStart,
    );
    final holdP = _phaseProgress(
      TierPromotionFrames.holdStart,
      TierPromotionFrames.completeAt,
    );

    // Compute lifted Y based on liftP + later phases (stays lifted).
    final liftedY = originY -
        96 * Curves.easeOutCubic.transform(
          (liftP + (ringsP > 0 ? 1 : 0) + (revealP > 0 ? 1 : 0))
              .clamp(0.0, 1.0),
        );

    // Three concentric rings (1.20-1.90s).
    if (ringsP > 0) {
      for (var i = 0; i < 3; i++) {
        final stagger = i * 0.18;
        final local = ((ringsP - stagger) / (1 - stagger))
            .clamp(0.0, 1.0);
        if (local <= 0) continue;
        final radius = 48 + 110 * Curves.easeOutCubic.transform(local);
        final alpha = 0.62 * (1 - local);
        final ring = Paint()
          ..color = _foil.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4;
        canvas.drawCircle(Offset(centerX, liftedY), radius, ring);
      }

      // Foil beam sweep across the lifted medallion.
      final sweepX = -size.width / 2 +
          (size.width * 1.6) *
              Curves.easeInOutCubic.transform(ringsP);
      _drawFoilSweep(
        canvas,
        size,
        Offset(centerX + sweepX, liftedY),
      );
    }

    // From-medallion (the rising one). Stays visible until reveal.
    final fromAlpha = revealP < 1.0 ? 1.0 - 0.42 * revealP : 0.58;
    _drawMedallion(
      canvas,
      Offset(centerX, liftedY),
      48.0,
      fromTier,
      glow: glowAlpha,
      alpha: fromAlpha,
    );

    // New-tier medallion materializes (revealP).
    if (revealP > 0) {
      final scale = 0.7 + 0.3 * Curves.easeOutCubic.transform(revealP);
      _drawMedallion(
        canvas,
        Offset(centerX, originY),
        48.0 * scale,
        toTier,
        glow: 0.42 + 0.58 * revealP,
        alpha: revealP.clamp(0.0, 1.0),
        emphasis: true,
      );
    }

    // Hold — tier name etches in + watermark.
    if (holdP > 0) {
      _drawTextCentered(
        canvas,
        toTier.toUpperCase(),
        Offset(centerX, originY + 86),
        18,
        Colors.white.withValues(alpha: 0.92 * holdP),
        weight: FontWeight.w900,
        spacing: 2.0,
      );
      _drawTextCentered(
        canvas,
        'TIER \u00b7 PROMOTED',
        Offset(centerX, originY + 112),
        9,
        _foil.withValues(alpha: 0.78 * holdP),
        weight: FontWeight.w800,
        spacing: 1.8,
      );
      _drawTextRight(
        canvas,
        'GLOBE \u00b7 ID',
        Offset(size.width - 16, size.height - 16),
        9,
        Colors.white.withValues(alpha: 0.42 * holdP),
        weight: FontWeight.w800,
        spacing: 1.8,
      );
    }
  }

  void _drawMedallion(
    Canvas canvas,
    Offset center,
    double radius,
    String tier, {
    double glow = 0.42,
    double alpha = 1,
    bool emphasis = false,
  }) {
    // Outer halo.
    final halo = Paint()
      ..color = _foil.withValues(alpha: 0.42 * glow * alpha)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        emphasis ? 8 : 4,
      );
    canvas.drawCircle(center, radius * 1.4, halo);

    // Inner body.
    final body = Paint()
      ..color = const Color(0xFF11141C).withValues(alpha: 0.92 * alpha);
    canvas.drawCircle(center, radius, body);

    // Hairline ring.
    final ring = Paint()
      ..color = (emphasis ? _foilLight : _foil)
          .withValues(alpha: 0.86 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = emphasis ? 1.6 : 1.2;
    canvas.drawCircle(center, radius, ring);

    // Tier glyph (mono-cap, first 3 chars).
    final glyph = tier.substring(0, math.min(3, tier.length)).toUpperCase();
    _drawTextCentered(
      canvas,
      glyph,
      center,
      radius * 0.42,
      Colors.white.withValues(alpha: 0.92 * alpha),
      weight: FontWeight.w900,
      spacing: 1.8,
    );
  }

  void _drawFoilSweep(Canvas canvas, Size size, Offset center) {
    final rect = Rect.fromCenter(center: center, width: 60, height: 96);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          _foil.withValues(alpha: 0),
          _foilLight.withValues(alpha: 0.62),
          _foil.withValues(alpha: 0),
        ],
        stops: const [0, 0.5, 1],
      ).createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRect(rect, paint);
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
  bool shouldRepaint(_TierPromotionPainter old) =>
      old.elapsed != elapsed || old.phase != phase;
}

class TierPromotionCeremonyScreen extends StatefulWidget {
  const TierPromotionCeremonyScreen({super.key});

  @override
  State<TierPromotionCeremonyScreen> createState() =>
      _TierPromotionCeremonyScreenState();
}

class _TierPromotionCeremonyScreenState
    extends State<TierPromotionCeremonyScreen> {
  int _generation = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: TierPromotionCeremony(
                key: ValueKey<int>(_generation),
                fromTier: 'ATELIER',
                toTier: 'PILOT',
              ),
            ),
            Positioned(
              top: 24,
              left: 24,
              child: Os2Text.monoCap(
                'CINEMA \u00b7 15C',
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
                        'REPLAY \u00b7 PROMOTION',
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
