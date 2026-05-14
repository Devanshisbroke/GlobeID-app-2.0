import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';

/// Phase 15d — Discover "favorite lock-in" cinematic.
///
/// 2.0 s ceremony that fires when a destination is locked into the
/// favorites set:
///   • 0.00-0.30 s — substrate dim, coin tossed (rises + spins X)
///   • 0.30-0.90 s — coin apex spin (mid-air spin, scale up)
///   • 0.90-1.30 s — coin descends, lands flat (signature impact)
///   • 1.30-2.00 s — seal ring locks in around the coin, country
///     name etches in, watermark drifts, lightImpact on complete
enum FavoriteLockInPhase {
  idle,
  toss,
  apex,
  land,
  lock,
  complete,
}

class FavoriteLockInFrames {
  FavoriteLockInFrames._();

  static const Duration tossStart = Duration.zero;
  static const Duration apexStart = Duration(milliseconds: 300);
  static const Duration landStart = Duration(milliseconds: 900);
  static const Duration lockStart = Duration(milliseconds: 1300);
  static const Duration completeAt = Duration(milliseconds: 2000);

  static FavoriteLockInPhase phaseAt(Duration elapsed) {
    if (elapsed < tossStart) return FavoriteLockInPhase.idle;
    if (elapsed < apexStart) return FavoriteLockInPhase.toss;
    if (elapsed < landStart) return FavoriteLockInPhase.apex;
    if (elapsed < lockStart) return FavoriteLockInPhase.land;
    if (elapsed < completeAt) return FavoriteLockInPhase.lock;
    return FavoriteLockInPhase.complete;
  }
}

class FavoriteLockInCeremony extends StatefulWidget {
  const FavoriteLockInCeremony({
    super.key,
    required this.countryCode,
    required this.countryName,
    this.onComplete,
    this.autoPlay = true,
  });

  /// e.g. 'JP'
  final String countryCode;

  /// e.g. 'JAPAN'
  final String countryName;

  final VoidCallback? onComplete;
  final bool autoPlay;

  @override
  State<FavoriteLockInCeremony> createState() =>
      _FavoriteLockInCeremonyState();
}

class _FavoriteLockInCeremonyState extends State<FavoriteLockInCeremony>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _landHaptic = false;
  bool _lockHaptic = false;
  bool _completionFired = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: FavoriteLockInFrames.completeAt,
    )..addListener(_tick);
    if (widget.autoPlay) {
      _ctrl.forward();
    }
  }

  void _tick() {
    final elapsed = _ctrl.duration! * _ctrl.value;
    final phase = FavoriteLockInFrames.phaseAt(elapsed);
    if (!_landHaptic && phase == FavoriteLockInPhase.land) {
      _landHaptic = true;
      HapticFeedback.mediumImpact();
    }
    if (!_lockHaptic && phase == FavoriteLockInPhase.lock) {
      _lockHaptic = true;
      HapticFeedback.heavyImpact();
    }
    if (!_completionFired && phase == FavoriteLockInPhase.complete) {
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
        final phase = FavoriteLockInFrames.phaseAt(elapsed);
        return SizedBox.expand(
          child: CustomPaint(
            painter: _FavoriteLockInPainter(
              elapsed: elapsed,
              phase: phase,
              countryCode: widget.countryCode,
              countryName: widget.countryName,
            ),
          ),
        );
      },
    );
  }
}

class _FavoriteLockInPainter extends CustomPainter {
  _FavoriteLockInPainter({
    required this.elapsed,
    required this.phase,
    required this.countryCode,
    required this.countryName,
  });

  final Duration elapsed;
  final FavoriteLockInPhase phase;
  final String countryCode;
  final String countryName;

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
    final centerX = size.width / 2;
    final landY = size.height * 0.5;

    final tossP = _phaseProgress(
      FavoriteLockInFrames.tossStart,
      FavoriteLockInFrames.apexStart,
    );
    final apexP = _phaseProgress(
      FavoriteLockInFrames.apexStart,
      FavoriteLockInFrames.landStart,
    );
    final landP = _phaseProgress(
      FavoriteLockInFrames.landStart,
      FavoriteLockInFrames.lockStart,
    );
    final lockP = _phaseProgress(
      FavoriteLockInFrames.lockStart,
      FavoriteLockInFrames.completeAt,
    );

    // Coin position — toss rises to apex, then lands.
    final tossDistance = 80.0;
    final coinY = _coinYAt(tossP, apexP, landP, landY, tossDistance);
    final coinCenter = Offset(centerX, coinY);

    // Spin scaleX — X-axis flip during apex.
    final spinT = (tossP + apexP + landP * 0.25).clamp(0.0, 3.0);
    final spinAngle = spinT * math.pi * 2;
    final coinScaleX = math.cos(spinAngle).abs();
    final coinScaleY = phase == FavoriteLockInPhase.lock
        ? 1.0
        : 0.94 + 0.06 * math.sin(spinAngle * 1.2);

    // Coin size: starts at 36, grows to 52 by apex, lands at 56.
    final coinRadius = 36.0 +
        20.0 * Curves.easeOutCubic.transform(
          (tossP * 0.5 + apexP * 0.5).clamp(0.0, 1.0),
        );

    _drawCoin(
      canvas,
      coinCenter,
      coinRadius,
      coinScaleX: coinScaleX,
      coinScaleY: coinScaleY,
      countryCode: countryCode,
      face: spinAngle % (2 * math.pi) < math.pi,
    );

    // Land impact ring.
    if (landP > 0 && phase.index <= FavoriteLockInPhase.lock.index) {
      final impactRadius = coinRadius + 8 + 18 * landP;
      final impactPaint = Paint()
        ..color = _foil.withValues(alpha: 0.62 * (1 - landP))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      canvas.drawCircle(Offset(centerX, landY), impactRadius, impactPaint);
    }

    // Lock seal ring.
    if (lockP > 0) {
      final lockRadius = coinRadius + 14 +
          4 * Curves.easeOutCubic.transform(lockP);
      final sealPaint = Paint()
        ..color = _foilLight.withValues(alpha: 0.86 * lockP)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawCircle(Offset(centerX, landY), lockRadius, sealPaint);

      // 4 hairline tick marks at NSEW.
      for (var i = 0; i < 4; i++) {
        final angle = i * math.pi / 2;
        final inner = Offset(
          centerX + (lockRadius + 4) * math.cos(angle),
          landY + (lockRadius + 4) * math.sin(angle),
        );
        final outer = Offset(
          centerX + (lockRadius + 12) * math.cos(angle),
          landY + (lockRadius + 12) * math.sin(angle),
        );
        final tick = Paint()
          ..color = _foil.withValues(alpha: 0.78 * lockP)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(inner, outer, tick);
      }

      // Country name etches in below the coin.
      _drawTextCentered(
        canvas,
        countryName.toUpperCase(),
        Offset(centerX, landY + lockRadius + 38),
        14,
        Colors.white.withValues(alpha: 0.92 * lockP),
        weight: FontWeight.w900,
        spacing: 1.8,
      );
      _drawTextCentered(
        canvas,
        'LOCKED IN \u00b7 FAVORITES',
        Offset(centerX, landY + lockRadius + 62),
        9,
        _foil.withValues(alpha: 0.78 * lockP),
        weight: FontWeight.w800,
        spacing: 1.8,
      );
      _drawTextRight(
        canvas,
        'GLOBE \u00b7 ID',
        Offset(size.width - 16, size.height - 16),
        9,
        Colors.white.withValues(alpha: 0.42 * lockP),
        weight: FontWeight.w800,
        spacing: 1.8,
      );
    }
  }

  double _coinYAt(
    double tossP,
    double apexP,
    double landP,
    double landY,
    double tossDistance,
  ) {
    if (tossP > 0 && tossP < 1) {
      // Rising.
      return landY -
          tossDistance * Curves.easeOutQuad.transform(tossP);
    }
    if (apexP > 0 && apexP < 1) {
      // Apex.
      return landY - tossDistance;
    }
    if (landP > 0 && landP < 1) {
      // Descending.
      return landY -
          tossDistance * (1 - Curves.easeInQuad.transform(landP));
    }
    return landY;
  }

  void _drawCoin(
    Canvas canvas,
    Offset center,
    double radius, {
    required double coinScaleX,
    required double coinScaleY,
    required String countryCode,
    required bool face,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(coinScaleX, coinScaleY);

    // Halo.
    final halo = Paint()
      ..color = _foil.withValues(alpha: 0.42)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset.zero, radius * 1.2, halo);

    // Coin body — gradient.
    final body = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_foilLight, _foil],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
    canvas.drawCircle(Offset.zero, radius, body);

    // Hairline ring.
    final ring = Paint()
      ..color = Colors.white.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(Offset.zero, radius - 2, ring);

    // Face — show country code; back — show GID monogram.
    if (face) {
      _drawTextCentered(
        canvas,
        countryCode,
        Offset.zero,
        radius * 0.6,
        Colors.black.withValues(alpha: 0.86),
        weight: FontWeight.w900,
        spacing: 1.4,
      );
    } else {
      _drawTextCentered(
        canvas,
        'GID',
        Offset.zero,
        radius * 0.5,
        Colors.black.withValues(alpha: 0.86),
        weight: FontWeight.w900,
        spacing: 1.6,
      );
    }
    canvas.restore();
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
  bool shouldRepaint(_FavoriteLockInPainter old) =>
      old.elapsed != elapsed || old.phase != phase;
}

class FavoriteLockInCeremonyScreen extends StatefulWidget {
  const FavoriteLockInCeremonyScreen({super.key});

  @override
  State<FavoriteLockInCeremonyScreen> createState() =>
      _FavoriteLockInCeremonyScreenState();
}

class _FavoriteLockInCeremonyScreenState
    extends State<FavoriteLockInCeremonyScreen> {
  int _generation = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: FavoriteLockInCeremony(
                key: ValueKey<int>(_generation),
                countryCode: 'JP',
                countryName: 'JAPAN',
              ),
            ),
            Positioned(
              top: 24,
              left: 24,
              child: Os2Text.monoCap(
                'CINEMA \u00b7 15D',
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
                        'REPLAY \u00b7 LOCK',
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
