import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../motion/os2_breathing.dart';
import '../os2_tokens.dart';
import '../primitives/os2_action_card.dart';
import '../primitives/os2_beacon.dart';
import '../primitives/os2_divider_rule.dart';
import '../primitives/os2_glyph_halo.dart';
import '../primitives/os2_info_strip.dart';
import '../primitives/os2_magnetic.dart';
import '../primitives/os2_marquee.dart';
import '../primitives/os2_pip.dart';
import '../primitives/os2_progress_arc.dart';
import '../primitives/os2_ribbon.dart';
import '../primitives/os2_slab.dart';
import '../primitives/os2_status_pill.dart';
import '../primitives/os2_text.dart';
import '../primitives/os2_timeline.dart';

/// OS 2.0 — Concierge hub.
///
/// Unified concierge surface combining all service ecosystems:
///   • Hero: breathing concierge orb (AGI standing by);
///   • Live marquee (current arrangements);
///   • Quick services grid (hotel / ride / dine / charter / lounge / eSIM);
///   • Active arrangements timeline;
///   • Loyalty programs panel;
///   • Standing protocols ribbon.
class Os2ConciergeHub extends ConsumerStatefulWidget {
  const Os2ConciergeHub({super.key});

  @override
  ConsumerState<Os2ConciergeHub> createState() => _Os2ConciergeHubState();
}

class _Os2ConciergeHubState extends ConsumerState<Os2ConciergeHub> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Os2.canvas,
      appBar: AppBar(
        backgroundColor: Os2.canvas,
        elevation: 0,
        title: Os2Text.title('Concierge', color: Os2.inkBright, size: Os2.textXl),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Os2.space2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: Row(
                  children: [
                    Os2Beacon(label: 'CONCIERGE \u00b7 STANDBY',
                        tone: Os2.servicesTone),
                    const Spacer(),
                    Os2StatusPill(
                      label: 'AVG',
                      value: '32S',
                      tone: Os2.signalSettled,
                      dense: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Os2.space3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _ConciergeHero(),
              ),
              const SizedBox(height: Os2.space3),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: Os2.space4),
                child: Os2Marquee(
                  items: [
                    'ARRANGED \u00b7 Mercedes EQS \u00b7 19:32 curbside',
                    'ARRANGED \u00b7 Soma Suites \u00b7 contactless check-in',
                    'ARRANGED \u00b7 The Saint \u00b7 4 guests \u00b7 20:30',
                    'STANDBY \u00b7 yacht charter \u00b7 Côte d\u2019Azur',
                    'STANDBY \u00b7 helicopter \u00b7 JFK \u2192 Hamptons',
                  ],
                  tone: Os2.servicesTone,
                ),
              ),
              const SizedBox(height: Os2.space4),
              Os2InfoStrip(
                entries: const [
                  Os2InfoEntry(
                    icon: Icons.support_agent_rounded,
                    label: 'TEAM',
                    value: '6 ONLINE',
                    tone: Os2.servicesTone,
                  ),
                  Os2InfoEntry(
                    icon: Icons.local_taxi_rounded,
                    label: 'RIDES',
                    value: '2 LIVE',
                    tone: Os2.discoverTone,
                  ),
                  Os2InfoEntry(
                    icon: Icons.hotel_rounded,
                    label: 'STAYS',
                    value: '1 ACTIVE',
                    tone: Os2.travelTone,
                  ),
                  Os2InfoEntry(
                    icon: Icons.restaurant_rounded,
                    label: 'DINING',
                    value: '3 HELD',
                    tone: Os2.walletTone,
                  ),
                  Os2InfoEntry(
                    icon: Icons.workspace_premium_rounded,
                    label: 'TIER',
                    value: 'AVIATOR',
                    tone: Os2.identityTone,
                  ),
                ],
              ),
              const SizedBox(height: Os2.space4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _QuickServices(),
              ),
              const SizedBox(height: Os2.space4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _ActiveArrangements(),
              ),
              const SizedBox(height: Os2.space4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _LoyaltyPrograms(),
              ),
              const SizedBox(height: Os2.space4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: Os2Ribbon(
                  label: 'STANDING PROTOCOLS',
                  value: '12 ACTIVE',
                  tone: Os2.servicesTone,
                  trailing: 'CURATED',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConciergeHero extends StatelessWidget {
  const _ConciergeHero();

  @override
  Widget build(BuildContext context) {
    return Os2Slab(
      tone: Os2.servicesTone,
      tier: Os2SlabTier.floor1,
      radius: Os2.rHero,
      halo: Os2SlabHalo.edge,
      elevation: Os2SlabElevation.cinematic,
      padding: const EdgeInsets.symmetric(
        horizontal: Os2.space4,
        vertical: Os2.space5,
      ),
      breath: true,
      child: Row(
        children: [
          Os2Breathing(
            minScale: 0.985,
            maxScale: 1.015,
            child: Os2GlyphHalo(
              icon: Icons.support_agent_rounded,
              tone: Os2.servicesTone,
              size: 88,
              iconSize: 44,
            ),
          ),
          const SizedBox(width: Os2.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Os2Text.monoCap('LIVE \u00b7 12 PROTOCOLS',
                    color: Os2.servicesTone, size: 11),
                const SizedBox(height: 4),
                Os2Text.display('Standing by.',
                    color: Os2.inkBright, size: 22),
                const SizedBox(height: 4),
                Os2Text.caption(
                  'Hand me anything from a 5pm reservation to a private yacht.',
                  color: Os2.inkMid,
                ),
                const SizedBox(height: Os2.space3),
                Row(
                  children: [
                    Os2StatusPill(
                      label: 'AVG',
                      value: '32S',
                      tone: Os2.signalSettled,
                      dense: true,
                    ),
                    const SizedBox(width: Os2.space2),
                    Os2StatusPill(
                      label: 'TIER',
                      value: 'AVIATOR',
                      tone: Os2.identityTone,
                      dense: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickServices extends StatelessWidget {
  const _QuickServices();
  @override
  Widget build(BuildContext context) {
    final services = const <_QS>[
      _QS('Hotel', Icons.hotel_rounded, Os2.travelTone),
      _QS('Ride', Icons.local_taxi_rounded, Os2.discoverTone),
      _QS('Dine', Icons.restaurant_rounded, Os2.walletTone),
      _QS('Charter', Icons.directions_boat_rounded, Os2.servicesTone),
      _QS('Lounge', Icons.local_cafe_rounded, Os2.identityTone),
      _QS('eSIM', Icons.sim_card_rounded, Os2.pulseTone),
      _QS('Visa', Icons.travel_explore_rounded, Os2.signalLive),
      _QS('Helicopter', Icons.flight_rounded, Os2.signalSettled),
      _QS('Doctor', Icons.medical_services_rounded, Os2.signalCritical),
    ];
    return Os2Slab(
      tone: Os2.servicesTone,
      tier: Os2SlabTier.floor2,
      radius: Os2.rCard,
      halo: Os2SlabHalo.corner,
      padding: const EdgeInsets.all(Os2.space4),
      breath: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Os2DividerRule(
            eyebrow: 'QUICK SUMMON',
            tone: Os2.servicesTone,
            trailing: '${services.length} SERVICES',
          ),
          const SizedBox(height: Os2.space3),
          for (var row = 0; row < (services.length / 3).ceil(); row++) ...[
            Row(
              children: [
                for (var col = 0; col < 3; col++) ...[
                  if (row * 3 + col < services.length)
                    Expanded(
                      child: Os2ActionCard(
                        title: services[row * 3 + col].title,
                        icon: services[row * 3 + col].icon,
                        tone: services[row * 3 + col].tone,
                        dense: true,
                        onTap: () {
                          HapticFeedback.selectionClick();
                        },
                      ),
                    )
                  else
                    const Expanded(child: SizedBox()),
                  if (col < 2) const SizedBox(width: Os2.space2),
                ],
              ],
            ),
            if (row < (services.length / 3).ceil() - 1)
              const SizedBox(height: Os2.space2),
          ],
        ],
      ),
    );
  }
}

class _QS {
  const _QS(this.title, this.icon, this.tone);
  final String title;
  final IconData icon;
  final Color tone;
}

class _ActiveArrangements extends StatelessWidget {
  const _ActiveArrangements();
  @override
  Widget build(BuildContext context) {
    return Os2Slab(
      tone: Os2.travelTone,
      tier: Os2SlabTier.floor2,
      radius: Os2.rCard,
      halo: Os2SlabHalo.corner,
      padding: const EdgeInsets.all(Os2.space4),
      breath: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Os2DividerRule(
            eyebrow: 'ACTIVE ARRANGEMENTS',
            tone: Os2.travelTone,
            trailing: '5 LIVE',
          ),
          const SizedBox(height: Os2.space3),
          Os2Timeline(
            tone: Os2.travelTone,
            dense: true,
            nodes: const [
              Os2TimelineNode(
                title: 'Curbside ride \u00b7 Mercedes EQS',
                caption: 'WM-2241 \u00b7 staged at 19:32',
                trailing: 'STAGED',
                state: Os2NodeState.active,
              ),
              Os2TimelineNode(
                title: 'Hotel \u00b7 Soma Suites room 1408',
                caption: 'Contactless check-in \u00b7 keys synced',
                trailing: '21:00',
                state: Os2NodeState.pending,
              ),
              Os2TimelineNode(
                title: 'Dinner \u00b7 The Saint',
                caption: '4 guests \u00b7 chef\u2019s table',
                trailing: '20:30',
                state: Os2NodeState.pending,
              ),
              Os2TimelineNode(
                title: 'eSIM \u00b7 US data + voice',
                caption: '10GB / 7d \u00b7 auto-activate',
                trailing: 'ARMED',
                state: Os2NodeState.settled,
              ),
              Os2TimelineNode(
                title: 'Lounge \u00b7 Star Alliance B-pier',
                caption: 'Seat S-12 \u00b7 quiet zone',
                trailing: 'OPEN',
                state: Os2NodeState.settled,
              ),
            ],
          ),
          const SizedBox(height: Os2.space3),
          Os2LabelledPipStack(
            label: 'PROGRESS',
            tone: Os2.travelTone,
            pips: const [
              Os2PipState.settled,
              Os2PipState.settled,
              Os2PipState.active,
              Os2PipState.pending,
              Os2PipState.pending,
            ],
            trailing: '3 / 5',
          ),
        ],
      ),
    );
  }
}

class _LoyaltyPrograms extends StatelessWidget {
  const _LoyaltyPrograms();
  @override
  Widget build(BuildContext context) {
    final programs = const [
      ('Star Alliance', 'GOLD', 0.74, Os2.identityTone),
      ('Marriott Bonvoy', 'PLAT', 0.62, Os2.walletTone),
      ('SkyTeam', 'ELITE', 0.41, Os2.travelTone),
      ('Hilton Honors', 'DIAMOND', 0.86, Os2.servicesTone),
    ];
    return Os2Slab(
      tone: Os2.walletTone,
      tier: Os2SlabTier.floor2,
      radius: Os2.rCard,
      halo: Os2SlabHalo.corner,
      padding: const EdgeInsets.all(Os2.space4),
      breath: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Os2DividerRule(
            eyebrow: 'LOYALTY PROGRAMS',
            tone: Os2.walletTone,
            trailing: '${programs.length} ACTIVE',
          ),
          const SizedBox(height: Os2.space3),
          for (final p in programs) ...[
            Os2Magnetic(
              onTap: () {
                HapticFeedback.selectionClick();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Os2.space2),
                child: Row(
                  children: [
                    Os2ProgressArc(
                      value: p.$3,
                      tone: p.$4,
                      diameter: 44,
                      strokeWidth: 4,
                      center: Os2Text.monoCap(
                        '${(p.$3 * 100).round()}',
                        color: Os2.inkBright,
                        size: 10,
                      ),
                    ),
                    const SizedBox(width: Os2.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Os2Text.title(p.$1,
                              color: Os2.inkBright, size: 14),
                          const SizedBox(height: 2),
                          Os2Text.caption('Tier · ${p.$2}',
                              color: Os2.inkMid),
                        ],
                      ),
                    ),
                    Os2Text.monoCap(p.$2, color: p.$4, size: Os2.textXs),
                  ],
                ),
              ),
            ),
            if (p != programs.last)
              Container(height: 1, color: Os2.hairlineSoft),
          ],
        ],
      ),
    );
  }
}
