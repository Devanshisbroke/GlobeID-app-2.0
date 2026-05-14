import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../motion/motion.dart' show Haptics;
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';

/// Country dossier "DECLASSIFIED" ceremony phases. A top-secret
/// folder cover lifts, three red CLASSIFIED stamps strike with
/// a wrist-rotation bounce, and the dossier body fades in
/// beneath. Signature haptic on the final stamp strike.
enum DeclassifiedPhase {
  idle,
  coverLift,
  stampOne,
  stampTwo,
  stampThree,
  dossierReveal,
  declassified,
}

extension DeclassifiedPhaseX on DeclassifiedPhase {
  String get handle => switch (this) {
        DeclassifiedPhase.idle => 'IDLE',
        DeclassifiedPhase.coverLift => 'COVER · LIFT',
        DeclassifiedPhase.stampOne => 'STAMP · ONE',
        DeclassifiedPhase.stampTwo => 'STAMP · TWO',
        DeclassifiedPhase.stampThree => 'STAMP · THREE',
        DeclassifiedPhase.dossierReveal => 'DOSSIER · REVEAL',
        DeclassifiedPhase.declassified => 'DECLASSIFIED',
      };
}

DeclassifiedPhase declassifiedPhaseFor(double t) {
  if (t <= 0) return DeclassifiedPhase.idle;
  if (t < 0.18) return DeclassifiedPhase.coverLift;
  if (t < 0.40) return DeclassifiedPhase.stampOne;
  if (t < 0.55) return DeclassifiedPhase.stampTwo;
  if (t < 0.70) return DeclassifiedPhase.stampThree;
  if (t < 1.0) return DeclassifiedPhase.dossierReveal;
  return DeclassifiedPhase.declassified;
}

/// Visible-for-test: cover lift fraction at progress [t]. Returns
/// 0 → 1 across [0.0, 0.18], then stays at 1 after that.
double computeCoverLift(double t) {
  if (t <= 0) return 0;
  if (t >= 0.18) return 1;
  return Curves.easeOutCubic.transform(t / 0.18);
}

/// Visible-for-test: scale of stamp at index 0/1/2 at progress [t].
/// Each stamp starts at 0, scales up to 1.45 overshoot, then
/// settles back to 1.0.
double computeStampScale(int index, double t) {
  // Stamp anchor centres: 0.25, 0.48, 0.63.
  final start = [0.20, 0.40, 0.55][index];
  final end = [0.40, 0.55, 0.70][index];
  if (t < start) return 0;
  if (t >= end) return 1.0;
  final local = (t - start) / (end - start);
  if (local < 0.55) {
    return 1.45 * Curves.easeOutBack.transform(local / 0.55);
  }
  final settle = (local - 0.55) / 0.45;
  return 1.45 - 0.45 * Curves.easeOutCubic.transform(settle);
}

class DeclassifiedCeremony extends StatefulWidget {
  const DeclassifiedCeremony({
    super.key,
    required this.play,
    this.duration = const Duration(milliseconds: 3200),
    this.onDeclassified,
    this.country = 'ITALY',
    this.classification = 'TOP · SECRET',
    this.dossierLines = const [
      'CASE · OFFICER · TRAVEL · DESK',
      'BEARER · CLEARED · FOR · ENTRY',
      'ADVISORY · GREEN · LEVEL · 1',
    ],
  });

  final bool play;
  final Duration duration;
  final VoidCallback? onDeclassified;
  final String country;
  final String classification;
  final List<String> dossierLines;

  @override
  State<DeclassifiedCeremony> createState() => _DeclassifiedCeremonyState();
}

class _DeclassifiedCeremonyState extends State<DeclassifiedCeremony>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final _fired = <int>{};
  bool _signatureFired = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    _c.addListener(_onProgress);
    _c.addStatusListener(_onStatus);
    if (widget.play) _c.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant DeclassifiedCeremony old) {
    super.didUpdateWidget(old);
    if (widget.duration != old.duration) _c.duration = widget.duration;
    if (widget.play && !old.play) {
      _fired.clear();
      _signatureFired = false;
      _c.forward(from: 0);
    } else if (!widget.play && old.play) {
      _c.value = 0;
      _fired.clear();
      _signatureFired = false;
    }
  }

  void _onProgress() {
    final t = _c.value;
    const triggers = [0.20, 0.40, 0.55];
    for (var i = 0; i < triggers.length; i++) {
      if (!_fired.contains(i) && t >= triggers[i]) {
        _fired.add(i);
        Haptics.selection();
      }
    }
    if (!_signatureFired && t >= 0.55) {
      _signatureFired = true;
      Haptics.signature();
    }
  }

  void _onStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed) widget.onDeclassified?.call();
  }

  @override
  void dispose() {
    _c.removeListener(_onProgress);
    _c.removeStatusListener(_onStatus);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final lift = computeCoverLift(t);
          final reveal = t >= 0.70 ? ((t - 0.70) / 0.30).clamp(0.0, 1.0) : 0.0;
          return SizedBox(
            width: 300,
            height: 380,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: reveal,
                  child: _DossierBody(
                    country: widget.country,
                    lines: widget.dossierLines,
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, -120 * lift),
                  child: Transform.rotate(
                    angle: -0.12 * lift,
                    child: Opacity(
                      opacity: (1 - lift * 1.2).clamp(0.0, 1.0),
                      child: _DossierCover(
                        country: widget.country,
                        classification: widget.classification,
                      ),
                    ),
                  ),
                ),
                for (var i = 0; i < 3; i++)
                  _PositionedStamp(
                    index: i,
                    scale: computeStampScale(i, t),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DossierCover extends StatelessWidget {
  const _DossierCover({required this.country, required this.classification});
  final String country;
  final String classification;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 380,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F1A12), Color(0xFF0F0B07)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFB73E3E).withValues(alpha: 0.55),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB73E3E).withValues(alpha: 0.18),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFB73E3E),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Os2Text.monoCap(
                classification,
                color: Colors.white,
                size: Os2.textTiny,
              ),
            ),
            const SizedBox(height: 20),
            Os2Text.monoCap(
              'CASE · DOSSIER',
              color: Os2.inkLow,
              size: Os2.textTiny,
            ),
            const SizedBox(height: 6),
            Os2Text.display(
              country,
              color: Os2.inkBright,
              size: Os2.textXl,
            ),
            const Spacer(),
            Container(height: 1, color: const Color(0xFFB73E3E)
                .withValues(alpha: 0.35)),
            const SizedBox(height: 12),
            Os2Text.monoCap(
              'BEARER · EYES · ONLY',
              color: const Color(0xFFB73E3E),
              size: Os2.textTiny,
            ),
            const SizedBox(height: 4),
            Os2Text.monoCap(
              'GLOBE · ID · CASE · OFFICER',
              color: Os2.inkLow,
              size: Os2.textTiny,
            ),
          ],
        ),
      ),
    );
  }
}

class _DossierBody extends StatelessWidget {
  const _DossierBody({required this.country, required this.lines});
  final String country;
  final List<String> lines;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 380,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1F), Color(0xFF0E0E12)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Os2.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Os2Text.monoCap(
              'DECLASSIFIED · DOSSIER',
              color: Os2.goldDeep,
              size: Os2.textTiny,
            ),
            const SizedBox(height: 4),
            Os2Text.display(
              country,
              color: Os2.inkBright,
              size: Os2.textXl,
            ),
            const SizedBox(height: 16),
            for (final line in lines) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Os2Text.monoCap(
                  line,
                  color: Os2.inkMid,
                  size: Os2.textTiny,
                ),
              ),
            ],
            const Spacer(),
            Container(height: 1, color: Os2.hairline),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF2E5A2E),
                  ),
                ),
                const SizedBox(width: 6),
                Os2Text.monoCap(
                  'CLEARED · FOR · BEARER',
                  color: const Color(0xFF2E5A2E),
                  size: Os2.textTiny,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PositionedStamp extends StatelessWidget {
  const _PositionedStamp({required this.index, required this.scale});
  final int index;
  final double scale;
  static const _positions = [
    Offset(-90, -110),
    Offset(60, -40),
    Offset(-30, 80),
  ];
  static const _rotations = [-0.15, 0.08, -0.05];
  @override
  Widget build(BuildContext context) {
    if (scale <= 0) return const SizedBox.shrink();
    final pos = _positions[index];
    return Transform.translate(
      offset: pos,
      child: Transform.scale(
        scale: scale,
        child: Transform.rotate(
          angle: _rotations[index],
          child: CustomPaint(
            painter: _StampPainter(),
            child: Container(
              width: 110,
              height: 64,
              alignment: Alignment.center,
              child: Os2Text.monoCap(
                'CLASSIFIED',
                color: const Color(0xFFB73E3E),
                size: Os2.textXs,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StampPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFFB73E3E)
      ..strokeWidth = 2.5;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final r = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    canvas.drawRRect(r, paint);
    final inner = RRect.fromRectAndRadius(
      rect.deflate(4),
      const Radius.circular(3),
    );
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFFB73E3E).withValues(alpha: 0.65)
      ..strokeWidth = 1.0;
    canvas.drawRRect(inner, innerPaint);
    final dotPaint = Paint()
      ..color = const Color(0xFFB73E3E).withValues(alpha: 0.35);
    final random = math.Random(7 + size.width.toInt());
    for (var i = 0; i < 8; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        0.6,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StampPainter old) => false;
}
