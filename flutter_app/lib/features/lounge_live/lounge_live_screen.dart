import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cinematic/live/live_primitives.dart';
import '../../cinematic/live/live_substrates.dart';
import '../../nexus/nexus_tokens.dart';

/// LoungeLive — embossed leather lounge card.
///
/// Anatomy:
///
///   • Atmosphere backdrop in deep cognac
///   • LoungeCardSubstrate (leather feel) with embossed crest, gold
///     foil edge, member tier band
///   • Occupancy meter — animated arc filling to current occupancy
///   • Perks block (showers, spa, dining, business)
///   • Live ticker — wait times for showers / cabanas / dining
///   • Bottom CTAs — "Check in" + "Directions"
class LoungeLiveScreen extends ConsumerStatefulWidget {
  const LoungeLiveScreen({super.key, this.loungeId});
  final String? loungeId;

  @override
  ConsumerState<LoungeLiveScreen> createState() => _LoungeLiveScreenState();
}

class _LoungeLiveScreenState extends ConsumerState<LoungeLiveScreen>
    with TickerProviderStateMixin {
  late final AnimationController _foil;
  Offset _tilt = Offset.zero;

  @override
  void initState() {
    super.initState();
    _foil = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _foil.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const tone = Color(0xFFD4A574);
    final perks = [
      _Perk('Showers', '4 OPEN', Icons.shower_rounded),
      _Perk('Dining', 'CHEF MENU', Icons.restaurant_rounded),
      _Perk('Spa', '20 MIN WAIT', Icons.spa_rounded),
      _Perk('Quiet rooms', 'AVAILABLE', Icons.hotel_rounded),
      _Perk('Business', 'OPEN', Icons.work_rounded),
      _Perk('Bar', 'OPEN · 24H', Icons.local_bar_rounded),
    ];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: LiveCanvas(
        tone: tone,
        statusBar: _Header(tone: tone),
        bottomBar: Row(
          children: [
            Expanded(
              child: LiveCta(
                label: 'Check in',
                icon: Icons.qr_code_scanner_rounded,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/boarding-pass-live');
                },
              ),
            ),
            const SizedBox(width: N.s3),
            Expanded(
              child: LiveCta(
                label: 'Directions',
                icon: Icons.alt_route_rounded,
                secondary: true,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/navigation-live');
                },
              ),
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              GestureDetector(
                onPanUpdate: (d) {
                  setState(() {
                    _tilt = Offset(
                      (_tilt.dx + d.delta.dx * 0.02).clamp(-0.4, 0.4),
                      (_tilt.dy + d.delta.dy * 0.02).clamp(-0.4, 0.4),
                    );
                  });
                },
                onPanEnd: (_) => setState(() => _tilt = Offset.zero),
                child: TiltParallax(
                  tilt: _tilt,
                  depth: 6,
                  child: LiveLift(
                    tone: tone,
                    child: AspectRatio(
                    aspectRatio: 1.58,
                    child: LoungeCardSubstrate(
                      tone: tone,
                      child: Stack(
                        children: [
                          // Lounge member card foil — iridescent
                          // for the brushed-foil member tier.
                          Positioned.fill(
                            child: HolographicFoil(
                              duration: const Duration(seconds: 5),
                              style: HolographicFoilStyle.iridescent,
                              child: Container(color: Colors.transparent),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'POLARIS LOUNGE',
                                      style: TextStyle(
                                        color: tone,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        letterSpacing: 2.6,
                                      ),
                                    ),
                                    const Spacer(),
                                    // OVI seal with NFC pulse +
                                    // orbiting perk dots — signals the
                                    // card is "live and ready to tap"
                                    // and broadcasts the active perks
                                    // (shower / dining / spa /
                                    // fast-track) as a quiet orbit
                                    // around the seal.
                                    NfcPulse(
                                      tone: tone,
                                      size: 64,
                                      child: OrbitalPerks(
                                        radius: 30,
                                        dotSize: 3.2,
                                        tones: [
                                          tone,
                                          tone.withValues(alpha: 0.78),
                                          const Color(0xFF66B7FF),
                                          const Color(0xFFE9C75D),
                                        ],
                                        child: OviSeal(
                                          icon: Icons.weekend_rounded,
                                          tone: tone,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  'AARON KUMAR',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ELITE MEMBER · POLARIS · SFO T3',
                                  style: TextStyle(
                                    color: tone.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    letterSpacing: 1.6,
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    Text(
                                      'EXPIRES 2027',
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.55),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10,
                                        letterSpacing: 1.6,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'GLOBEID',
                                      style: TextStyle(
                                        color: tone,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                        letterSpacing: 2.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // GlobeID signature — discreet hairline
                          // gold rule + 9 px monogram pressed into
                          // the corner. Says "manufactured by
                          // GlobeID" without competing for the eye.
                          const GlobeIdSignature(
                            alignment: Alignment.bottomLeft,
                          ),
                          // Live state pill — cinematic ladder
                          // status. Pulses with the state glow.
                          const Positioned(
                            top: 12,
                            right: 12,
                            child: LiveStatusPill(
                              state: LiveSurfaceState.active,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: N.s4),
              _OccupancyCard(tone: tone),
              const SizedBox(height: N.s4),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final p in perks)
                    SizedBox(
                      width: (MediaQuery.of(context).size.width - 16 * 2 - 10) /
                          2,
                      child: _PerkChip(perk: p, tone: tone),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Perk {
  const _Perk(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
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
                  'LIVE LOUNGE · ACCESS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'POLARIS · SFO TERMINAL 3',
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
          StatusPill(
            icon: Icons.verified_rounded,
            label: 'ACTIVE',
            tone: tone,
            dense: true,
          ),
        ],
      ),
    );
  }
}

class _OccupancyCard extends StatefulWidget {
  const _OccupancyCard({required this.tone});
  final Color tone;
  @override
  State<_OccupancyCard> createState() => _OccupancyCardState();
}

class _OccupancyCardState extends State<_OccupancyCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(N.rCardLg),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: AnimatedBuilder(
              animation: _ctl,
              builder: (_, __) {
                return CustomPaint(
                  painter:
                      _OccupancyPainter(progress: _ctl.value * 0.62, tone: widget.tone),
                  child: Center(
                    child: Text(
                      '${(_ctl.value * 62).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0.8,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OCCUPANCY · LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'MODERATELY BUSY',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Seats ~210/320 · cabanas 6/10 · showers 4/12',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                    letterSpacing: 0.4,
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

class _OccupancyPainter extends CustomPainter {
  _OccupancyPainter({required this.progress, required this.tone});
  final double progress;
  final Color tone;
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 6;
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, track);
    final arc = Paint()
      ..color = tone
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -1.57,
      6.283 * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _OccupancyPainter old) =>
      old.progress != progress;
}

class _PerkChip extends StatelessWidget {
  const _PerkChip({required this.perk, required this.tone});
  final _Perk perk;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: tone.withValues(alpha: 0.10),
        border: Border.all(
          color: tone.withValues(alpha: 0.30),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(perk.icon, color: tone, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  perk.label.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10.5,
                    letterSpacing: 1.4,
                  ),
                ),
                Text(
                  perk.value,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w800,
                    fontSize: 9.5,
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
