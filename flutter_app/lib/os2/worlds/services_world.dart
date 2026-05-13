import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../os2_tokens.dart';
import '../primitives/os2_action_card.dart';
import '../primitives/os2_chip.dart';
import '../primitives/os2_divider_rule.dart';
import '../primitives/os2_info_strip.dart';
import '../primitives/os2_magnetic.dart';
import '../primitives/os2_ribbon.dart';
import '../primitives/os2_slab.dart';
import '../primitives/os2_text.dart';
import '../primitives/os2_timeline.dart';
import '../primitives/os2_world_header.dart';

/// OS 2.0 — Services world.
///
/// Concierge floor. Each service is a full-bleed vignette slab,
/// stacked vertically (not a 3-column grid). The user reads each
/// service as a deliberate offer, not a tile in a menu.
class ServicesWorld extends ConsumerWidget {
  const ServicesWorld({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Os2WorldHeader(
              world: Os2World.services,
              title: 'Concierge',
              subtitle: 'Hand-curated service floor',
              beacon: 'READY',
            ),
            const SizedBox(height: Os2.space3),
            Os2InfoStrip(
              entries: [
                Os2InfoEntry(
                  icon: Icons.support_agent_rounded,
                  label: 'CONCIERGE',
                  value: 'ONLINE',
                  tone: Os2.signalSettled,
                  onTap: () => GoRouter.of(context).push('/copilot'),
                ),
                Os2InfoEntry(
                  icon: Icons.health_and_safety_rounded,
                  label: 'SAFETY',
                  value: '24 / 7',
                  tone: Os2.signalLive,
                  onTap: () => GoRouter.of(context).push('/emergency'),
                ),
                Os2InfoEntry(
                  icon: Icons.local_atm_rounded,
                  label: 'BENEFITS',
                  value: '12 ACTIVE',
                  tone: Os2.servicesTone,
                ),
                Os2InfoEntry(
                  icon: Icons.flag_rounded,
                  label: 'PROGRAMS',
                  value: '6 ENROLLED',
                  tone: Os2.identityTone,
                ),
              ],
            ),
            const SizedBox(height: Os2.space4),
            // Action grid: 6 quick concierge actions.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
              child: _ServicesQuickActions(),
            ),
            const SizedBox(height: Os2.space5),
            // Recent requests timeline.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
              child: _ServicesTimeline(),
            ),
            const SizedBox(height: Os2.space5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
              child: Column(
                children: [
                  _Vignette(
                    icon: Icons.bed_rounded,
                    label: 'STAY',
                    title: 'Hotels & residences',
                    body: 'Boutique stays, suites, and long-stay residences in 84 cities.',
                    route: '/services/hotels',
                    tone: Os2.servicesTone,
                  ),
                  _Vignette(
                    icon: Icons.flight_takeoff_rounded,
                    label: 'FLY',
                    title: 'Flights & charters',
                    body: 'Premium economy through full charter \u00b7 Star Alliance + oneworld.',
                    route: '/services/flights',
                    tone: Os2.travelTone,
                  ),
                  _Vignette(
                    icon: Icons.local_taxi_rounded,
                    label: 'MOVE',
                    title: 'Ground mobility',
                    body: 'Premium rides, chauffeurs, helicopter transfers in 36 cities.',
                    route: '/services/rides',
                    tone: Os2.discoverTone,
                  ),
                  _Vignette(
                    icon: Icons.restaurant_rounded,
                    label: 'DINE',
                    title: 'Restaurants & reservations',
                    body: 'Same-day tables at Michelin and "impossible" reservations.',
                    route: '/services/food',
                    tone: Os2.pulseTone,
                  ),
                  _Vignette(
                    icon: Icons.event_rounded,
                    label: 'EXPERIENCE',
                    title: 'Activities & tickets',
                    body: 'Private tours, sold-out concerts, sports premium boxes.',
                    route: '/services/activities',
                    tone: Os2.identityTone,
                  ),
                  _Vignette(
                    icon: Icons.local_cafe_rounded,
                    label: 'LOUNGE',
                    title: 'Lounge access',
                    body: 'One-tap entry into 1,800 airport lounges worldwide.',
                    route: '/lounge',
                    tone: Os2.walletTone,
                  ),
                  _Vignette(
                    icon: Icons.sim_card_rounded,
                    label: 'CONNECT',
                    title: 'eSIM & data plans',
                    body: 'Country and region packs activate before you land.',
                    route: '/esim',
                    tone: Os2.discoverTone,
                  ),
                  _Vignette(
                    icon: Icons.assignment_ind_rounded,
                    label: 'VISA',
                    title: 'Visa & eVisa center',
                    body:
                        'Eligibility, expiry & readiness · 192 destinations.',
                    route: '/visa',
                    tone: Os2.identityTone,
                  ),
                  _Vignette(
                    icon: Icons.currency_exchange_rounded,
                    label: 'FOREX',
                    title: 'Currency exchange',
                    body:
                        'Live FX · multi-currency pours · spot rates in 48 currencies.',
                    route: '/wallet/exchange',
                    tone: Os2.walletTone,
                  ),
                  _Vignette(
                    icon: Icons.auto_awesome_rounded,
                    label: 'CURATED',
                    title: 'Curated trips',
                    body:
                        'Hand-built itineraries by category — heritage, family, solo, gourmet.',
                    route: '/itinerary',
                    tone: Os2.discoverTone,
                  ),
                  _Vignette(
                    icon: Icons.alt_route_rounded,
                    label: 'ROUTES',
                    title: 'Smart routes',
                    body:
                        'Multi-leg pipeline optimisation across airline, rail and ground.',
                    route: '/travel-os',
                    tone: Os2.travelTone,
                  ),
                  _Vignette(
                    icon: Icons.directions_subway_rounded,
                    label: 'TRANSIT',
                    title: 'Local transit & passes',
                    body:
                        'Metro, rail, bus and ride passes for 84 cities.',
                    route: '/services/transport',
                    tone: Os2.pulseTone,
                  ),
                  _Vignette(
                    icon: Icons.health_and_safety_rounded,
                    label: 'SAFETY',
                    title: 'Emergency desk',
                    body:
                        'Tap-to-talk crisis support \u00b7 medical \u00b7 evacuation in 24/7 ops.',
                    route: '/emergency',
                    tone: Os2.identityTone,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Vignette extends StatelessWidget {
  const _Vignette({
    required this.icon,
    required this.label,
    required this.title,
    required this.body,
    required this.route,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final String title;
  final String body;
  final String route;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Os2.space3),
      child: Os2Magnetic(
        onTap: () => GoRouter.of(context).push(route),
        child: Os2Slab(
          tone: tone,
          tier: Os2SlabTier.floor2,
          radius: Os2.rSlab,
          halo: Os2SlabHalo.edge,
          elevation: Os2SlabElevation.raised,
          padding: const EdgeInsets.all(Os2.space5),
          breath: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: tone.withValues(alpha: 0.40),
                    width: Os2.strokeFine,
                  ),
                ),
                child: Icon(icon, color: tone, size: 24),
              ),
              const SizedBox(width: Os2.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Os2Chip(
                      label: label,
                      tone: tone,
                      intensity: Os2ChipIntensity.solid,
                      size: Os2ChipSize.compact,
                    ),
                    const SizedBox(height: Os2.space2),
                    Os2Text.headline(
                      title,
                      color: Os2.inkBright,
                      size: 20,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    Os2Text.body(
                      body,
                      color: Os2.inkMid,
                      size: 13,
                      maxLines: 3,
                    ),
                    const SizedBox(height: Os2.space3),
                    Row(
                      children: [
                        Icon(Icons.arrow_forward_rounded,
                            size: 14, color: tone),
                        const SizedBox(width: 4),
                        Os2Text.caption('OPEN', color: tone),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────── Quick actions

class _ServicesQuickActions extends StatelessWidget {
  const _ServicesQuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QA('Book stay', Icons.bed_rounded, Os2.servicesTone, '/services/hotels'),
      _QA('Charter', Icons.flight_takeoff_rounded, Os2.travelTone, '/services/flights'),
      _QA('Ride', Icons.local_taxi_rounded, Os2.discoverTone, '/services/rides'),
      _QA('Dine', Icons.restaurant_rounded, Os2.pulseTone, '/services/food'),
      _QA('Lounge', Icons.local_cafe_rounded, Os2.walletTone, '/lounge'),
      _QA('eSIM', Icons.sim_card_rounded, Os2.discoverTone, '/esim'),
      _QA('Visa', Icons.assignment_ind_rounded, Os2.identityTone, '/visa'),
      _QA('Forex', Icons.currency_exchange_rounded, Os2.walletTone,
          '/wallet/exchange'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Os2DividerRule(
          eyebrow: 'QUICK ACTIONS',
          tone: Os2.servicesTone,
          trailing: '8 / 12',
        ),
        const SizedBox(height: Os2.space3),
        for (var i = 0; i < actions.length; i += 2) ...[
          Row(
            children: [
              for (var j = i; j < i + 2 && j < actions.length; j++) ...[
                Expanded(
                  child: Os2ActionCard(
                    title: actions[j].title,
                    icon: actions[j].icon,
                    tone: actions[j].tone,
                    dense: true,
                    onTap: () => GoRouter.of(context).push(actions[j].route),
                  ),
                ),
                if (j == i && j + 1 < actions.length)
                  const SizedBox(width: Os2.space3),
              ],
            ],
          ),
          if (i + 2 < actions.length) const SizedBox(height: Os2.space3),
        ],
      ],
    );
  }
}

class _QA {
  const _QA(this.title, this.icon, this.tone, this.route);
  final String title;
  final IconData icon;
  final Color tone;
  final String route;
}

// ─────────────────────────────────────────── Recent requests

class _ServicesTimeline extends StatelessWidget {
  const _ServicesTimeline();

  @override
  Widget build(BuildContext context) {
    return Os2Slab(
      tone: Os2.servicesTone,
      tier: Os2SlabTier.floor2,
      radius: Os2.rCard,
      halo: Os2SlabHalo.corner,
      elevation: Os2SlabElevation.resting,
      padding: const EdgeInsets.all(Os2.space4),
      breath: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Os2DividerRule(
            eyebrow: 'RECENT REQUESTS',
            tone: Os2.servicesTone,
            trailing: 'LAST 24H',
          ),
          const SizedBox(height: Os2.space3),
          Os2Timeline(
            tone: Os2.servicesTone,
            dense: true,
            nodes: const [
              Os2TimelineNode(
                title: 'Hotel · Soma Suites · SFO',
                caption: 'Concierge briefed · contactless check-in',
                trailing: 'BOOKED',
                state: Os2NodeState.settled,
              ),
              Os2TimelineNode(
                title: 'Lounge · Star Alliance · FRA',
                caption: 'One-tap entry · 64 / 110 occupancy',
                trailing: 'READY',
                state: Os2NodeState.active,
              ),
              Os2TimelineNode(
                title: 'Ride · SFO airport pickup',
                caption: 'Staged · arrives at gate · 19:32',
                trailing: 'STAGED',
                state: Os2NodeState.pending,
              ),
              Os2TimelineNode(
                title: 'Dinner · The Saint · SOMA',
                caption: '20:30 · 4 guests · concierge held',
                trailing: '20:30',
                state: Os2NodeState.pending,
              ),
            ],
          ),
          const SizedBox(height: Os2.space3),
          Os2Ribbon(
            label: 'CONCIERGE',
            value: 'STANDING BY',
            tone: Os2.signalSettled,
            trailing: 'AVG 32S',
          ),
        ],
      ),
    );
  }
}
