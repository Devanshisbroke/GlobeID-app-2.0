import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cinematic/live/live_primitives.dart';
import '../../cinematic/live/live_substrates.dart';
import '../../motion/motion.dart';
import '../../nexus/nexus_tokens.dart';

/// NavigationLive — cinematic turn-by-turn / intermodal handoff.
///
/// Anatomy:
///
///   • Atmosphere backdrop in graphite-teal (the maps tone)
///   • Big turn arrow disc (animated heading rotation) + distance to
///     the next maneuver
///   • Turn-by-turn strip — NavStripSubstrate ribbon with dashed
///     centre lane, next step preview, and ETA pill
///   • Intermodal chips (Walk · Metro · Taxi · Rail)
///   • Route summary: from / to / via, ETA, mode
///   • Bottom CTAs — "Boarding pass" + "Country intel"
class NavigationLiveScreen extends ConsumerStatefulWidget {
  const NavigationLiveScreen({super.key});

  @override
  ConsumerState<NavigationLiveScreen> createState() =>
      _NavigationLiveScreenState();
}

class _NavigationLiveScreenState extends ConsumerState<NavigationLiveScreen>
    with TickerProviderStateMixin {
  late final AnimationController _heading;
  late final AnimationController _stripScroll;

  // Live distance to next maneuver, in metres. Counts down on a
  // 1 Hz timer; when it crosses 0 the system fires a signature
  // haptic + LiveDataPulse on the turn disc and cycles to the next
  // maneuver.
  static const _maneuvers = <String>[
    'ONTO NARITA EXPRESS · PLATFORM 4',
    'BOARD NARITA EXPRESS · CAR 6',
    'OFF AT TOKYO STATION · MARUNOUCHI EXIT',
    'WALK 240 M TO AMAN TOKYO',
  ];
  static const _maneuverStarts = <int>[120, 90, 60, 240];
  int _maneuverIdx = 0;
  int _distance = 120;
  int _eta = 64;
  Timer? _tick;
  final _turnPulse = LiveDataPulseController();

  /// Cinematic state of the navigation card. The state ladder
  /// derives from [_distance]:
  ///   >500 m → armed     (cruising, no imminent turn)
  ///   50–500 m → active  (approaching maneuver)
  ///   1–50 m → committed (turn imminent — focus the eye)
  ///    ≤0 m → settled    (turn executed — brief beat then armed)
  LiveSurfaceState get _navState {
    if (_distance <= 0) return LiveSurfaceState.settled;
    if (_distance > 500) return LiveSurfaceState.armed;
    if (_distance > 50) return LiveSurfaceState.active;
    return LiveSurfaceState.committed;
  }

  @override
  void initState() {
    super.initState();
    _heading = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _stripScroll = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _tick = Timer.periodic(const Duration(seconds: 1), _onTick);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  void _onTick(Timer _) {
    if (!mounted) return;
    setState(() {
      // Distance closes at ~5 m/s walking + intermodal scaling.
      _distance = math.max(_distance - 5, 0);
      // ETA closes at 1 min every 18 s so the user sees a real-world
      // descent of ETA without feeling fake.
      if (_distance % 18 == 0 && _eta > 0) _eta -= 1;
    });

    if (_distance == 0) {
      // Cinematic maneuver-commit moment — signature haptic +
      // LiveDataPulse over the turn disc, then advance to the
      // next maneuver after a 1-second settle.
      Haptics.signature();
      _turnPulse.pulse();
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() {
          _maneuverIdx = (_maneuverIdx + 1) % _maneuvers.length;
          _distance = _maneuverStarts[_maneuverIdx];
        });
      });
    } else if (_distance == 50 || _distance == 25) {
      // Selection-tick at threshold crossings (entering the
      // committed band, then the final approach).
      Haptics.snapDetent();
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _heading.dispose();
    _stripScroll.dispose();
    _turnPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const tone = Color(0xFF2DD4BF);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: LiveCanvas(
        tone: tone,
        statusBar: _Header(tone: tone, state: _navState),
        bottomBar: Row(
          children: [
            Expanded(
              child: LiveCta(
                label: 'Boarding',
                icon: Icons.qr_code_2_rounded,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/boarding-pass-live');
                },
              ),
            ),
            const SizedBox(width: N.s3),
            Expanded(
              child: LiveCta(
                label: 'Intel',
                icon: Icons.public_rounded,
                secondary: true,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/country-live/JP');
                },
              ),
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TurnDisc(
                tone: tone,
                heading: _heading,
                distance: _distance,
                maneuver: _maneuvers[_maneuverIdx],
                pulse: _turnPulse,
              ),
              const SizedBox(height: N.s4),
              _NavStrip(tone: tone, scroll: _stripScroll),
              const SizedBox(height: N.s4),
              _RouteSummary(tone: tone, etaMinutes: _eta),
              const SizedBox(height: N.s4),
              _ModesRow(tone: tone),
            ],
          ),
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
                  'LIVE NAVIGATION',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'NRT TERMINAL 1 → AMAN TOKYO',
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

class _TurnDisc extends StatelessWidget {
  const _TurnDisc({
    required this.tone,
    required this.heading,
    required this.distance,
    required this.maneuver,
    required this.pulse,
  });
  final Color tone;
  final AnimationController heading;
  final int distance;
  final String maneuver;
  final LiveDataPulseController pulse;

  /// Derives the cinematic state for the turn disc from the live
  /// distance, mirroring the parent's _navState ladder. Drives the
  /// breathing halo cadence so the disc breathes harder the closer
  /// we get to the maneuver.
  LiveSurfaceState get _state {
    if (distance <= 0) return LiveSurfaceState.settled;
    if (distance > 500) return LiveSurfaceState.armed;
    if (distance > 50) return LiveSurfaceState.active;
    return LiveSurfaceState.committed;
  }

  /// Halo intensity ramp keyed to distance:
  ///   >500 m → calm 0.12
  ///   50–500 m → noticed 0.22
  ///   1–50 m → urgent 0.42
  ///   ≤0 m → bright commit 0.50
  double get _haloAlpha {
    if (distance <= 0) return 0.50;
    if (distance > 500) return 0.12;
    if (distance > 50) return 0.22;
    return 0.42;
  }

  @override
  Widget build(BuildContext context) {
    final urgent = distance > 0 && distance <= 50;
    return LiveDataPulse(
      controller: pulse,
      tone: tone,
      child: BreathingHalo(
        state: _state,
        tone: tone,
        maxAlpha: _haloAlpha,
        expand: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(N.rCardLg),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: urgent
                ? tone.withValues(alpha: 0.42)
                : Colors.white.withValues(alpha: 0.10),
            width: urgent ? 0.8 : 0.5,
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: AnimatedBuilder(
                animation: heading,
                builder: (_, __) {
                  return CustomPaint(
                    painter: _CompassPainter(
                        heading: heading.value * math.pi * 2, tone: tone),
                    child: Center(
                      child: Transform.rotate(
                        angle: math.sin(heading.value * math.pi * 2) * 0.18,
                        child: Icon(
                          Icons.turn_right_rounded,
                          color: tone,
                          size: 76,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Text(
              distance <= 0 ? 'TURN NOW' : 'TURN RIGHT IN',
              style: TextStyle(
                color: distance <= 0
                    ? tone
                    : urgent
                        ? tone.withValues(alpha: 0.95)
                        : Colors.white70,
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              distance <= 0 ? 'GO' : '$distance m',
              style: TextStyle(
                color: urgent || distance <= 0 ? tone : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 32,
                letterSpacing: 1.0,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              maneuver,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontWeight: FontWeight.w800,
                fontSize: 10,
                letterSpacing: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter({required this.heading, required this.tone});
  final double heading;
  final Color tone;
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 6;
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(c, r, track);
    canvas.drawCircle(c, r - 10, track);
    // Heading indicator arc.
    final arc = Paint()
      ..color = tone.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      heading - 0.18,
      0.36,
      false,
      arc,
    );
    // Cardinal ticks.
    for (var i = 0; i < 12; i++) {
      final a = i / 12 * math.pi * 2;
      final p1 = Offset(c.dx + math.cos(a) * (r - 4), c.dy + math.sin(a) * (r - 4));
      final p2 = Offset(c.dx + math.cos(a) * (r + 2), c.dy + math.sin(a) * (r + 2));
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.20)
          ..strokeWidth = 0.8,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) =>
      old.heading != heading;
}

class _NavStrip extends StatelessWidget {
  const _NavStrip({required this.tone, required this.scroll});
  final Color tone;
  final AnimationController scroll;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: NavStripSubstrate(
        tone: tone,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(Icons.directions_walk_rounded, color: tone, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedBuilder(
                  animation: scroll,
                  builder: (_, __) {
                    return Stack(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Transform.translate(
                            offset: Offset(-scroll.value * 80, 0),
                            child: Row(
                              children: [
                                for (final s in const [
                                  'WALK · 220 m',
                                  'METRO · 8 stops',
                                  'WALK · 90 m',
                                  'TAXI · 6 min',
                                ])
                                  Padding(
                                    padding: const EdgeInsets.only(right: 18),
                                    child: Text(
                                      s,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                            alpha: 0.85),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                        letterSpacing: 1.4,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({required this.tone, required this.etaMinutes});
  final Color tone;
  final int etaMinutes;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(N.rCardLg),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded, color: tone, size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'NARITA TERMINAL 1 · ARRIVALS B',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Text(
                etaMinutes <= 0 ? 'ARRIVED' : 'ETA ${etaMinutes}m',
                style: TextStyle(
                  color: tone,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_pin, color: tone, size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'AMAN TOKYO · OTEMACHI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Text(
                'VIA N’EX',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModesRow extends StatelessWidget {
  const _ModesRow({required this.tone});
  final Color tone;
  @override
  Widget build(BuildContext context) {
    final items = [
      _Mode('WALK', '6 min', Icons.directions_walk_rounded),
      _Mode('TRAIN', 'N’EX 55 min', Icons.train_rounded),
      _Mode('TAXI', '¥ 18,400', Icons.local_taxi_rounded),
      _Mode('PRIVATE', 'BOOKED', Icons.directions_car_rounded),
    ];
    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final it = items[i];
          return Container(
            width: 130,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: tone.withValues(alpha: 0.10),
              border: Border.all(
                color: tone.withValues(alpha: 0.28),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(it.icon, color: tone, size: 18),
                const Spacer(),
                Text(
                  it.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  it.eta,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w800,
                    fontSize: 9.5,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Mode {
  const _Mode(this.label, this.eta, this.icon);
  final String label;
  final String eta;
  final IconData icon;
}
