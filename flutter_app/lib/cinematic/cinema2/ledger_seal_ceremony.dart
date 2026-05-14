import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';

/// Phase 15a — Wallet "ledger seal" ceremony.
///
/// 2.4 s cinematic that fires when a wallet entry is committed:
///   • 0.00-0.40 s — substrate dim + ledger ribbon prints in
///   • 0.40-1.00 s — gold wax loads onto the seal (color fills,
///     scale 0.92 → 1.20)
///   • 1.00-1.50 s — seal arc-drops onto the ledger (scale 1.45
///     → 0.96 overshoot · ink press) · signature haptic
///   • 1.50-2.40 s — gold ink bleeds, ledger settles, watermark
///     drifts into the corner
///
/// Phases are deterministic — `LedgerSealPhase` exposes the current
/// frame so callers can sync chrome / haptics / audio.
enum LedgerSealPhase {
  /// Idle — nothing painted yet.
  idle,

  /// Ribbon prints onto the substrate.
  ribbon,

  /// Wax loads onto the seal.
  wax,

  /// Seal drops onto the ledger.
  press,

  /// Ink bleeds + watermark drifts.
  settle,

  /// Cinematic complete.
  complete,
}

/// Frame boundaries (ms) for each phase.
class LedgerSealFrames {
  LedgerSealFrames._();

  static const Duration ribbonStart = Duration.zero;
  static const Duration waxStart = Duration(milliseconds: 400);
  static const Duration pressStart = Duration(milliseconds: 1000);
  static const Duration settleStart = Duration(milliseconds: 1500);
  static const Duration completeAt = Duration(milliseconds: 2400);

  /// Resolve the phase active at `elapsed`.
  static LedgerSealPhase phaseAt(Duration elapsed) {
    if (elapsed < ribbonStart) return LedgerSealPhase.idle;
    if (elapsed < waxStart) return LedgerSealPhase.ribbon;
    if (elapsed < pressStart) return LedgerSealPhase.wax;
    if (elapsed < settleStart) return LedgerSealPhase.press;
    if (elapsed < completeAt) return LedgerSealPhase.settle;
    return LedgerSealPhase.complete;
  }
}

/// The drawable ceremony widget. Self-contained; drops into any
/// surface that wants the cinematic. Fires `onComplete` when the
/// seal lands and the ink finishes bleeding.
class LedgerSealCeremony extends StatefulWidget {
  const LedgerSealCeremony({
    super.key,
    required this.entryLabel,
    required this.amount,
    this.currency = 'EUR',
    this.onComplete,
    this.autoPlay = true,
  });

  /// What's being sealed (e.g. 'GROCERIES · CARREFOUR').
  final String entryLabel;

  /// Amount being sealed (string, already formatted).
  final String amount;

  /// Currency symbol/code displayed on the ledger.
  final String currency;

  final VoidCallback? onComplete;

  /// If false, caller must call `play()` via a controller.
  final bool autoPlay;

  @override
  State<LedgerSealCeremony> createState() => _LedgerSealCeremonyState();
}

class _LedgerSealCeremonyState extends State<LedgerSealCeremony>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _hapticFired = false;
  bool _completionFired = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: LedgerSealFrames.completeAt,
    )..addListener(_tick);
    if (widget.autoPlay) {
      _ctrl.forward();
    }
  }

  void _tick() {
    final elapsed = _ctrl.duration! * _ctrl.value;
    final phase = LedgerSealFrames.phaseAt(elapsed);
    // Signature haptic on the press frame.
    if (!_hapticFired && phase == LedgerSealPhase.press) {
      _hapticFired = true;
      HapticFeedback.mediumImpact();
    }
    if (!_completionFired && phase == LedgerSealPhase.complete) {
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
        final phase = LedgerSealFrames.phaseAt(elapsed);
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            return SizedBox.expand(
              child: CustomPaint(
                painter: _LedgerSealPainter(
                  elapsed: elapsed,
                  phase: phase,
                  entryLabel: widget.entryLabel,
                  amount: widget.amount,
                  currency: widget.currency,
                  size: size,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LedgerSealPainter extends CustomPainter {
  _LedgerSealPainter({
    required this.elapsed,
    required this.phase,
    required this.entryLabel,
    required this.amount,
    required this.currency,
    required this.size,
  });

  final Duration elapsed;
  final LedgerSealPhase phase;
  final String entryLabel;
  final String amount;
  final String currency;
  final Size size;

  static const Color _foil = Color(0xFFD4AF37);
  static const Color _foilLight = Color(0xFFE9C75D);

  double _phaseProgress(Duration start, Duration end) {
    final span = (end - start).inMilliseconds;
    if (span <= 0) return 1;
    final elapsedMs = elapsed.inMilliseconds - start.inMilliseconds;
    if (elapsedMs <= 0) return 0;
    if (elapsedMs >= span) return 1;
    return elapsedMs / span;
  }

  @override
  void paint(Canvas canvas, Size canvasSize) {
    // Substrate dim.
    final bg = Paint()..color = const Color(0xFF050505);
    canvas.drawRect(Offset.zero & canvasSize, bg);

    // Ribbon prints across the canvas.
    final ribbonProgress = _phaseProgress(
      LedgerSealFrames.ribbonStart,
      LedgerSealFrames.waxStart,
    );
    if (ribbonProgress > 0) {
      final ribbonW = canvasSize.width * 0.86;
      final ribbonH = 64.0;
      final ribbonLeft = (canvasSize.width - ribbonW) / 2;
      final ribbonTop = canvasSize.height * 0.42;
      final printedWidth = ribbonW * Curves.easeOutCubic.transform(
        ribbonProgress,
      );
      final ribbonRect = Rect.fromLTWH(
        ribbonLeft,
        ribbonTop,
        printedWidth,
        ribbonH,
      );
      final ribbonPaint = Paint()
        ..color = const Color(0xFF11141C).withValues(alpha: 0.92);
      canvas.drawRRect(
        RRect.fromRectAndRadius(ribbonRect, const Radius.circular(8)),
        ribbonPaint,
      );

      // Hairline outline.
      final hairline = Paint()
        ..color = _foil.withValues(alpha: 0.42)
        ..strokeWidth = 0.6
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(
        RRect.fromRectAndRadius(ribbonRect, const Radius.circular(8)),
        hairline,
      );

      // Entry label on the left.
      _drawTextLeft(
        canvas,
        entryLabel.toUpperCase(),
        Offset(ribbonLeft + 16, ribbonTop + ribbonH / 2),
        9.0,
        Colors.white.withValues(alpha: 0.72),
        weight: FontWeight.w800,
        spacing: 1.4,
        opacity: ribbonProgress,
      );

      // Amount on the right.
      if (ribbonProgress > 0.5) {
        final amountOpacity = math.min(
          1.0,
          (ribbonProgress - 0.5) / 0.5,
        );
        _drawTextRight(
          canvas,
          '$amount $currency',
          Offset(
            ribbonLeft + printedWidth - 16,
            ribbonTop + ribbonH / 2,
          ),
          14.0,
          _foilLight,
          weight: FontWeight.w900,
          opacity: amountOpacity,
        );
      }
    }

    // Wax loads onto the seal.
    final waxProgress = _phaseProgress(
      LedgerSealFrames.waxStart,
      LedgerSealFrames.pressStart,
    );
    final sealCenter = Offset(
      canvasSize.width / 2,
      canvasSize.height * 0.28,
    );
    if (waxProgress > 0 && phase.index < LedgerSealPhase.press.index) {
      final waxRadius = 42.0;
      final fillAmount = waxProgress;
      final wax = Paint()
        ..color = Color.lerp(
          _foil.withValues(alpha: 0.16),
          _foil.withValues(alpha: 0.86),
          fillAmount,
        )!;
      canvas.drawCircle(sealCenter, waxRadius, wax);

      // Wax ring.
      final waxRing = Paint()
        ..color = _foilLight.withValues(alpha: 0.42 + 0.5 * fillAmount)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(sealCenter, waxRadius, waxRing);

      // "GID" monogram on the seal.
      _drawTextCentered(
        canvas,
        'GID',
        sealCenter,
        18,
        Colors.white.withValues(alpha: 0.62 * fillAmount + 0.2),
        weight: FontWeight.w900,
        spacing: 1.8,
      );
    }

    // Seal arc-drops + presses.
    final pressProgress = _phaseProgress(
      LedgerSealFrames.pressStart,
      LedgerSealFrames.settleStart,
    );
    if (pressProgress > 0) {
      // Scale 1.45 → 0.96 overshoot.
      final scale = _overshoot(pressProgress);
      final ribbonTop = canvasSize.height * 0.42;
      final landY = ribbonTop + 32;
      final dropY = Tween<double>(
        begin: sealCenter.dy,
        end: landY,
      ).transform(Curves.easeInQuad.transform(pressProgress));
      final pressCenter = Offset(sealCenter.dx, dropY);
      final pressedRadius = 28.0 * scale;
      final inkAlpha = pressProgress < 0.8
          ? 0.92
          : (1 - (pressProgress - 0.8) / 0.2) * 0.92 + 0.42;
      final inkPaint = Paint()
        ..color = _foil.withValues(alpha: inkAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1.2);
      canvas.drawCircle(pressCenter, pressedRadius, inkPaint);

      final inkRing = Paint()
        ..color = _foilLight.withValues(alpha: 0.78)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(pressCenter, pressedRadius, inkRing);

      _drawTextCentered(
        canvas,
        'GID',
        pressCenter,
        16.0 * scale,
        Colors.white.withValues(alpha: 0.92),
        weight: FontWeight.w900,
        spacing: 1.8,
      );
    }

    // Ink bleed + watermark drift.
    final settleProgress = _phaseProgress(
      LedgerSealFrames.settleStart,
      LedgerSealFrames.completeAt,
    );
    if (settleProgress > 0) {
      final ribbonTop = canvasSize.height * 0.42;
      final landY = ribbonTop + 32;
      final settledCenter = Offset(canvasSize.width / 2, landY);

      // Ink bleed (alpha-fading wider radial).
      final bleedRadius = 28.0 + 14.0 * settleProgress;
      final bleedAlpha = 0.42 * (1 - settleProgress);
      final bleed = Paint()
        ..color = _foil.withValues(alpha: bleedAlpha);
      canvas.drawCircle(settledCenter, bleedRadius, bleed);

      // Watermark drift in bottom-right.
      final watermarkOpacity = settleProgress.clamp(0.0, 1.0);
      _drawTextRight(
        canvas,
        'GLOBE \u00b7 ID',
        Offset(canvasSize.width - 16, canvasSize.height - 16),
        9.0,
        Colors.white.withValues(alpha: 0.42 * watermarkOpacity),
        weight: FontWeight.w800,
        spacing: 1.8,
      );

      // SEALED chip top-center.
      final chipOpacity = settleProgress.clamp(0.0, 1.0);
      _drawTextCentered(
        canvas,
        'SEALED \u00b7 ${_timestamp()}',
        Offset(canvasSize.width / 2, canvasSize.height * 0.18),
        9.0,
        _foil.withValues(alpha: 0.86 * chipOpacity),
        weight: FontWeight.w800,
        spacing: 1.8,
      );
    }
  }

  /// Overshoot for the press scale.
  double _overshoot(double t) {
    // Curve from 1.45 at t=0 → ~1.0 at t=0.55 → 0.96 → 1.0 settle.
    // Use cubic ease-out style with overshoot.
    if (t < 0.55) {
      // Decay from 1.45 to 0.96.
      final p = Curves.easeOutCubic.transform(t / 0.55);
      return 1.45 - 0.49 * p;
    } else {
      // Settle 0.96 → 1.0.
      final p = Curves.easeOutCubic.transform((t - 0.55) / 0.45);
      return 0.96 + 0.04 * p;
    }
  }

  String _timestamp() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m UTC';
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

  void _drawTextLeft(
    Canvas canvas,
    String text,
    Offset leftCenter,
    double size,
    Color color, {
    FontWeight weight = FontWeight.w800,
    double spacing = 0,
    double opacity = 1,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withValues(alpha: color.a * opacity),
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
      Offset(leftCenter.dx, leftCenter.dy - tp.height / 2),
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
    double opacity = 1,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withValues(alpha: color.a * opacity),
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
  bool shouldRepaint(_LedgerSealPainter old) =>
      old.elapsed != elapsed || old.phase != phase;
}

/// Standalone screen that hosts the ceremony with a "Play again" CTA.
class LedgerSealCeremonyScreen extends StatefulWidget {
  const LedgerSealCeremonyScreen({super.key});

  @override
  State<LedgerSealCeremonyScreen> createState() =>
      _LedgerSealCeremonyScreenState();
}

class _LedgerSealCeremonyScreenState extends State<LedgerSealCeremonyScreen> {
  int _generation = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: LedgerSealCeremony(
                key: ValueKey<int>(_generation),
                entryLabel: 'GROCERIES \u00b7 CARREFOUR',
                amount: '\u20ac 42.60',
                currency: 'EUR',
              ),
            ),
            // TOP eyebrow.
            Positioned(
              top: 24,
              left: 24,
              child: Os2Text.monoCap(
                'CINEMA \u00b7 15A',
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
            // Replay CTA.
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
                        'REPLAY \u00b7 CEREMONY',
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
