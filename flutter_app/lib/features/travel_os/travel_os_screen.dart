import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/agentic_chip.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/cinematic_button.dart';
import '../../widgets/cinematic_hero.dart';
import '../../widgets/journey_strip.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../../widgets/section_header.dart';
import '../../widgets/toast.dart';

/// TravelOSScreen — the agentic orchestration hub.
///
/// This is GlobeID's "operating system for travel" — a single screen
/// that visualizes the entire trip lifecycle as one continuous flow
/// and exposes contextual chained actions inline. The screen is built
/// from deterministic, pure-data lifecycle phases (Plan → Pre-flight
/// → Boarding → In-flight → Arrival → Stay → Return), and every
/// phase exposes:
///   • a status pill
///   • the next 3 chained actions (visa / hotel / lounge / etc)
///   • a "promote" CTA that surfaces what to act on now
class TravelOSScreen extends StatefulWidget {
  const TravelOSScreen({super.key});

  @override
  State<TravelOSScreen> createState() => _TravelOSScreenState();
}

class _TravelOSScreenState extends State<TravelOSScreen> {
  int _activePhase =
      1; // 0=Plan, 1=Pre-flight, 2=Board, 3=Fly, 4=Arrive, 5=Stay, 6=Return

  static const _phases = <_Phase>[
    _Phase(
      key: 'plan',
      label: 'Plan',
      icon: Icons.event_note_rounded,
      title: 'Trip planned',
      subtitle: '7 days · Tokyo · 12 Jun',
      summary:
          'Itinerary locked, accommodations preferenced, travel checklist seeded.',
      tone: Color(0xFF6366F1),
    ),
    _Phase(
      key: 'preflight',
      label: 'Pre-flight',
      icon: Icons.assignment_turned_in_rounded,
      title: 'Pre-flight prep',
      subtitle: 'Visa active · checklist 80%',
      summary:
          'Documents are valid. Final 20% of checklist depends on packing weight + lounge selection.',
      tone: Color(0xFF059669),
    ),
    _Phase(
      key: 'board',
      label: 'Board',
      icon: Icons.flight_takeoff_rounded,
      title: 'Boarding',
      subtitle: 'Gate 78A · 09:25 SFO',
      summary:
          'Boarding opens at 08:55. TSA wait is 18 min. You are in zone 3.',
      tone: Color(0xFF0EA5E9),
    ),
    _Phase(
      key: 'fly',
      label: 'In-flight',
      icon: Icons.connecting_airports_rounded,
      title: 'In-flight',
      subtitle: 'UA837 · 11h 05m · 156 kt',
      summary:
          'Cruise altitude. Flight tracker pinned. Wallet is in airplane-safe mode.',
      tone: Color(0xFF1D4ED8),
    ),
    _Phase(
      key: 'arrive',
      label: 'Arrive',
      icon: Icons.flight_land_rounded,
      title: 'Arrival',
      subtitle: 'Narita T1 · Welcome to Japan',
      summary:
          'Immigration kiosk available. eSIM activates on landing. Hotel transfer chained.',
      tone: Color(0xFFEA580C),
    ),
    _Phase(
      key: 'stay',
      label: 'Stay',
      icon: Icons.hotel_rounded,
      title: 'Stay',
      subtitle: 'Aman Tokyo · 7 nights',
      summary:
          'Concierge synced. Local recommendations seeded. Cultural insights ready.',
      tone: Color(0xFF7E22CE),
    ),
    _Phase(
      key: 'return',
      label: 'Return',
      icon: Icons.replay_rounded,
      title: 'Return',
      subtitle: '19 Jun · NRT → CDG',
      summary:
          'Trip memories captured. Multi-leg itinerary continues to Paris.',
      tone: Color(0xFFE11D48),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phase = _phases[_activePhase];
    return PageScaffold(
      title: 'Travel OS',
      subtitle: 'Agentic orchestration · Tokyo · 12 Jun',
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: AnimatedAppearance(
              child: CinematicHero(
                eyebrow: 'AGENTIC ORCHESTRATION',
                title: 'Tokyo journey',
                subtitle:
                    '${phase.title} · ${phase.subtitle}\nGlobeID is chaining your services in the background.',
                icon: phase.icon,
                tone: phase.tone,
                badges: const [
                  HeroBadge(
                      label: 'Live', icon: Icons.fiber_manual_record_rounded),
                  HeroBadge(
                      label: '7 services synced', icon: Icons.hub_rounded),
                  HeroBadge(label: 'Carbon offset', icon: Icons.eco_rounded),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space5)),
          SliverToBoxAdapter(
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space4),
              child: JourneyStrip(
                activeIndex: _activePhase,
                steps: [
                  for (final p in _phases)
                    JourneyStep(label: p.label, icon: p.icon),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Phase navigation',
              subtitle: 'Tap a phase to preview what GlobeID will do',
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 116,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 1),
                itemCount: _phases.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppTokens.space2),
                itemBuilder: (_, i) => _PhaseTile(
                  phase: _phases[i],
                  active: i == _activePhase,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _activePhase = i);
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: phase.title,
              subtitle: phase.summary,
            ),
          ),
          SliverList.separated(
            itemCount: _chainsFor(phase.key).length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppTokens.space2),
            itemBuilder: (_, i) {
              final chain = _chainsFor(phase.key)[i];
              return AnimatedAppearance(
                delay: Duration(milliseconds: 60 * i),
                child: Pressable(
                  scale: 0.985,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (chain.route != null) {
                      GoRouter.of(context).push(chain.route!);
                    } else {
                      AppToast.show(
                        context,
                        title: '${chain.label} · scheduled',
                        tone: AppToastTone.info,
                      );
                    }
                  },
                  child: PremiumCard(
                    padding: const EdgeInsets.all(AppTokens.space4),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: phase.tone.withValues(alpha: 0.16),
                          ),
                          child: Icon(chain.icon, color: phase.tone, size: 18),
                        ),
                        const SizedBox(width: AppTokens.space3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(chain.label,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  )),
                              Text(chain.subtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  )),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: chain.statusTone.withValues(alpha: 0.16),
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusFull),
                          ),
                          child: Text(
                            chain.status,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: chain.statusTone,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.chevron_right_rounded,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space5)),
          SliverToBoxAdapter(
            child: AgenticBand(
              title: 'Promote next',
              chips: _chipsFor(phase.key),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space5)),
          SliverToBoxAdapter(
            child: CinematicButton(
              label: 'Run full sync',
              icon: Icons.bolt_rounded,
              gradient: LinearGradient(
                colors: [phase.tone, phase.tone.withValues(alpha: 0.55)],
              ),
              onPressed: () {
                HapticFeedback.heavyImpact();
                AppToast.show(
                  context,
                  title: 'GlobeID sync',
                  message:
                      '${_chainsFor(phase.key).length} services chained',
                  tone: AppToastTone.success,
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space9)),
        ],
      ),
    );
  }

  List<_Chain> _chainsFor(String key) {
    switch (key) {
      case 'plan':
        return const [
          _Chain(
              icon: Icons.event_note_rounded,
              label: 'Lock itinerary',
              subtitle: 'Tokyo · 7 days · 12 Jun',
              status: 'DONE',
              statusTone: Color(0xFF10B981),
              route: '/planner'),
          _Chain(
              icon: Icons.flight_rounded,
              label: 'Book outbound flight',
              subtitle: 'UA837 · SFO → NRT',
              status: 'HELD',
              statusTone: Color(0xFFD97706),
              route: '/services/flights'),
          _Chain(
              icon: Icons.hotel_rounded,
              label: 'Reserve hotel',
              subtitle: 'Aman Tokyo · 7 nights',
              status: 'PENDING',
              statusTone: Color(0xFF6B7280),
              route: '/services/hotels'),
          _Chain(
              icon: Icons.shield_rounded,
              label: 'Travel insurance',
              subtitle: 'Allianz · 16 days',
              status: 'SUGGESTED',
              statusTone: Color(0xFF7E22CE),
              route: '/services'),
        ];
      case 'preflight':
        return const [
          _Chain(
              icon: Icons.assignment_ind_rounded,
              label: 'Visa · Japan',
              subtitle: 'eVisa active',
              status: 'ACTIVE',
              statusTone: Color(0xFF10B981),
              route: '/identity'),
          _Chain(
              icon: Icons.assignment_turned_in_rounded,
              label: 'Pack checklist',
              subtitle: '12 of 15 done',
              status: 'PROGRESS',
              statusTone: Color(0xFFD97706),
              route: '/planner'),
          _Chain(
              icon: Icons.airline_seat_recline_extra_rounded,
              label: 'Reserve lounge',
              subtitle: 'United Polaris · SFO T3',
              status: 'TAP TO BOOK',
              statusTone: Color(0xFF0EA5E9),
              route: '/services'),
          _Chain(
              icon: Icons.translate_rounded,
              label: 'Phrase pack',
              subtitle: 'JA · arrival · taxi · food',
              status: 'READY',
              statusTone: Color(0xFF6366F1),
              route: '/copilot'),
          _Chain(
              icon: Icons.local_atm_rounded,
              label: 'Currency loaded',
              subtitle: 'JPY 80,000',
              status: 'WALLET',
              statusTone: Color(0xFF7E22CE),
              route: '/multi-currency'),
        ];
      case 'board':
        return const [
          _Chain(
              icon: Icons.flight_takeoff_rounded,
              label: 'Boarding pass',
              subtitle: 'UA837 · 12A · zone 3',
              status: 'LIVE',
              statusTone: Color(0xFF10B981),
              route: '/boarding/trp-001/leg-ua837'),
          _Chain(
              icon: Icons.luggage_rounded,
              label: 'Bag tags',
              subtitle: '2 checked · scanned',
              status: 'TAGGED',
              statusTone: Color(0xFFD97706),
              route: '/wallet'),
          _Chain(
              icon: Icons.airline_seat_recline_extra_rounded,
              label: 'Lounge access',
              subtitle: 'Polaris · gate 78',
              status: 'GO',
              statusTone: Color(0xFF7E22CE),
              route: '/services'),
        ];
      case 'fly':
        return const [
          _Chain(
              icon: Icons.timeline_rounded,
              label: 'Flight tracker',
              subtitle: 'Live altitude · ETA',
              status: 'LIVE',
              statusTone: Color(0xFF10B981),
              route: '/timeline'),
          _Chain(
              icon: Icons.airplanemode_active_rounded,
              label: 'Wallet airplane mode',
              subtitle: 'Local-first · auto-sync on land',
              status: 'ON',
              statusTone: Color(0xFF6366F1),
              route: '/wallet'),
          _Chain(
              icon: Icons.bedtime_rounded,
              label: 'Jet-lag plan',
              subtitle: 'Hydrate · sleep window',
              status: 'TIP',
              statusTone: Color(0xFFD97706),
              route: '/copilot'),
        ];
      case 'arrive':
        return const [
          _Chain(
              icon: Icons.qr_code_rounded,
              label: 'Immigration kiosk',
              subtitle: 'Tap to start',
              status: 'READY',
              statusTone: Color(0xFF10B981),
              route: '/kiosk-sim'),
          _Chain(
              icon: Icons.sim_card_rounded,
              label: 'eSIM · activate',
              subtitle: 'Japan · 5GB · 15 days',
              status: 'AUTO',
              statusTone: Color(0xFF7E22CE),
              route: '/services'),
          _Chain(
              icon: Icons.local_taxi_rounded,
              label: 'Airport pickup',
              subtitle: 'NRT → Aman Tokyo',
              status: 'BOOKED',
              statusTone: Color(0xFFEA580C),
              route: '/services/rides'),
          _Chain(
              icon: Icons.translate_rounded,
              label: 'Welcome to Japan',
              subtitle: 'Phrase: arigatō, sumimasen',
              status: 'GUIDE',
              statusTone: Color(0xFF6366F1),
              route: '/copilot'),
        ];
      case 'stay':
        return const [
          _Chain(
              icon: Icons.hotel_rounded,
              label: 'Hotel concierge',
              subtitle: 'Aman Tokyo · checked in',
              status: 'IN-HOUSE',
              statusTone: Color(0xFF10B981),
              route: '/services/hotels'),
          _Chain(
              icon: Icons.restaurant_rounded,
              label: 'Tonight 19:30',
              subtitle: 'Sushi Saito · 12-course',
              status: 'HOLD',
              statusTone: Color(0xFFD97706),
              route: '/services/food'),
          _Chain(
              icon: Icons.museum_rounded,
              label: 'TeamLab Borderless',
              subtitle: 'Tomorrow 14:00 · skip-the-line',
              status: 'TICKET',
              statusTone: Color(0xFF7E22CE),
              route: '/services/activities'),
          _Chain(
              icon: Icons.directions_subway_rounded,
              label: 'Tokyo metro pass',
              subtitle: 'Loaded · tap-and-go',
              status: 'WALLET',
              statusTone: Color(0xFF0EA5E9),
              route: '/wallet'),
          _Chain(
              icon: Icons.translate_rounded,
              label: 'Cultural insights',
              subtitle: 'Tip rules · etiquette · tipping',
              status: 'READ',
              statusTone: Color(0xFF6366F1),
              route: '/copilot'),
        ];
      case 'return':
      default:
        return const [
          _Chain(
              icon: Icons.flight_takeoff_rounded,
              label: 'NRT → CDG',
              subtitle: 'AF273 · 19 Jun · 12h 40m',
              status: 'NEXT',
              statusTone: Color(0xFFE11D48),
              route: '/services/flights'),
          _Chain(
              icon: Icons.collections_bookmark_rounded,
              label: 'Trip memories',
              subtitle: '128 photos · 12 receipts',
              status: 'CAPTURE',
              statusTone: Color(0xFF7E22CE),
              route: '/timeline'),
          _Chain(
              icon: Icons.eco_rounded,
              label: 'Carbon offset',
              subtitle: '12.4 t CO₂ · offset auto',
              status: 'DONE',
              statusTone: Color(0xFF10B981),
              route: '/analytics'),
        ];
    }
  }

  List<AgenticChip> _chipsFor(String key) {
    switch (key) {
      case 'preflight':
        return const [
          AgenticChip(
              icon: Icons.luggage_rounded,
              label: 'Pack checklist',
              eyebrow: 'do',
              route: '/planner',
              tone: Color(0xFF6366F1)),
          AgenticChip(
              icon: Icons.airline_seat_recline_extra_rounded,
              label: 'Polaris lounge',
              eyebrow: 'reserve',
              route: '/services',
              tone: Color(0xFFD97706)),
          AgenticChip(
              icon: Icons.assignment_ind_rounded,
              label: 'Verify documents',
              eyebrow: 'docs',
              route: '/identity',
              tone: Color(0xFF059669)),
        ];
      case 'arrive':
        return const [
          AgenticChip(
              icon: Icons.qr_code_rounded,
              label: 'Start kiosk',
              eyebrow: 'now',
              route: '/kiosk-sim',
              tone: Color(0xFF10B981)),
          AgenticChip(
              icon: Icons.local_taxi_rounded,
              label: 'Airport ride',
              eyebrow: 'go',
              route: '/services/rides',
              tone: Color(0xFFEA580C)),
          AgenticChip(
              icon: Icons.translate_rounded,
              label: 'Welcome guide',
              eyebrow: 'read',
              route: '/copilot',
              tone: Color(0xFF6366F1)),
        ];
      case 'stay':
        return const [
          AgenticChip(
              icon: Icons.restaurant_rounded,
              label: 'Tonight 19:30',
              eyebrow: 'hold',
              route: '/services/food',
              tone: Color(0xFFD97706)),
          AgenticChip(
              icon: Icons.directions_subway_rounded,
              label: 'Metro pass',
              eyebrow: 'wallet',
              route: '/wallet',
              tone: Color(0xFF0EA5E9)),
          AgenticChip(
              icon: Icons.hiking_rounded,
              label: 'Day trip',
              eyebrow: 'plan',
              route: '/services/activities',
              tone: Color(0xFF7E22CE)),
        ];
      default:
        return const [
          AgenticChip(
              icon: Icons.event_note_rounded,
              label: 'Itinerary',
              route: '/planner',
              tone: Color(0xFF6366F1)),
          AgenticChip(
              icon: Icons.flight_takeoff_rounded,
              label: 'Boarding pass',
              route: '/boarding/trp-001/leg-ua837',
              tone: Color(0xFF0EA5E9)),
          AgenticChip(
              icon: Icons.qr_code_rounded,
              label: 'Open kiosk',
              route: '/kiosk-sim',
              tone: Color(0xFF10B981)),
        ];
    }
  }
}

class _Phase {
  const _Phase({
    required this.key,
    required this.label,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.tone,
  });
  final String key;
  final String label;
  final IconData icon;
  final String title;
  final String subtitle;
  final String summary;
  final Color tone;
}

class _Chain {
  const _Chain({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.status,
    required this.statusTone,
    this.route,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final String status;
  final Color statusTone;
  final String? route;
}

class _PhaseTile extends StatelessWidget {
  const _PhaseTile({
    required this.phase,
    required this.active,
    required this.onTap,
  });
  final _Phase phase;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      scale: 0.95,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTokens.durationSm,
        width: 152,
        padding: const EdgeInsets.all(AppTokens.space3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radius2xl),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: active
                ? [phase.tone, phase.tone.withValues(alpha: 0.55)]
                : [
                    theme.colorScheme.surface.withValues(alpha: 0.85),
                    theme.colorScheme.surface.withValues(alpha: 0.55),
                  ],
          ),
          border: Border.all(
            color: active
                ? Colors.white.withValues(alpha: 0.20)
                : theme.colorScheme.onSurface.withValues(alpha: 0.10),
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: phase.tone.withValues(alpha: 0.34),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? Colors.white.withValues(alpha: 0.25)
                    : phase.tone.withValues(alpha: 0.18),
              ),
              child: Icon(phase.icon,
                  color: active ? Colors.white : phase.tone, size: 16),
            ),
            const Spacer(),
            Text(phase.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: active ? Colors.white : null,
                )),
            const SizedBox(height: 2),
            Text(phase.subtitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: active
                      ? Colors.white.withValues(alpha: 0.85)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
