import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cinematic/live/live_primitives.dart';
import '../../nexus/nexus_tokens.dart';

/// ArrivalLive — cinematic arrival hand-off.
///
/// Anatomy:
///
///   • Atmosphere backdrop in emerald (the "you've landed" tone)
///   • Descent banner with altitude / ground-speed strip
///   • Carousel block: animated baggage conveyer with rotating tag,
///     live carousel number + ETA
///   • Transport hand-off chips: TAXI · RIDE · METRO · PRIVATE
///   • Customs status pill + immigration deep-link
///   • Bottom CTAs — "Live navigation" + "Customs"
class ArrivalLiveScreen extends ConsumerStatefulWidget {
  const ArrivalLiveScreen({super.key});

  @override
  ConsumerState<ArrivalLiveScreen> createState() => _ArrivalLiveScreenState();
}

class _ArrivalLiveScreenState extends ConsumerState<ArrivalLiveScreen>
    with TickerProviderStateMixin {
  late final AnimationController _belt;

  @override
  void initState() {
    super.initState();
    _belt = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _belt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const tone = Color(0xFF10B981);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: LiveCanvas(
        tone: tone,
        statusBar: _Header(tone: tone),
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
                label: 'Customs',
                icon: Icons.shield_rounded,
                secondary: true,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/customs');
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
              _DescentBanner(tone: tone),
              const SizedBox(height: N.s4),
              _BaggageBelt(tone: tone, anim: _belt),
              const SizedBox(height: N.s4),
              _TransportRow(tone: tone),
              const SizedBox(height: N.s4),
              _CustomsCard(tone: tone),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.tone});
  final Color tone;
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
                  'LIVE ARRIVAL · NARITA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'UA 837 · WELCOME TO JAPAN',
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
            state: LiveSurfaceState.committed,
            tone: tone,
          ),
        ],
      ),
    );
  }
}

class _DescentBanner extends StatelessWidget {
  const _DescentBanner({required this.tone});
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(N.rCardLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tone.withValues(alpha: 0.18),
            tone.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: tone.withValues(alpha: 0.30), width: 0.6),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Arrival is the "settled" cinematic state — you've
              // landed, the city is yours. Calm 4.2 s breathing.
              BreathingRing(
                tone: tone,
                size: 78,
                duration: LiveSurfaceState.settled.breathingPeriod,
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tone.withValues(alpha: 0.18),
                  border: Border.all(
                    color: tone.withValues(alpha: 0.55),
                    width: 0.6,
                  ),
                ),
                child: const Icon(
                  Icons.airplanemode_active_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ALTITUDE',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Text(
                      '0 FT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: 1.0,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: tone.withValues(alpha: 0.20),
                        border:
                            Border.all(color: tone.withValues(alpha: 0.45)),
                      ),
                      child: const Text(
                        'ON GROUND',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'TAXI · GATE 14 · CARRIER UA',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 1.0,
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

class _BaggageBelt extends StatelessWidget {
  const _BaggageBelt({required this.tone, required this.anim});
  final Color tone;
  final AnimationController anim;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.luggage_rounded, color: tone, size: 18),
              const SizedBox(width: 8),
              const Text(
                'BAGGAGE CAROUSEL C-2',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              Text(
                'ETA 14 MIN',
                style: TextStyle(
                  color: tone,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 80,
            child: AnimatedBuilder(
              animation: anim,
              builder: (_, __) {
                return CustomPaint(
                  size: const Size(double.infinity, 80),
                  painter: _BeltPainter(t: anim.value, tone: tone),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BeltPainter extends CustomPainter {
  _BeltPainter({required this.t, required this.tone});
  final double t;
  final Color tone;
  @override
  void paint(Canvas canvas, Size size) {
    final belt = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 30, size.width, 28), const Radius.circular(14)),
      belt,
    );
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    for (var i = 0; i < 18; i++) {
      final x = (size.width * i / 18 + size.width * t) % size.width;
      canvas.drawLine(Offset(x, 32), Offset(x, 56), tickPaint);
    }
    // Bags.
    for (var i = 0; i < 4; i++) {
      final phase = (t + i * 0.25) % 1.0;
      final x = phase * (size.width + 60) - 30;
      final bag = Rect.fromLTWH(x, 24, 38, 22);
      final bagPaint = Paint()..color = tone.withValues(alpha: 0.85);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bag, const Radius.circular(6)),
        bagPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(bag.left + 14, bag.top - 4, 10, 6),
        Paint()..color = Colors.white.withValues(alpha: 0.40),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BeltPainter old) => old.t != t;
}

class _TransportRow extends StatelessWidget {
  const _TransportRow({required this.tone});
  final Color tone;
  @override
  Widget build(BuildContext context) {
    final items = [
      _Tx('TAXI', '12 MIN', Icons.local_taxi_rounded),
      _Tx('RIDE', '8 MIN', Icons.directions_car_rounded),
      _Tx('METRO', '24 MIN', Icons.train_rounded),
      _Tx('PRIVATE', 'READY', Icons.directions_car_filled_rounded),
    ];
    return SizedBox(
      height: 78,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final it = items[i];
          return GestureDetector(
            onTap: () => HapticFeedback.lightImpact(),
            child: Container(
              width: 130,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: tone.withValues(alpha: 0.08),
                border: Border.all(
                  color: tone.withValues(alpha: 0.28),
                  width: 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(it.icon, color: tone, size: 18),
                  const Spacer(),
                  Text(
                    it.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
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
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Tx {
  const _Tx(this.label, this.eta, this.icon);
  final String label;
  final String eta;
  final IconData icon;
}

class _CustomsCard extends StatelessWidget {
  const _CustomsCard({required this.tone});
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(N.rCard),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_rounded, color: tone, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'CUSTOMS DECLARATION READY',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.4,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'GREEN LANE · NOTHING TO DECLARE',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ],
      ),
    );
  }
}
