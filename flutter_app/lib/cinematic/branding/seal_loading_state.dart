import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../motion/motion.dart';

/// Discrete choreography phases for the [SealLoadingState] ceremony.
///
/// Each phase maps to a distinct moment in the seal-stamping
/// animation. The phase enum is exposed so operators / consumers can
/// read out the current state for instrumentation and tests.
enum SealLoadingPhase {
  idle,
  substrateFade,
  press,
  settle,
  inkBleed,
  marked,
}

/// Pure mapping from `t ∈ [0..1]` → [SealLoadingPhase].
///
/// Boundaries are chosen to give the press phase enough room for an
/// over-shoot (`Curves.easeOutBack`) while leaving the ink-bleed
/// radial enough headroom to read as a real ink ring.
SealLoadingPhase sealLoadingPhaseFor(double t) {
  if (t <= 0) return SealLoadingPhase.idle;
  if (t < 0.18) return SealLoadingPhase.substrateFade;
  if (t < 0.48) return SealLoadingPhase.press;
  if (t < 0.62) return SealLoadingPhase.settle;
  if (t < 0.80) return SealLoadingPhase.inkBleed;
  if (t < 1.0) return SealLoadingPhase.marked;
  return SealLoadingPhase.marked;
}

/// MONO-CAP operator handles for each phase. Used both in the lab
/// operator screen and in tests so they're a stable contract.
const Map<SealLoadingPhase, String> sealLoadingHandles = {
  SealLoadingPhase.idle: 'IDLE · COVER',
  SealLoadingPhase.substrateFade: 'SUBSTRATE · FADE',
  SealLoadingPhase.press: 'PRESS · OVERSHOOT',
  SealLoadingPhase.settle: 'SETTLE · INK',
  SealLoadingPhase.inkBleed: 'BLEED · RADIATE',
  SealLoadingPhase.marked: 'MARKED · GLOBE · ID',
};

/// Computes the scale factor for the seal disc at progress [t].
///
/// Press uses [Curves.easeOutBack] (over-shoot 1.12), settle uses
/// [Curves.easeOutCubic] back to 1.0. Values outside `[0..1]` clamp.
double computeSealScale(double t) {
  if (t <= 0.18) return 0.40;
  if (t <= 0.48) {
    final p = (t - 0.18) / (0.48 - 0.18);
    final eased = Curves.easeOutBack.transform(p.clamp(0.0, 1.0));
    return 0.40 + (1.12 - 0.40) * eased;
  }
  if (t <= 0.62) {
    final p = (t - 0.48) / (0.62 - 0.48);
    final eased = Curves.easeOutCubic.transform(p.clamp(0.0, 1.0));
    return 1.12 + (1.0 - 1.12) * eased;
  }
  return 1.0;
}

/// Computes the ink-bleed radial fraction at progress [t].
///
/// 0 outside the bleed window, 0 → 1 across the window using
/// [Curves.easeOutCubic] so the ink reads as a single rapid pulse
/// rather than a linear ramp.
double computeInkBleedFraction(double t) {
  if (t <= 0.62) return 0.0;
  if (t >= 0.80) return 1.0;
  final p = (t - 0.62) / (0.80 - 0.62);
  return Curves.easeOutCubic.transform(p.clamp(0.0, 1.0));
}

/// Computes the marker-label opacity at progress [t]. Fades in
/// linearly across the `marked` window.
double computeMarkerOpacity(double t) {
  if (t <= 0.80) return 0.0;
  if (t >= 1.0) return 1.0;
  return ((t - 0.80) / 0.20).clamp(0.0, 1.0);
}

/// GlobeID cold-mount seal loading state.
///
/// A 1.6 s cinematic that plays whenever the app needs a brand-grade
/// hold (cold-mount of a Live credential, identity vault hydration,
/// re-issuance attestation). Five phases:
///
///   1. SUBSTRATE · FADE — OLED scrim eases in over 290 ms
///   2. PRESS · OVERSHOOT — gold seal scales 0.40 → 1.12 (easeOutBack)
///   3. SETTLE · INK — seal eases back to 1.00 (easeOutCubic),
///      signature haptic fires at this commit moment
///   4. BLEED · RADIATE — ink ring radiates from the seal edge,
///      fading from 1.0 → 0.0 alpha
///   5. MARKED · GLOBE · ID — mono-cap GLOBE · ID label fades up
///      under the seal
class SealLoadingState extends StatefulWidget {
  const SealLoadingState({
    super.key,
    this.tone = const Color(0xFFD4AF37),
    this.duration = const Duration(milliseconds: 1600),
    this.autoPlay = true,
    this.label = 'GLOBE · ID',
    this.subLabel = 'CRED · LOADING',
    this.diameter = 96,
    this.onSettled,
  });

  /// Foil-gold tone — colours the seal disc, ring, ink-bleed,
  /// monogram, and the bottom label.
  final Color tone;

  /// Total ceremony duration (default 1.6 s).
  final Duration duration;

  /// Whether the ceremony starts playing on mount. Set false for
  /// operator screens that drive playback via a CTA.
  final bool autoPlay;

  /// Top mono-cap label that fades in at the marked frame.
  final String label;

  /// Mono-cap sub-label under [label].
  final String subLabel;

  /// Pixel diameter of the seal disc at scale = 1.0.
  final double diameter;

  /// Callback fired when the seal commits (settle frame).
  final VoidCallback? onSettled;

  @override
  State<SealLoadingState> createState() => SealLoadingStateState();
}

class SealLoadingStateState extends State<SealLoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _hapticFired = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _ctrl.addListener(_maybeFireHaptic);
    if (widget.autoPlay) {
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_maybeFireHaptic);
    _ctrl.dispose();
    super.dispose();
  }

  void _maybeFireHaptic() {
    // Signature haptic fires at the settle commit (t = 0.48).
    if (_hapticFired) return;
    if (_ctrl.value >= 0.48) {
      _hapticFired = true;
      Haptics.signature();
      widget.onSettled?.call();
    }
  }

  /// Play the ceremony from idle → marked.
  Future<void> play() async {
    _hapticFired = false;
    _ctrl
      ..stop()
      ..value = 0;
    await _ctrl.forward();
  }

  /// Reset to idle without playing.
  void reset() {
    _hapticFired = false;
    _ctrl
      ..stop()
      ..value = 0;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        final substrate = (t / 0.18).clamp(0.0, 1.0);
        final scale = computeSealScale(t);
        final bleed = computeInkBleedFraction(t);
        final marker = computeMarkerOpacity(t);
        return Stack(
          alignment: Alignment.center,
          children: [
            // Substrate scrim — OLED black at 0.92 alpha.
            Positioned.fill(
              child: Container(
                color: const Color(0xFF050505)
                    .withValues(alpha: 0.92 * substrate),
              ),
            ),
            // Ink-bleed radial — soft gold halo that radiates from
            // the seal edge and fades to zero.
            if (bleed > 0)
              IgnorePointer(
                child: Container(
                  width: widget.diameter * (1.0 + bleed * 0.85),
                  height: widget.diameter * (1.0 + bleed * 0.85),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.tone.withValues(alpha: 0.0),
                        widget.tone.withValues(alpha: 0.22 * (1 - bleed)),
                        widget.tone.withValues(alpha: 0.0),
                      ],
                      stops: const [0.55, 0.78, 1.0],
                    ),
                  ),
                ),
              ),
            // Seal disc — scales with overshoot.
            Transform.scale(
              scale: scale,
              child: _SealDisc(
                tone: widget.tone,
                diameter: widget.diameter,
              ),
            ),
            // Top label + sub-label — fade in at marked frame.
            Positioned(
              bottom: 24,
              child: Opacity(
                opacity: marker,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.tone.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3.2,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subLabel,
                      style: const TextStyle(
                        color: Color(0xFF8A8A92),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SealDisc extends StatelessWidget {
  const _SealDisc({required this.tone, required this.diameter});
  final Color tone;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.18, -0.22),
          radius: 0.85,
          colors: [
            tone.withValues(alpha: 0.95),
            HSLColor.fromColor(tone)
                .withLightness(0.36)
                .toColor()
                .withValues(alpha: 0.92),
            HSLColor.fromColor(tone)
                .withLightness(0.18)
                .toColor()
                .withValues(alpha: 0.94),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
        border: Border.all(
          color: tone.withValues(alpha: 0.6),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: tone.withValues(alpha: 0.42),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _SealMonogramPainter(tone: tone),
        child: Center(
          child: Text(
            'G·ID',
            style: TextStyle(
              color: HSLColor.fromColor(tone)
                  .withLightness(0.14)
                  .toColor(),
              fontSize: diameter * 0.26,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _SealMonogramPainter extends CustomPainter {
  _SealMonogramPainter({required this.tone});
  final Color tone;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2;
    // Outer hairline ring at 78 % radius.
    final ring = Paint()
      ..color = HSLColor.fromColor(tone)
          .withLightness(0.20)
          .toColor()
          .withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, r * 0.78, ring);
    // Eight notches around the ring like a wax seal die.
    final notch = Paint()
      ..color = HSLColor.fromColor(tone)
          .withLightness(0.22)
          .toColor()
          .withValues(alpha: 0.62)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi - math.pi / 2;
      final p = center +
          Offset(math.cos(angle) * r * 0.88, math.sin(angle) * r * 0.88);
      canvas.drawCircle(p, 1.4, notch);
    }
  }

  @override
  bool shouldRepaint(_SealMonogramPainter old) => old.tone != tone;
}
