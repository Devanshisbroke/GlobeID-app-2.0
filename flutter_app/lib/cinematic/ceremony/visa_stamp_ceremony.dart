import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../motion/motion.dart' show Haptics;
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';

/// Four-frame ceremony for committing a visa stamp on the bearer
/// page. Each frame is a distinct cinematic moment.
enum VisaStampPhase {
  /// Idle: no stamp visible yet.
  idle,

  /// 0 → 0.23 — ink loads on the stamp face. Color saturates from
  /// muted to full gold-amber as if pressed onto an ink pad.
  inkLoad,

  /// 0.23 → 0.53 — stamp arcs down on a slight wrist-rotation
  /// (-12° → 0°), scaling 1.35 → 1.0 with a faint motion blur.
  arcSwing,

  /// 0.53 → 0.65 — ink press. A gold radial flash blooms outward
  /// from the contact point. Signature haptic fires here.
  pressFlash,

  /// 0.65 → 1.0 — ink bleed settles. Stamp lifts back (1.0 → 0.96
  /// scale), ink fades from full saturation to the final printed
  /// shade, watermark "ENTRY · STAMPED" mono-cap drops below.
  bleedSettle,

  /// 1.0 — committed. Stamp is fully rendered on the page.
  committed,
}

extension VisaStampPhaseX on VisaStampPhase {
  String get handle => switch (this) {
        VisaStampPhase.idle => 'IDLE',
        VisaStampPhase.inkLoad => 'INK · LOAD',
        VisaStampPhase.arcSwing => 'ARC · SWING',
        VisaStampPhase.pressFlash => 'PRESS · FLASH',
        VisaStampPhase.bleedSettle => 'BLEED · SETTLE',
        VisaStampPhase.committed => 'COMMITTED',
      };
}

/// Pure mapping from `0..1` progress to the corresponding stamp
/// ceremony phase. Exposed so tests can verify the ladder without
/// driving a real animation controller.
VisaStampPhase visaPhaseFor(double t) {
  if (t <= 0) return VisaStampPhase.idle;
  if (t < 0.23) return VisaStampPhase.inkLoad;
  if (t < 0.53) return VisaStampPhase.arcSwing;
  if (t < 0.65) return VisaStampPhase.pressFlash;
  if (t < 1.0) return VisaStampPhase.bleedSettle;
  return VisaStampPhase.committed;
}

class VisaStampCeremony extends StatefulWidget {
  const VisaStampCeremony({
    super.key,
    required this.play,
    this.duration = const Duration(milliseconds: 1700),
    this.onCommitted,
    this.country = 'DEU',
    this.purpose = 'TOURIST · 90D',
    this.stampDate = '14 · MAR · 2026',
    this.tone = const Color(0xFFC8932F),
  });

  /// When true the ceremony plays from 0 → 1.
  final bool play;
  final Duration duration;
  final VoidCallback? onCommitted;
  final String country;
  final String purpose;
  final String stampDate;
  final Color tone;

  @override
  State<VisaStampCeremony> createState() => _VisaStampCeremonyState();
}

class _VisaStampCeremonyState extends State<VisaStampCeremony>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _pressFired = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    _c.addListener(_onProgress);
    _c.addStatusListener(_onStatus);
    if (widget.play) _c.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant VisaStampCeremony old) {
    super.didUpdateWidget(old);
    if (widget.duration != old.duration) _c.duration = widget.duration;
    if (widget.play && !old.play) {
      _pressFired = false;
      _c.forward(from: 0);
    } else if (!widget.play && old.play) {
      _c.value = 0;
      _pressFired = false;
    }
  }

  void _onProgress() {
    // Haptic at the start of the press flash frame (0.53).
    if (!_pressFired && _c.value >= 0.53 && _c.value < 0.66) {
      _pressFired = true;
      Haptics.signature();
    }
  }

  void _onStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed) widget.onCommitted?.call();
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
          return Stack(
            alignment: Alignment.center,
            children: [
              // Page substrate (parchment).
              _ParchmentPage(),
              // Stamp print residue (visible from press onward).
              if (t >= 0.53)
                _StampPrint(
                  progress: t,
                  country: widget.country,
                  purpose: widget.purpose,
                  stampDate: widget.stampDate,
                  tone: widget.tone,
                ),
              // Live stamp (hovers in the air during ink-load + swing).
              if (t < 0.65)
                _Stamp(
                  progress: t,
                  country: widget.country,
                  tone: widget.tone,
                ),
              // Press flash radial.
              if (t >= 0.53 && t < 0.78)
                _PressFlash(local: ((t - 0.53) / 0.25).clamp(0.0, 1.0)),
            ],
          );
        },
      ),
    );
  }
}

class _ParchmentPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 380,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF1E8CE), Color(0xFFE5D6A4)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Os2.goldDeep.withValues(alpha: 0.18),
            blurRadius: 32,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Os2Text.monoCap(
              'BEARER · PAGE',
              color: const Color(0xFF6A5314),
              size: Os2.textTiny,
            ),
            const Spacer(),
            Os2Text.watermark(
              'GLOBE · ID',
              color: const Color(0xFF6A5314).withValues(alpha: 0.30),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({
    required this.progress,
    required this.country,
    required this.tone,
  });
  final double progress;
  final String country;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final loadLocal = (progress / 0.23).clamp(0.0, 1.0);
    final swingLocal = ((progress - 0.23) / 0.30).clamp(0.0, 1.0);
    final pressLocal = ((progress - 0.53) / 0.12).clamp(0.0, 1.0);

    // Position: stamp hovers above the page during load,
    // then arcs down + rotates during swing.
    final liftY = -90.0 +
        90.0 * Curves.easeInCubic.transform(swingLocal) +
        2.0 * Curves.easeOutCubic.transform(pressLocal);
    final scale = 1.0 +
        0.35 * (1.0 - Curves.easeOutCubic.transform(swingLocal));
    final rotation = -0.21 *
        (1.0 - Curves.easeOutCubic.transform(swingLocal));

    // Ink saturation builds during inkLoad.
    final saturation = Curves.easeOutCubic.transform(loadLocal);
    final inkColor = Color.lerp(tone.withValues(alpha: 0.42), tone, saturation)!;

    return Transform.translate(
      offset: Offset(0, liftY),
      child: Transform.rotate(
        angle: rotation,
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: inkColor, width: 3),
              color: inkColor.withValues(alpha: 0.10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Os2Text.display(
                  country,
                  color: inkColor,
                  size: 30,
                ),
                const SizedBox(height: 4),
                Os2Text.monoCap(
                  'ENTRY',
                  color: inkColor,
                  size: Os2.textTiny,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StampPrint extends StatelessWidget {
  const _StampPrint({
    required this.progress,
    required this.country,
    required this.purpose,
    required this.stampDate,
    required this.tone,
  });
  final double progress;
  final String country;
  final String purpose;
  final String stampDate;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final bleedLocal = ((progress - 0.65) / 0.35).clamp(0.0, 1.0);
    // Ink starts saturated and "bleeds" into final print color.
    final finalTone = Color.lerp(tone, tone.withValues(alpha: 0.8), bleedLocal)!;
    final opacity = (0.0 + (progress - 0.53).clamp(0.0, 0.47) / 0.47).clamp(0.0, 1.0);
    final lift = 4.0 * (1.0 - Curves.easeOutCubic.transform(bleedLocal));

    return Transform.translate(
      offset: Offset(0, lift),
      child: Opacity(
        opacity: opacity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 124,
              height: 124,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: finalTone, width: 2.4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Os2Text.display(
                    country,
                    color: finalTone,
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Os2Text.monoCap(
                    'ENTRY',
                    color: finalTone,
                    size: Os2.textTiny,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Opacity(
              opacity: Curves.easeOutCubic.transform(bleedLocal),
              child: Column(
                children: [
                  Os2Text.monoCap(
                    purpose,
                    color: finalTone,
                    size: Os2.textTiny,
                  ),
                  const SizedBox(height: 2),
                  Os2Text.monoCap(
                    'STAMPED · $stampDate',
                    color: finalTone.withValues(alpha: 0.78),
                    size: Os2.textTiny,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PressFlash extends StatelessWidget {
  const _PressFlash({required this.local});
  final double local;
  @override
  Widget build(BuildContext context) {
    if (local <= 0 || local >= 1) return const SizedBox.shrink();
    final radius = 60 + 220 * Curves.easeOutCubic.transform(local);
    final opacity = (1.0 - local).clamp(0.0, 1.0);
    return IgnorePointer(
      child: CustomPaint(
        size: Size(radius * 2, radius * 2),
        painter: _PressFlashPainter(radius: radius, opacity: opacity),
      ),
    );
  }
}

class _PressFlashPainter extends CustomPainter {
  _PressFlashPainter({required this.radius, required this.opacity});
  final double radius;
  final double opacity;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Os2.goldLight.withValues(alpha: 0.55 * opacity),
          Os2.goldDeep.withValues(alpha: 0.16 * opacity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _PressFlashPainter old) =>
      old.radius != radius || old.opacity != opacity;
}

/// Visible-for-testing helper computing the swing-easing position
/// of the stamp so a unit test can verify the choreography without
/// driving a real controller. Returns the dy offset (px from page
/// center) the stamp should occupy at progress [t].
double computeStampDy(double t) {
  final swingLocal = ((t - 0.23) / 0.30).clamp(0.0, 1.0);
  final pressLocal = ((t - 0.53) / 0.12).clamp(0.0, 1.0);
  return -90.0 +
      90.0 * Curves.easeInCubic.transform(swingLocal) +
      2.0 * Curves.easeOutCubic.transform(pressLocal);
}

/// Visible-for-testing helper computing the rotation of the stamp
/// at progress [t]. Returns radians.
double computeStampRotation(double t) {
  final swingLocal = ((t - 0.23) / 0.30).clamp(0.0, 1.0);
  return -0.21 * (1.0 - Curves.easeOutCubic.transform(swingLocal));
}

/// `math.pi` re-export so consumers can `import this file` and not
/// have to pull in `dart:math` separately.
const double kPi = math.pi;
