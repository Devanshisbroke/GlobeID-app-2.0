import 'package:flutter/material.dart';

import '../../motion/motion.dart' show Haptics;
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';

/// Cinematic phases of the passport opening ceremony. Each phase
/// is a distinct visual moment the ceremony walks through.
enum PassportCeremonyPhase {
  /// Closed: nothing rendered yet (controller idle).
  closed,

  /// 0 → 0.18 — substrate dawn. OLED floor lifts a few pixels and
  /// the embossed gold seal fades in centered on the cover.
  substrateDawn,

  /// 0.18 → 0.46 — foil sweep. A 45° gold band travels left → right
  /// across the cover. Watermark drifts in below it.
  foilSweep,

  /// 0.46 → 0.66 — emboss settle. Crest scales 1.06 → 1.0 with a
  /// soft inner shadow. Mono-cap eyebrow / title appear.
  embossSettle,

  /// 0.66 → 1.0 — bearer reveal. Cover lifts upward + tilts back
  /// (-12°) revealing the bearer page beneath. Signature haptic at
  /// the 0.78 mark.
  bearerReveal,

  /// 1.0 — settled. The bearer is fully visible; the cover sits
  /// at -22° behind. Ceremony is done.
  settled,
}

extension PassportCeremonyPhaseX on PassportCeremonyPhase {
  String get handle => switch (this) {
        PassportCeremonyPhase.closed => 'CLOSED',
        PassportCeremonyPhase.substrateDawn => 'SUBSTRATE · DAWN',
        PassportCeremonyPhase.foilSweep => 'FOIL · SWEEP',
        PassportCeremonyPhase.embossSettle => 'EMBOSS · SETTLE',
        PassportCeremonyPhase.bearerReveal => 'BEARER · REVEAL',
        PassportCeremonyPhase.settled => 'SETTLED',
      };
}

/// Maps a `0..1` progress value to the active [PassportCeremonyPhase].
/// Exposed as a top-level pure function so tests can verify the
/// phase ladder without driving a real animation controller.
PassportCeremonyPhase phaseFor(double t) {
  if (t <= 0) return PassportCeremonyPhase.closed;
  if (t < 0.18) return PassportCeremonyPhase.substrateDawn;
  if (t < 0.46) return PassportCeremonyPhase.foilSweep;
  if (t < 0.66) return PassportCeremonyPhase.embossSettle;
  if (t < 1.0) return PassportCeremonyPhase.bearerReveal;
  return PassportCeremonyPhase.settled;
}

/// Passport Opening Ceremony — a 3-second cinematic that plays the
/// first time the user opens their Live Passport.
///
/// The ceremony walks through five visual phases (substrate dawn →
/// foil sweep → emboss settle → bearer reveal → settled) with one
/// `Haptics.signature()` fired at the 0.78 mark. The host owns the
/// trigger (this widget does not assume "first ever open" state);
/// it just plays from 0 → 1 when [play] becomes true.
///
/// Phases are pure functions of [progress], so a test can drive
/// the controller directly and assert the right phase / opacity /
/// scale at every milestone without timing flakiness.
class PassportOpeningCeremony extends StatefulWidget {
  const PassportOpeningCeremony({
    super.key,
    required this.play,
    required this.bearer,
    this.duration = const Duration(milliseconds: 3000),
    this.onSettled,
    this.bearerName = 'BARAI, DEVANSH',
    this.bearerNo = 'IN · BX21 · 8841 · 9027',
    this.expires = '15 · NOV · 2032',
  });

  /// When true the ceremony plays from 0 → 1.
  final bool play;

  /// The widget revealed beneath the cover once the ceremony lands.
  /// Receives no callback — the host wires it up.
  final Widget bearer;

  final Duration duration;
  final VoidCallback? onSettled;
  final String bearerName;
  final String bearerNo;
  final String expires;

  @override
  State<PassportOpeningCeremony> createState() =>
      _PassportOpeningCeremonyState();
}

class _PassportOpeningCeremonyState extends State<PassportOpeningCeremony>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _signatureFired = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    _c.addListener(_handleProgress);
    _c.addStatusListener(_handleStatus);
    if (widget.play) _c.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant PassportOpeningCeremony old) {
    super.didUpdateWidget(old);
    if (widget.duration != old.duration) {
      _c.duration = widget.duration;
    }
    if (widget.play && !old.play) {
      _signatureFired = false;
      _c.forward(from: 0);
    } else if (!widget.play && old.play) {
      _c.value = 0;
      _signatureFired = false;
    }
  }

  void _handleProgress() {
    if (!_signatureFired && _c.value >= 0.78) {
      _signatureFired = true;
      // Signature haptic at the bearer reveal lock-in.
      Haptics.signature();
    }
  }

  void _handleStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed) widget.onSettled?.call();
  }

  @override
  void dispose() {
    _c.removeListener(_handleProgress);
    _c.removeStatusListener(_handleStatus);
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
          final phase = phaseFor(t);
          return Stack(
            fit: StackFit.expand,
            children: [
              // OLED floor + atmospheric haze.
              _AtmosphereLayer(progress: t),
              // Bearer page (revealed once the cover lifts).
              if (phase == PassportCeremonyPhase.bearerReveal ||
                  phase == PassportCeremonyPhase.settled)
                Opacity(
                  opacity: ((t - 0.66) / 0.34).clamp(0.0, 1.0),
                  child: Center(child: widget.bearer),
                ),
              // Cover layer (always until past 0.66).
              Center(
                child: _PassportCover(
                  progress: t,
                  bearerName: widget.bearerName,
                  bearerNo: widget.bearerNo,
                  expires: widget.expires,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AtmosphereLayer extends StatelessWidget {
  const _AtmosphereLayer({required this.progress});
  final double progress;
  @override
  Widget build(BuildContext context) {
    final dawn = (progress / 0.18).clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 1.2,
          colors: [
            Os2.goldDeep.withValues(alpha: 0.08 * dawn),
            const Color(0xFF050505),
            const Color(0xFF030308),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
    );
  }
}

class _PassportCover extends StatelessWidget {
  const _PassportCover({
    required this.progress,
    required this.bearerName,
    required this.bearerNo,
    required this.expires,
  });
  final double progress;
  final String bearerName;
  final String bearerNo;
  final String expires;

  @override
  Widget build(BuildContext context) {
    final t = progress;
    final substrateOpacity = (t / 0.18).clamp(0.0, 1.0);
    final foilLocal = ((t - 0.18) / 0.28).clamp(0.0, 1.0);
    final embossLocal = ((t - 0.46) / 0.20).clamp(0.0, 1.0);
    final liftLocal = ((t - 0.66) / 0.34).clamp(0.0, 1.0);

    // Cover tilts back -22° and scales down to 0.86 as it opens.
    final coverTilt = -0.38 * Curves.easeOutCubic.transform(liftLocal);
    final coverScale = 1.0 - 0.14 * Curves.easeOutCubic.transform(liftLocal);
    final coverY = -60.0 * Curves.easeOutCubic.transform(liftLocal);

    // Emboss settle: subtle scale-down 1.06 → 1.0.
    final embossScale = 1.0 +
        0.06 * (1.0 - Curves.easeOutCubic.transform(embossLocal));

    return Opacity(
      opacity: substrateOpacity,
      child: Transform.translate(
        offset: Offset(0, coverY),
        child: Transform(
          alignment: Alignment.topCenter,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateX(coverTilt)
            ..scaleByDouble(coverScale, coverScale, 1.0, 1.0),
          child: Container(
            width: 280,
            height: 380,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1A1F), Color(0xFF0E0E12)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Os2.goldDeep.withValues(alpha: 0.42),
              ),
              boxShadow: [
                BoxShadow(
                  color: Os2.goldDeep.withValues(alpha: 0.16 * substrateOpacity),
                  blurRadius: 60,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Foil sweep band.
                  _FoilSweepBand(local: foilLocal),
                  // Static crest + chrome.
                  Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Os2Text.watermark(
                          'GLOBE · ID',
                          color: Colors.white.withValues(alpha: 0.55 * substrateOpacity),
                        ),
                        const SizedBox(height: 36),
                        Transform.scale(
                          scale: embossScale,
                          child: _GoldCrest(opacity: substrateOpacity),
                        ),
                        const SizedBox(height: 24),
                        Opacity(
                          opacity: ((t - 0.36) / 0.24).clamp(0.0, 1.0),
                          child: Os2Text.monoCap(
                            'GLOBAL · IDENTITY · PASSPORT',
                            color: Os2.goldDeep,
                            size: Os2.textTiny,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Opacity(
                          opacity: ((t - 0.46) / 0.20).clamp(0.0, 1.0),
                          child: Os2Text.display(
                            bearerName,
                            color: Os2.inkBright,
                            size: Os2.textXl,
                          ),
                        ),
                        const Spacer(),
                        Opacity(
                          opacity: ((t - 0.54) / 0.20).clamp(0.0, 1.0),
                          child: Column(
                            children: [
                              Os2Text.monoCap(
                                bearerNo,
                                color: Os2.inkMid,
                                size: Os2.textTiny,
                              ),
                              const SizedBox(height: 6),
                              Os2Text.monoCap(
                                'EXP · $expires',
                                color: Os2.inkLow,
                                size: Os2.textTiny,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FoilSweepBand extends StatelessWidget {
  const _FoilSweepBand({required this.local});
  final double local;
  @override
  Widget build(BuildContext context) {
    if (local <= 0 || local >= 1) return const SizedBox.shrink();
    return Positioned.fill(
      child: CustomPaint(
        painter: _FoilSweepPainter(local: local),
      ),
    );
  }
}

class _FoilSweepPainter extends CustomPainter {
  _FoilSweepPainter({required this.local});
  final double local;
  @override
  void paint(Canvas canvas, Size size) {
    final eased = Curves.easeInOutCubic.transform(local);
    // Band sweeps from x = -size.width to x = size.width * 2.
    final dx = -size.width + (size.width * 2.4) * eased;
    final bandWidth = size.width * 0.55;
    final rect = Rect.fromLTWH(dx, -20, bandWidth, size.height + 40);
    final shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.transparent,
        Os2.goldDeep.withValues(alpha: 0.18),
        Os2.goldLight.withValues(alpha: 0.55),
        Os2.goldDeep.withValues(alpha: 0.18),
        Colors.transparent,
      ],
      stops: const [0, 0.18, 0.5, 0.82, 1.0],
    ).createShader(rect);
    // Rotate 25° so the band cuts at a foil angle.
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-0.42);
    canvas.translate(-size.width / 2, -size.height / 2);
    canvas.drawRect(rect, Paint()..shader = shader);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FoilSweepPainter old) => old.local != local;
}

class _GoldCrest extends StatelessWidget {
  const _GoldCrest({required this.opacity});
  final double opacity;
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Os2.goldLight, Os2.goldDeep],
            stops: [0.0, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Os2.goldDeep.withValues(alpha: 0.45 * opacity),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Os2Text.display(
            'G·ID',
            color: const Color(0xFF050505),
            size: 22,
          ),
        ),
      ),
    );
  }
}

