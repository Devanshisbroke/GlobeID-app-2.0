import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cinematic/live/live_primitives.dart';
import '../../nexus/nexus_tokens.dart';

/// LiveSystemsHub — cinematic index of every alive system in GlobeID.
///
/// A single OLED canvas surface that hosts a 2-column grid of preview
/// tiles, each:
///   • Wrapped in a hairline panel + tonal disc
///   • Animated holographic ribbon overlay
///   • Tap → routes to the live surface
///
/// Lives at `/live` and is surfaced from Pulse home, Travel tab, and
/// Services. The "alive OS" landing.
class LiveSystemsHubScreen extends ConsumerStatefulWidget {
  const LiveSystemsHubScreen({super.key});

  @override
  ConsumerState<LiveSystemsHubScreen> createState() =>
      _LiveSystemsHubScreenState();
}

class _LiveSystemsHubScreenState extends ConsumerState<LiveSystemsHubScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ambient;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  static const _systems = <_LiveTileMeta>[
    _LiveTileMeta(
      label: 'PASSPORT',
      subtitle: 'Identity · Globe',
      icon: Icons.book_rounded,
      tone: Color(0xFF1E3A8A),
      route: '/passport-live',
    ),
    _LiveTileMeta(
      label: 'BOARDING PASS',
      subtitle: 'Active flight · QR',
      icon: Icons.qr_code_2_rounded,
      tone: Color(0xFF0EA5E9),
      route: '/boarding-pass-live',
    ),
    _LiveTileMeta(
      label: 'VISA',
      subtitle: 'Sealed booklet · MRZ',
      icon: Icons.shield_rounded,
      tone: Color(0xFFE11D48),
      route: '/visa-live/JP',
    ),
    _LiveTileMeta(
      label: 'FOREX',
      subtitle: 'Banknote stack',
      icon: Icons.currency_exchange_rounded,
      tone: Color(0xFF10B981),
      route: '/forex-live',
    ),
    _LiveTileMeta(
      label: 'TRIP TIMELINE',
      subtitle: '9 alive stages',
      icon: Icons.timeline_rounded,
      tone: Color(0xFF6366F1),
      route: '/trip-timeline-live',
    ),
    _LiveTileMeta(
      label: 'IMMIGRATION',
      subtitle: 'eGate · queue',
      icon: Icons.how_to_reg_rounded,
      tone: Color(0xFF06B6D4),
      route: '/immigration-live',
    ),
    _LiveTileMeta(
      label: 'AIRPORT COMPANION',
      subtitle: 'Radar · gate compass',
      icon: Icons.radar_rounded,
      tone: Color(0xFF60A5FA),
      route: '/airport-companion-live',
    ),
    _LiveTileMeta(
      label: 'ARRIVAL',
      subtitle: 'Baggage · transport',
      icon: Icons.flight_land_rounded,
      tone: Color(0xFF10B981),
      route: '/arrival-live',
    ),
    _LiveTileMeta(
      label: 'TRANSIT PASSES',
      subtitle: 'Suica · Pasmo · NFC',
      icon: Icons.nfc_rounded,
      tone: Color(0xFF8B5CF6),
      route: '/transit-passes-live',
    ),
    _LiveTileMeta(
      label: 'LOUNGE',
      subtitle: 'Embossed access',
      icon: Icons.weekend_rounded,
      tone: Color(0xFFD4A574),
      route: '/lounge-live',
    ),
    _LiveTileMeta(
      label: 'COUNTRY INTEL',
      subtitle: 'Dossier · advisory',
      icon: Icons.public_rounded,
      tone: Color(0xFFF59E0B),
      route: '/country-live/JP',
    ),
    _LiveTileMeta(
      label: 'NAVIGATION',
      subtitle: 'Turn-by-turn · modes',
      icon: Icons.alt_route_rounded,
      tone: Color(0xFF2DD4BF),
      route: '/navigation-live',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const heroTone = N.tierGold;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: LiveCanvas(
        tone: heroTone,
        statusBar: _Header(tone: heroTone),
        bottomBar: LiveCta(
          label: 'Take me where I am',
          icon: Icons.my_location_rounded,
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/trip-timeline-live');
          },
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _HeroBlock(tone: heroTone, ambient: _ambient),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: N.s5)),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 80),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 156,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final m = _systems[i];
                    return _LiveTile(meta: m, ambient: _ambient);
                  },
                  childCount: _systems.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveTileMeta {
  const _LiveTileMeta({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.tone,
    required this.route,
  });
  final String label;
  final String subtitle;
  final IconData icon;
  final Color tone;
  final String route;
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
                  'GLOBEID · ALIVE OS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '12 LIVING SURFACES',
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
            icon: Icons.bolt_rounded,
            label: 'ALIVE',
            tone: tone,
            dense: true,
          ),
        ],
      ),
    );
  }
}

class _HeroBlock extends StatelessWidget {
  const _HeroBlock({required this.tone, required this.ambient});
  final Color tone;
  final AnimationController ambient;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(N.rCardLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tone.withValues(alpha: 0.20),
            tone.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: tone.withValues(alpha: 0.32), width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  BreathingRing(tone: tone, size: 86),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tone.withValues(alpha: 0.20),
                      border: Border.all(
                        color: tone.withValues(alpha: 0.55),
                        width: 0.6,
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 26,
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
                      'ALIVE',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.60),
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Every document, ticket, and credential — a living object',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        height: 1.25,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.black.withValues(alpha: 0.32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
                width: 0.5,
              ),
            ),
            child: const LiveTicker(
              items: [
                'PASSPORT · INDIA · VALID 2030',
                'BOARDING UA 837 · GATE B14 · 02:14:35',
                'VISA · JAPAN · 90 DAYS · MULTIPLE ENTRY',
                'TREASURY · \$8,513.23 USD EQ',
                'IMMIGRATION · LANE 2 · 4 MIN WAIT',
                'ARRIVAL · NRT 19:45 JST',
              ],
              tone: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveTile extends StatefulWidget {
  const _LiveTile({required this.meta, required this.ambient});
  final _LiveTileMeta meta;
  final AnimationController ambient;
  @override
  State<_LiveTile> createState() => _LiveTileState();
}

class _LiveTileState extends State<_LiveTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0,
      upperBound: 0.04,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.meta;
    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapCancel: () => _press.reverse(),
      onTap: () {
        HapticFeedback.lightImpact();
        _press.reverse();
        context.push(m.route);
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_press, widget.ambient]),
        builder: (_, __) {
          final scale = 1 - _press.value;
          return Transform.scale(
            scale: scale,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(N.rCardLg),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    m.tone.withValues(alpha: 0.18),
                    m.tone.withValues(alpha: 0.04),
                  ],
                ),
                border: Border.all(
                  color: m.tone.withValues(alpha: 0.32),
                  width: 0.5,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: HolographicFoil(
                      duration: const Duration(seconds: 7),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: m.tone.withValues(alpha: 0.20),
                            border: Border.all(
                              color: m.tone.withValues(alpha: 0.55),
                              width: 0.6,
                            ),
                          ),
                          child: Icon(m.icon, color: m.tone, size: 18),
                        ),
                        const Spacer(),
                        Text(
                          m.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          m.subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.62),
                            fontWeight: FontWeight.w800,
                            fontSize: 10.5,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
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
