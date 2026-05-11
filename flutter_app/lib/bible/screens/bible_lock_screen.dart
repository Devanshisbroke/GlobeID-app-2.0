import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../bible_tokens.dart';
import '../bible_typography.dart';
import '../chrome/bible_buttons.dart';
import '../chrome/bible_pressable.dart';
import '../chrome/bible_widgets.dart';
import '../living/bible_breathing.dart';
import '../materials/bible_atmosphere.dart';

/// GlobeID — **Lock / Emergency** (§11.13 _The Calm Shield_).
///
/// Registers: Stillness, with one Activation path on pull-down to
/// summon the Emergency overlay.
///
/// Centered biometric ring orbiting a faint GlobeID wordmark. Pulling
/// the screen down ≥96 px summons the Emergency overlay — the only
/// place a passive surface fires a heavy haptic.
class BibleLockScreen extends StatefulWidget {
  const BibleLockScreen({super.key});

  @override
  State<BibleLockScreen> createState() => _BibleLockScreenState();
}

class _BibleLockScreenState extends State<BibleLockScreen>
    with TickerProviderStateMixin {
  late final AnimationController _orbit;
  late final AnimationController _greet;
  double _pullDistance = 0;
  bool _emergencyVisible = false;
  bool _scanning = false;
  double _ringFill = 0;

  @override
  void initState() {
    super.initState();
    _orbit = AnimationController(
      vsync: this,
      duration: B.lockOrbit,
    )..repeat();
    _greet = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _orbit.dispose();
    _greet.dispose();
    super.dispose();
  }

  void _startScan() async {
    if (_scanning) return;
    setState(() {
      _scanning = true;
      _ringFill = 0;
    });
    HapticFeedback.lightImpact();
    for (var i = 0; i <= 30; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 60));
      if (!mounted) return;
      setState(() => _ringFill = i / 30);
      if (i % 10 == 0) HapticFeedback.selectionClick();
    }
    HapticFeedback.heavyImpact();
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  void _handlePull(double dy) {
    setState(() {
      _pullDistance = (_pullDistance + dy).clamp(0.0, 200.0);
      if (_pullDistance > 96 && !_emergencyVisible) {
        _emergencyVisible = true;
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _resetPull() {
    setState(() {
      _pullDistance = 0;
      _emergencyVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BibleAtmosphere(
      emotion: BEmotion.stillness,
      tone: B.polarBlue.withValues(alpha: 0.06),
      child: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: (d) => _handlePull(d.delta.dy),
          onVerticalDragEnd: (_) => _resetPull(),
          child: Stack(
            children: [
              // ─────────────── Greeting wordmark
              Positioned(
                top: 56,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _greet,
                  child: Column(
                    children: [
                      BText.eyebrow(
                        '— globeid —',
                        color: B.inkOnDarkLow,
                      ),
                      const SizedBox(height: B.space2),
                      BText.display(
                        _greeting(),
                        size: 22,
                        color: B.inkOnDarkHigh,
                      ),
                    ],
                  ),
                ),
              ),
              // ─────────────── Biometric ring centerpiece
              Center(
                child: BibleBreathing(
                  period: const Duration(seconds: 6),
                  child: _BiometricRing(
                    orbit: _orbit,
                    fill: _ringFill,
                    scanning: _scanning,
                    onTap: _startScan,
                  ),
                ),
              ),
              // ─────────────── System ribbons bottom
              Positioned(
                left: 24,
                right: 24,
                bottom: 28,
                child: _SystemRibbon(),
              ),
              // ─────────────── Pull-down emergency overlay
              if (_pullDistance > 0)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Transform.translate(
                    offset: Offset(0, _pullDistance - 200),
                    child: _EmergencyOverlay(
                      visible: _emergencyVisible,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'Late hours — be well.';
    if (hour < 12) return 'Good morning.';
    if (hour < 18) return 'Good afternoon.';
    return 'Good evening.';
  }
}

class _BiometricRing extends StatelessWidget {
  const _BiometricRing({
    required this.orbit,
    required this.fill,
    required this.scanning,
    required this.onTap,
  });
  final AnimationController orbit;
  final double fill;
  final bool scanning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BiblePressable(
      onTap: onTap,
      scale: 0.94,
      child: SizedBox(
        width: 220,
        height: 220,
        child: AnimatedBuilder(
          animation: orbit,
          builder: (_, __) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Soft glow halo
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        B.polarBlue.withValues(alpha: 0.16),
                        B.polarBlue.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
                // Outer orbit ring (dashed sweep)
                CustomPaint(
                  size: const Size(196, 196),
                  painter: _OrbitPainter(
                    phase: orbit.value,
                    fill: fill,
                    tone: scanning ? B.equatorTeal : B.polarBlue,
                  ),
                ),
                // Inner shield disc
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                    border: Border.all(
                      color: B.hairlineLight,
                      width: 0.6,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    scanning
                        ? Icons.face_retouching_natural_rounded
                        : Icons.fingerprint_rounded,
                    size: 48,
                    color: scanning ? B.equatorTeal : B.polarBlue,
                  ),
                ),
                // Wordmark
                Positioned(
                  bottom: 6,
                  child: BText.monoCap(
                    scanning ? 'scanning…' : 'hold to unlock',
                    color: B.inkOnDarkLow,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter({
    required this.phase,
    required this.fill,
    required this.tone,
  });
  final double phase;
  final double fill;
  final Color tone;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = size.shortestSide / 2 - 4;
    final center = size.center(Offset.zero);

    // Static dim track.
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.06);
    canvas.drawCircle(center, r, track);

    // Sweep arc (orbit).
    final sweep = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: phase * 2 * math.pi,
        endAngle: phase * 2 * math.pi + math.pi * 0.5,
        colors: [
          tone.withValues(alpha: 0),
          tone.withValues(alpha: 0.9),
        ],
      ).createShader(rect);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      phase * 2 * math.pi,
      math.pi * 0.5,
      false,
      sweep,
    );

    // Fill progress (scan).
    if (fill > 0) {
      final scan = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = tone;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        -math.pi / 2,
        2 * math.pi * fill,
        false,
        scan,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter old) =>
      old.phase != phase || old.fill != fill || old.tone != tone;
}

class _SystemRibbon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            BibleStatusPill(
              label: 'fleet',
              value: 'idle',
              tone: B.polarBlue,
              icon: Icons.flight_rounded,
              dense: true,
            ),
            BibleStatusPill(
              label: 'vault',
              value: 'sealed',
              tone: B.foilGold,
              icon: Icons.shield_rounded,
              dense: true,
            ),
            BibleStatusPill(
              label: 'agi',
              value: 'on-standby',
              tone: B.auroraViolet,
              dense: true,
              breathing: true,
            ),
          ],
        ),
        const SizedBox(height: B.space3),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.keyboard_double_arrow_down_rounded,
              size: 14,
              color: B.inkOnDarkLow,
            ),
            const SizedBox(width: B.space1),
            BText.eyebrow(
              'pull down for emergency',
              color: B.inkOnDarkLow,
            ),
          ],
        ),
      ],
    );
  }
}

class _EmergencyOverlay extends StatelessWidget {
  const _EmergencyOverlay({required this.visible});
  final bool visible;
  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: B.dIn,
      opacity: visible ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(B.space5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(B.rSlab),
          color: B.diplomaticGarnet.withValues(alpha: 0.92),
          boxShadow: [
            BoxShadow(
              color: B.diplomaticGarnet.withValues(alpha: 0.55),
              blurRadius: 36,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            BText.eyebrow('emergency overlay', color: B.inkOnDark),
            const SizedBox(height: B.space2),
            BText.display(
              'How may we help, traveller?',
              size: 18,
              color: B.inkOnDark,
              align: TextAlign.center,
            ),
            const SizedBox(height: B.space4),
            Row(
              children: [
                Expanded(
                  child: BibleCinematicButton(
                    label: 'Call consulate',
                    icon: Icons.support_agent_rounded,
                    tone: B.foilGold,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: B.space2),
                Expanded(
                  child: BibleMagneticButton(
                    label: 'Share location',
                    icon: Icons.location_on_rounded,
                    tone: B.snowfieldWhite,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
