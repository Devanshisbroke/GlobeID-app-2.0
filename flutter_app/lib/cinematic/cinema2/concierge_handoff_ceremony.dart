import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';

/// Phase 15e — Services "concierge handoff" cinematic.
///
/// 2.6 s ceremony that fires when a concierge service is confirmed:
///   • 0.00-0.40 s — substrate dim, user-side node breathes in (left)
///   • 0.40-1.00 s — request packet travels from user to concierge
///     (gold capsule, parabolic flight + tail)
///   • 1.00-1.40 s — concierge-side node receives + flash
///     (mediumImpact haptic on receive)
///   • 1.40-2.10 s — confirmation seal materializes between the
///     two nodes (heavyImpact haptic on lock-in)
///   • 2.10-2.60 s — service label etches in, watermark drifts,
///     lightImpact on complete
enum ConciergeHandoffPhase {
  idle,
  userNode,
  travel,
  receive,
  seal,
  settle,
  complete,
}

class ConciergeHandoffFrames {
  ConciergeHandoffFrames._();

  static const Duration userNodeStart = Duration.zero;
  static const Duration travelStart = Duration(milliseconds: 400);
  static const Duration receiveStart = Duration(milliseconds: 1000);
  static const Duration sealStart = Duration(milliseconds: 1400);
  static const Duration settleStart = Duration(milliseconds: 2100);
  static const Duration completeAt = Duration(milliseconds: 2600);

  static ConciergeHandoffPhase phaseAt(Duration elapsed) {
    if (elapsed < userNodeStart) return ConciergeHandoffPhase.idle;
    if (elapsed < travelStart) return ConciergeHandoffPhase.userNode;
    if (elapsed < receiveStart) return ConciergeHandoffPhase.travel;
    if (elapsed < sealStart) return ConciergeHandoffPhase.receive;
    if (elapsed < settleStart) return ConciergeHandoffPhase.seal;
    if (elapsed < completeAt) return ConciergeHandoffPhase.settle;
    return ConciergeHandoffPhase.complete;
  }
}

class ConciergeHandoffCeremony extends StatefulWidget {
  const ConciergeHandoffCeremony({
    super.key,
    required this.serviceLabel,
    this.onComplete,
    this.autoPlay = true,
  });

  /// e.g. 'PRIVATE DRIVER · 09:40'
  final String serviceLabel;

  final VoidCallback? onComplete;
  final bool autoPlay;

  @override
  State<ConciergeHandoffCeremony> createState() =>
      _ConciergeHandoffCeremonyState();
}

class _ConciergeHandoffCeremonyState extends State<ConciergeHandoffCeremony>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _receiveHaptic = false;
  bool _sealHaptic = false;
  bool _completionFired = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: ConciergeHandoffFrames.completeAt,
    )..addListener(_tick);
    if (widget.autoPlay) {
      _ctrl.forward();
    }
  }

  void _tick() {
    final elapsed = _ctrl.duration! * _ctrl.value;
    final phase = ConciergeHandoffFrames.phaseAt(elapsed);
    if (!_receiveHaptic && phase == ConciergeHandoffPhase.receive) {
      _receiveHaptic = true;
      HapticFeedback.mediumImpact();
    }
    if (!_sealHaptic && phase == ConciergeHandoffPhase.seal) {
      _sealHaptic = true;
      HapticFeedback.heavyImpact();
    }
    if (!_completionFired && phase == ConciergeHandoffPhase.complete) {
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
        final phase = ConciergeHandoffFrames.phaseAt(elapsed);
        return SizedBox.expand(
          child: CustomPaint(
            painter: _ConciergeHandoffPainter(
              elapsed: elapsed,
              phase: phase,
              serviceLabel: widget.serviceLabel,
            ),
          ),
        );
      },
    );
  }
}

class _ConciergeHandoffPainter extends CustomPainter {
  _ConciergeHandoffPainter({
    required this.elapsed,
    required this.phase,
    required this.serviceLabel,
  });

  final Duration elapsed;
  final ConciergeHandoffPhase phase;
  final String serviceLabel;

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
    final userX = size.width * 0.22;
    final conciergeX = size.width * 0.78;

    final userP = _phaseProgress(
      ConciergeHandoffFrames.userNodeStart,
      ConciergeHandoffFrames.travelStart,
    );
    final travelP = _phaseProgress(
      ConciergeHandoffFrames.travelStart,
      ConciergeHandoffFrames.receiveStart,
    );
    final receiveP = _phaseProgress(
      ConciergeHandoffFrames.receiveStart,
      ConciergeHandoffFrames.sealStart,
    );
    final sealP = _phaseProgress(
      ConciergeHandoffFrames.sealStart,
      ConciergeHandoffFrames.settleStart,
    );
    final settleP = _phaseProgress(
      ConciergeHandoffFrames.settleStart,
      ConciergeHandoffFrames.completeAt,
    );

    // Hairline track between nodes.
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = 0.6;
    canvas.drawLine(
      Offset(userX, centerY),
      Offset(conciergeX, centerY),
      track,
    );

    // User-side node (left).
    final userAlpha = Curves.easeOutCubic.transform(userP.clamp(0.0, 1.0));
    _drawNode(
      canvas,
      Offset(userX, centerY),
      'YOU',
      tone: _foil,
      alpha: userAlpha,
      pulse: phase == ConciergeHandoffPhase.userNode ? userP : 1,
    );

    // Concierge-side node (right).
    final conciergeAlpha = Curves.easeOutCubic.transform(
      ((userP + travelP * 0.6).clamp(0.0, 1.0)),
    );
    _drawNode(
      canvas,
      Offset(conciergeX, centerY),
      'GID',
      tone: _foilLight,
      alpha: conciergeAlpha,
      pulse: phase == ConciergeHandoffPhase.receive ? 1 + receiveP * 0.4 : 1,
    );

    // Packet traveling from user → concierge with parabolic arc.
    if (travelP > 0 && travelP < 1.0) {
      final t = Curves.easeInOutCubic.transform(travelP);
      final px = userX + (conciergeX - userX) * t;
      final arc = math.sin(t * math.pi) * 38;
      final py = centerY - arc;
      _drawPacket(canvas, Offset(px, py));

      // Tail — 4 trailing dots.
      for (var i = 1; i <= 4; i++) {
        final tt = (t - i * 0.05).clamp(0.0, 1.0);
        if (tt <= 0) continue;
        final tx = userX + (conciergeX - userX) * tt;
        final ta = math.sin(tt * math.pi) * 38;
        final ty = centerY - ta;
        final tail = Paint()
          ..color = _foil.withValues(alpha: 0.36 - i * 0.06)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(Offset(tx, ty), 4 - i * 0.6, tail);
      }
    }

    // Receive flash on concierge node.
    if (receiveP > 0 && phase.index <= ConciergeHandoffPhase.seal.index) {
      final flashRadius = 28 + 20 * receiveP;
      final flash = Paint()
        ..color = _foilLight.withValues(alpha: 0.62 * (1 - receiveP))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      canvas.drawCircle(Offset(conciergeX, centerY), flashRadius, flash);
    }

    // Confirmation seal between the nodes.
    if (sealP > 0) {
      final sealX = (userX + conciergeX) / 2;
      final sealRadius = 16.0 + 18 * Curves.easeOutCubic.transform(sealP);
      _drawSeal(canvas, Offset(sealX, centerY), sealRadius, sealP);
    }
    if (settleP > 0) {
      final sealX = (userX + conciergeX) / 2;
      _drawSeal(canvas, Offset(sealX, centerY), 34.0, 1.0);

      // Service label etches in below the seal.
      _drawTextCentered(
        canvas,
        serviceLabel.toUpperCase(),
        Offset(size.width / 2, centerY + 78),
        14,
        Colors.white.withValues(alpha: 0.92 * settleP),
        weight: FontWeight.w900,
        spacing: 1.8,
      );
      _drawTextCentered(
        canvas,
        'CONFIRMED \u00b7 CONCIERGE',
        Offset(size.width / 2, centerY + 102),
        9,
        _foil.withValues(alpha: 0.78 * settleP),
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

  void _drawNode(
    Canvas canvas,
    Offset center,
    String glyph, {
    required Color tone,
    required double alpha,
    double pulse = 1,
  }) {
    final radius = 22.0 * pulse;
    // Halo.
    final halo = Paint()
      ..color = tone.withValues(alpha: 0.42 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, radius * 1.4, halo);

    // Body.
    final body = Paint()
      ..color = const Color(0xFF11141C).withValues(alpha: 0.92 * alpha);
    canvas.drawCircle(center, radius, body);

    // Hairline ring.
    final ring = Paint()
      ..color = tone.withValues(alpha: 0.86 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius, ring);

    // Glyph.
    _drawTextCentered(
      canvas,
      glyph,
      center,
      11,
      Colors.white.withValues(alpha: 0.92 * alpha),
      weight: FontWeight.w900,
      spacing: 1.8,
    );
  }

  void _drawPacket(Canvas canvas, Offset center) {
    final body = Paint()
      ..color = _foilLight.withValues(alpha: 0.92)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center, 7, body);
    final core = Paint()..color = _foilLight;
    canvas.drawCircle(center, 4, core);
  }

  void _drawSeal(
    Canvas canvas,
    Offset center,
    double radius,
    double alpha,
  ) {
    final outer = Paint()
      ..color = _foil.withValues(alpha: 0.92 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(center, radius, outer);

    final inner = Paint()
      ..color = _foilLight.withValues(alpha: 0.86 * alpha);
    canvas.drawCircle(center, radius * 0.42, inner);

    // 8 tick marks around the seal.
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final inn = Offset(
        center.dx + (radius + 3) * math.cos(angle),
        center.dy + (radius + 3) * math.sin(angle),
      );
      final out = Offset(
        center.dx + (radius + 8) * math.cos(angle),
        center.dy + (radius + 8) * math.sin(angle),
      );
      final tick = Paint()
        ..color = _foil.withValues(alpha: 0.62 * alpha)
        ..strokeWidth = 1.0;
      canvas.drawLine(inn, out, tick);
    }
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
  bool shouldRepaint(_ConciergeHandoffPainter old) =>
      old.elapsed != elapsed || old.phase != phase;
}

class ConciergeHandoffCeremonyScreen extends StatefulWidget {
  const ConciergeHandoffCeremonyScreen({super.key});

  @override
  State<ConciergeHandoffCeremonyScreen> createState() =>
      _ConciergeHandoffCeremonyScreenState();
}

class _ConciergeHandoffCeremonyScreenState
    extends State<ConciergeHandoffCeremonyScreen> {
  int _generation = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: ConciergeHandoffCeremony(
                key: ValueKey<int>(_generation),
                serviceLabel: 'PRIVATE DRIVER \u00b7 09:40',
              ),
            ),
            Positioned(
              top: 24,
              left: 24,
              child: Os2Text.monoCap(
                'CINEMA \u00b7 15E',
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
                        'REPLAY \u00b7 HANDOFF',
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
