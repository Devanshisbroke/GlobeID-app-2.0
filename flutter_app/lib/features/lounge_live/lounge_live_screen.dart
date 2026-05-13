import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cinematic/live/live_primitives.dart';
import '../../cinematic/live/live_substrates.dart';
import '../../motion/motion.dart';
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
  bool _checkedIn = false;
  DateTime? _checkInAt;

  // Cinematic state of the lounge card. Starts armed (waiting for
  // a check-in tap); commits when the user taps "Check in", then
  // settles after 1.8 s back to active for the rest of the visit.
  LiveSurfaceState _cardState = LiveSurfaceState.armed;

  // Pulse broadcaster — fires over the member card when the user
  // commits a check-in, blooming a tonal halo across the foil.
  final LiveDataPulseController _checkInPulse = LiveDataPulseController();

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
    _checkInPulse.dispose();
    super.dispose();
  }

  /// Cinematic check-in handler — the signature moment when an
  /// Elite member walks past the host.
  ///
  /// First tap commits: triple-pulse haptic + gold pulse over the
  /// member card + persistent "CHECKED IN · hh:mm" badge. The
  /// status ladder ramps armed → committed → active, easing back
  /// to a settled cadence after 1.8 s.
  ///
  /// Second tap (already checked in) routes to the boarding pass.
  void _handleCheckIn() {
    if (!_checkedIn) {
      setState(() {
        _checkedIn = true;
        _checkInAt = DateTime.now();
        _cardState = LiveSurfaceState.committed;
      });
      unawaited(Haptics.signature());
      _checkInPulse.pulse();
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (!mounted) return;
        setState(() => _cardState = LiveSurfaceState.active);
      });
    } else {
      HapticFeedback.lightImpact();
      context.push('/boarding-pass-live');
    }
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
                label: _checkedIn ? 'Checked in · go' : 'Check in',
                icon: _checkedIn
                    ? Icons.verified_rounded
                    : Icons.qr_code_scanner_rounded,
                onTap: _handleCheckIn,
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
        child: LiveMaterialize(
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
                    child: LiveDataPulse(
                      controller: _checkInPulse,
                      tone: const Color(0xFFE9C75D),
                      child: AspectRatio(
                    aspectRatio: 1.58,
                    child: LoungeCardSubstrate(
                      tone: tone,
                      child: Stack(
                        children: [
                          // Subliminal GLOBE·ID watermark drift —
                          // 40 s cycle, alpha 0.035 against the
                          // cognac leather. Below conscious threshold
                          // but the eye reads it as proof of life.
                          const Positioned.fill(
                            child: GlobeIdWatermarkDrift(
                              alpha: 0.035,
                              fontSize: 44,
                              period: Duration(seconds: 48),
                            ),
                          ),
                          // Lounge member card foil — iridescent
                          // for the brushed-foil member tier. The
                          // sweep is tilt-driven so the highlight
                          // follows the user's pan, matching how a
                          // real brushed-foil card catches light.
                          Positioned.fill(
                            child: HolographicFoil(
                              duration: const Duration(seconds: 5),
                              style: HolographicFoilStyle.iridescent,
                              tilt: _tilt,
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
                                    // as a quiet orbit around the
                                    // seal. Each dot is tone-coded to
                                    // its perk's live status (green =
                                    // open / available, amber = waits,
                                    // gold = chef / curated, blue =
                                    // business). The dot count tracks
                                    // the real perks length so the
                                    // halo reads as data-driven, not
                                    // decorative.
                                    NfcPulse(
                                      tone: tone,
                                      size: 64,
                                      child: OrbitalPerks(
                                        radius: 30,
                                        dotSize: 3.2,
                                        tones: [
                                          for (final p in perks)
                                            _perkTone(p.value, tone),
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
                          // status. Pulses with the state glow,
                          // evolving armed → committed → active as
                          // the user checks into the lounge, then
                          // settling to gold once committed.
                          Positioned(
                            top: 12,
                            right: 12,
                            child: LiveStatusPill(
                              state: _cardState,
                              tone: _checkedIn
                                  ? const Color(0xFFE9C75D)
                                  : tone,
                            ),
                          ),
                          // Check-in commit banner — once the user
                          // commits the lounge entry, a faint gold
                          // hairline-framed "CHECKED IN · hh:mm"
                          // anchors the bottom-left so the card
                          // reads as "active and settled".
                          if (_checkedIn && _checkInAt != null)
                            Positioned(
                              left: 18,
                              bottom: 18,
                              child: _CheckedInBadge(at: _checkInAt!),
                            ),
                        ],
                      ),
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

/// Map a perk's live status to a tonal accent so the OrbitalPerks
/// dots read as a data-driven status ring rather than a decorative
/// orbit. Open / available → green; wait windows → amber; curated /
/// chef offerings → gold; otherwise inherit the lounge tone.
Color _perkTone(String status, Color fallback) {
  final s = status.toUpperCase();
  if (s.contains('WAIT')) return const Color(0xFFF59E0B);
  if (s.contains('OPEN') || s.contains('AVAILABLE')) {
    return const Color(0xFF66D29A);
  }
  if (s.contains('CHEF') || s.contains('MENU') || s.contains('CURATED')) {
    return const Color(0xFFE9C75D);
  }
  return fallback;
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

/// CHECKED IN · hh:mm — small hairline-framed badge that pulses
/// once on mount (signature commit) then settles. Stays for the
/// rest of the session so the lounge card reads "actively used".
class _CheckedInBadge extends StatefulWidget {
  const _CheckedInBadge({required this.at});
  final DateTime at;

  @override
  State<_CheckedInBadge> createState() => _CheckedInBadgeState();
}

class _CheckedInBadgeState extends State<_CheckedInBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hh = widget.at.hour.toString().padLeft(2, '0');
    final mm = widget.at.minute.toString().padLeft(2, '0');
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = Curves.easeOutCubic.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 6),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE9C75D).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE9C75D).withValues(alpha: 0.60),
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFFE9C75D),
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              'CHECKED IN · $hh:$mm',
              style: const TextStyle(
                color: Color(0xFFE9C75D),
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
