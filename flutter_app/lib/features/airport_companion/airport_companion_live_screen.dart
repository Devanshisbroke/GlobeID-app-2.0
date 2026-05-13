import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cinematic/live/live_primitives.dart';
import '../../motion/motion.dart';
import '../../nexus/nexus_tokens.dart';

/// AirportCompanionLive — alive terminal radar.
///
/// Anatomy:
///
///   • Atmosphere backdrop in slate-blue (the terminal-night tone)
///   • Centre radar disc: rotating sweep, concentric distance rings,
///     animated POIs (gate, lounge, security, baggage) that drift on
///     each rotation and pulse when intersected by the sweep.
///   • Walk-time compass: gate proximity + walking minutes, rotates
///     gently with each new pull.
///   • Live ticker: SECURITY 4m · GATE B14 4m walk · LOUNGE 3m walk ·
///     BAGGAGE C-2 OPEN.
///   • Bottom CTAs — "Open navigation" + "Boarding pass".
class AirportCompanionLiveScreen extends ConsumerStatefulWidget {
  const AirportCompanionLiveScreen({super.key});

  @override
  ConsumerState<AirportCompanionLiveScreen> createState() =>
      _AirportCompanionLiveScreenState();
}

class _AirportCompanionLiveScreenState
    extends ConsumerState<AirportCompanionLiveScreen>
    with TickerProviderStateMixin {
  late final AnimationController _sweep;

  // Cinematic dwell countdown — minutes-to-boarding. As the value
  // drops, the screen progresses through the state ladder:
  //   >60 m → armed  (cruising the terminal, lounge time)
  //   30–60 → active (you should be heading to the gate)
  //   5–30  → committed (boarding window — get to the gate)
  //   ≤5    → settled  (final call / departing)
  // This drives both the LiveStatusPill in the header and the
  // dwell-countdown HUD that brightens near boarding.
  int _dwellMinutes = 64;
  Timer? _dwellTick;
  bool _windowAnnounced = false;
  final _dwellPulse = LiveDataPulseController();

  LiveSurfaceState get _dwellState {
    if (_dwellMinutes <= 5) return LiveSurfaceState.settled;
    if (_dwellMinutes <= 30) return LiveSurfaceState.committed;
    if (_dwellMinutes <= 60) return LiveSurfaceState.active;
    return LiveSurfaceState.armed;
  }

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    // Tick once every 8 s wall-clock to map to roughly 1 min of
    // simulated dwell descent (so the user perceptibly sees the
    // countdown move during a demo session).
    _dwellTick = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      final prev = _dwellState;
      setState(() {
        if (_dwellMinutes > 0) _dwellMinutes -= 1;
      });
      // Cinematic threshold crossings — one signature haptic
      // when the boarding window opens (active → committed),
      // one when final call begins (committed → settled).
      final now = _dwellState;
      if (prev != now &&
          (now == LiveSurfaceState.committed ||
              now == LiveSurfaceState.settled)) {
        _dwellPulse.pulse();
        if (now == LiveSurfaceState.committed && !_windowAnnounced) {
          _windowAnnounced = true;
          Haptics.signature();
        } else if (now == LiveSurfaceState.settled) {
          Haptics.warning();
        }
      }
    });
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _dwellTick?.cancel();
    _dwellPulse.dispose();
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const tone = Color(0xFF60A5FA);
    const items = [
      'SECURITY · 4M WAIT',
      'GATE B14 · 4M WALK',
      'POLARIS LOUNGE · 3M WALK',
      'BAGGAGE C-2 · OPEN',
      'STARBUCKS · 1M WALK',
    ];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: LiveCanvas(
        tone: tone,
        statusBar: _Header(tone: tone, state: _dwellState),
        bottomBar: Row(
          children: [
            Expanded(
              child: LiveCta(
                label: 'Navigation',
                icon: Icons.alt_route_rounded,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/navigation-live');
                },
              ),
            ),
            const SizedBox(width: N.s3),
            Expanded(
              child: LiveCta(
                label: 'Boarding pass',
                icon: Icons.qr_code_2_rounded,
                secondary: true,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/boarding-pass-live');
                },
              ),
            ),
          ],
        ),
        child: Column(
          children: [
            _CompassRow(tone: tone),
            const SizedBox(height: N.s3),
            _DwellHud(
              tone: tone,
              minutes: _dwellMinutes,
              state: _dwellState,
              pulse: _dwellPulse,
            ),
            const SizedBox(height: N.s3),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Breathing period derives from the live dwell
                  // state: armed (>60 min) at 2.2 s → committed
                  // (5–30 min) at 1.4 s → settled (≤5 min, final
                  // call) at the longest 4.2 s exhale.
                  BreathingRing(
                    tone: tone,
                    size: 320,
                    duration: _dwellState.breathingPeriod,
                  ),
                  _Radar(anim: _sweep, tone: tone),
                ],
              ),
            ),
            const SizedBox(height: N.s4),
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                  width: 0.5,
                ),
              ),
              child: const LiveTicker(items: items, tone: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.tone, required this.state});
  final Color tone;
  final LiveSurfaceState state;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: N.s3),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 0.5,
                ),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: N.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AIRPORT COMPANION · SFO',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'TERMINAL 3 · CONCOURSE C',
                  style: TextStyle(
                    color: tone.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
          LiveStatusPill(
            state: state,
            tone: tone,
          ),
        ],
      ),
    );
  }
}

/// Dwell HUD — the cinematic countdown that brightens as boarding
/// approaches. Idle/armed at >60 min reads as a calm reference card;
/// 30–60 min lights up; <30 min sits in the warm warning band; <5 min
/// burns gold for the final-call moment.
class _DwellHud extends StatelessWidget {
  const _DwellHud({
    required this.tone,
    required this.minutes,
    required this.state,
    required this.pulse,
  });
  final Color tone;
  final int minutes;
  final LiveSurfaceState state;
  final LiveDataPulseController pulse;

  @override
  Widget build(BuildContext context) {
    // Intensity tracks the state ladder so the card glows brighter
    // as boarding approaches. Settled (≤5 min) burns the warmest
    // because that's "FINAL CALL — go to the gate now."
    final double intensity = switch (state) {
      LiveSurfaceState.idle => 0.08,
      LiveSurfaceState.armed => 0.12,
      LiveSurfaceState.active => 0.22,
      LiveSurfaceState.committed => 0.40,
      LiveSurfaceState.settled => 0.62,
    };
    final Color hudTone = state == LiveSurfaceState.settled
        ? const Color(0xFFE9C75D)
        : state == LiveSurfaceState.committed
            ? const Color(0xFFF59E0B)
            : tone;
    final label = state == LiveSurfaceState.settled
        ? 'FINAL CALL'
        : state == LiveSurfaceState.committed
            ? 'BOARDING IN'
            : 'DEPARTURE IN';
    return LiveDataPulse(
      controller: pulse,
      tone: hudTone,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(N.rCardLg),
          color: hudTone.withValues(alpha: 0.06 + intensity * 0.06),
          border: Border.all(
            color: hudTone.withValues(alpha: 0.22 + intensity * 0.32),
            width: 0.6,
          ),
        ),
        child: Row(
          children: [
            Icon(
              state == LiveSurfaceState.settled
                  ? Icons.directions_run_rounded
                  : Icons.flight_takeoff_rounded,
              color: hudTone.withValues(alpha: 0.75 + intensity * 0.25),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(
                          alpha: 0.55 + intensity * 0.30),
                      fontWeight: FontWeight.w900,
                      fontSize: 9,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    minutes <= 0 ? 'DEPARTED' : '$minutes MIN',
                    style: TextStyle(
                      color:
                          hudTone.withValues(alpha: 0.85 + intensity * 0.15),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 1.4,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            // Inline state pill — mirrors the header pill so the HUD
            // is self-contained for users scanning the bottom area.
            LiveStatusPill(state: state, tone: hudTone),
          ],
        ),
      ),
    );
  }
}

class _CompassRow extends StatelessWidget {
  const _CompassRow({required this.tone});
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CompassChip(
            label: 'GATE B14',
            value: '4 MIN',
            icon: Icons.airplanemode_active_rounded,
            tone: tone,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CompassChip(
            label: 'LOUNGE',
            value: '3 MIN',
            icon: Icons.weekend_rounded,
            tone: tone,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CompassChip(
            label: 'SEC.',
            value: '4 MIN',
            icon: Icons.shield_rounded,
            tone: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }
}

class _CompassChip extends StatelessWidget {
  const _CompassChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: tone.withValues(alpha: 0.10),
        border: Border.all(color: tone.withValues(alpha: 0.32), width: 0.6),
      ),
      child: Row(
        children: [
          Icon(icon, color: tone, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w900,
                    fontSize: 8,
                    letterSpacing: 1.4,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1.0,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Radar extends StatelessWidget {
  const _Radar({required this.anim, required this.tone});
  final AnimationController anim;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: AnimatedBuilder(
        animation: anim,
        builder: (_, __) {
          return CustomPaint(
            painter: _RadarPainter(t: anim.value, tone: tone),
          );
        },
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.t, required this.tone});
  final double t;
  final Color tone;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    // Rings.
    for (var i = 1; i <= 3; i++) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.10)
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(c, r * i / 3, paint);
    }
    // Cross hairs.
    final hair = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), hair);
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), hair);
    // Sweep.
    final sweep = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi,
        endAngle: math.pi,
        colors: [
          Colors.transparent,
          tone.withValues(alpha: 0.55),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(t * math.pi * 2);
    canvas.drawCircle(Offset.zero, r, sweep);
    canvas.restore();
    // POIs.
    final pois = [
      _Poi('B14', 0.62, math.pi * 0.18),
      _Poi('SEC', 0.55, math.pi * 1.4),
      _Poi('LNG', 0.40, math.pi * 0.85),
      _Poi('BAG', 0.78, math.pi * 1.65),
    ];
    for (final p in pois) {
      final x = c.dx + math.cos(p.angle) * r * p.distance;
      final y = c.dy + math.sin(p.angle) * r * p.distance;
      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()..color = tone.withValues(alpha: 0.95),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: p.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + 7, y - 5));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => old.t != t;
}

class _Poi {
  const _Poi(this.label, this.distance, this.angle);
  final String label;
  final double distance;
  final double angle;
}
