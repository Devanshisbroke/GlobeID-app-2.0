import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../cards/nexus_baggage_card.dart';
import '../cards/nexus_boarding_pass_card.dart';
import '../cards/nexus_countdown_card.dart';
import '../cards/nexus_destination_card.dart';
import '../cards/nexus_immigration_card.dart';
import '../cards/nexus_lounge_card.dart';
import '../cards/nexus_navigation_card.dart';
import '../cards/nexus_orion_card.dart';
import '../chrome/nexus_bottom_nav.dart';
import '../chrome/nexus_chip.dart';
import '../chrome/nexus_pipeline.dart';
import '../chrome/nexus_scaffold.dart';
import '../chrome/nexus_update_banner.dart';
import '../nexus_tokens.dart';
import '../nexus_typography.dart';

/// Canonical Travel OS screen — the lifecycle dashboard.
class NexusTravelOsScreen extends StatefulWidget {
  const NexusTravelOsScreen({super.key});

  @override
  State<NexusTravelOsScreen> createState() => _NexusTravelOsScreenState();
}

class _NexusTravelOsScreenState extends State<NexusTravelOsScreen> {
  bool _showBanner = true;
  late final DateTime _departTarget;

  @override
  void initState() {
    super.initState();
    _departTarget = DateTime.now().add(const Duration(
      hours: 2,
      minutes: 14,
      seconds: 45,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return NScaffold(
      time: '11:08',
      right: 'Biometric · Verified',
      topBanner: _showBanner
          ? NUpdateBanner(
              eyebrow: 'Update',
              message: 'Gate change · B32 → B14',
              onDismiss: () => setState(() => _showBanner = false),
              onDetails: () {},
            )
          : null,
      bottomNav: NBottomNav(
        items: const [
          NNavItem(
            label: 'Travel OS',
            icon: Icons.public_rounded,
            path: '/nexus/os',
          ),
          NNavItem(
            label: 'Passport',
            icon: Icons.menu_book_rounded,
            path: '/nexus/passport',
          ),
          NNavItem(
            label: 'Wallet',
            icon: Icons.account_balance_wallet_rounded,
            path: '/nexus/wallet',
          ),
        ],
        activeIndex: 0,
        onTap: (i) {
          const paths = ['/nexus/os', '/nexus/passport', '/nexus/wallet'];
          if (i != 0) context.go(paths[i]);
        },
      ),
      children: [
        // ─── Eyebrow + title row
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NText.eyebrow11('Globe ID · Travel OS'),
            const SizedBox(height: N.s2),
            Text(
              'GlobeID Travel OS',
              style: NType.title22(color: N.inkHi),
            ),
            const SizedBox(height: N.s3),
            Wrap(
              spacing: N.s2,
              runSpacing: N.s2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                NText.eyebrow10('Journey · Lounge stage'),
                const NChip(
                  label: 'Pandion Elite',
                  variant: NChipVariant.active,
                  dense: true,
                ),
                NText.eyebrow10('Tier · 03', color: N.tierGoldHi),
              ],
            ),
          ],
        ),
        const SizedBox(height: N.s5),

        // ─── Countdown card
        NCountdownCard(
          target: _departTarget,
          eyebrow: 'departs in',
          flight: 'LX · 402',
          route: 'ZRH 09:55 → 17:40 SIN',
        ),
        const SizedBox(height: N.s5),

        // ─── Pipeline strip
        const NPipeline(
          stages: [
            'Plan',
            'Pack',
            'Check-in',
            'Security',
            'Lounge',
            'Board',
            'Land',
          ],
          activeIndex: 4,
        ),
        const SizedBox(height: N.s5),

        // ─── Boarding pass card
        const NBoardingPassCard(
          data: NBoardingPassData(
            passenger: 'ALEXANDER V. GRAFF',
            cabin: 'FIRST · SOVEREIGN',
            fromCode: 'ZRH',
            fromCity: 'Zurich',
            fromTerm: 'T2',
            toCode: 'SIN',
            toCity: 'Changi',
            toTerm: 'T3',
            gate: 'B14',
            seat: '2A',
            group: 'S1',
            board: '09:15',
            token: 'GID-7Q4-8821-Λ',
          ),
        ),
        const SizedBox(height: N.s3),

        // ─── Live navigation
        const NNavigationCard(
          minutes: 12,
          direction: 'East Concourse · Level 2',
          destination: 'Gate B14',
        ),
        const SizedBox(height: N.s3),

        // ─── Lounge eligibility
        const NLoungeCard(
          name: 'Concorde',
          openUntil: '09:15',
          eligibility: 'Eligible · Suite access',
        ),
        const SizedBox(height: N.s3),

        // ─── Baggage synchronized
        const NBaggageCard(
          rfid: 'GX-9921',
          drop: 'Confirmed',
          loading: 'Hold 2',
        ),
        const SizedBox(height: N.s3),

        // ─── Immigration readiness
        const NImmigrationCard(
          percent: 0.90,
          items: [
            NImmigrationItem(
              label: 'Digital arrival card · submitted',
              state: 'done',
            ),
            NImmigrationItem(
              label: 'SmartGate biometric · token active',
              state: 'done',
            ),
            NImmigrationItem(
              label: 'Passport scan · at gate B14',
              state: 'active',
            ),
          ],
        ),
        const SizedBox(height: N.s3),

        // ─── Orion AI
        const NOrionCard(
          message:
              'Fast-track lane pre-booked for 09:08. Suite seating in Concorde reserved under your tier.',
        ),
        const SizedBox(height: N.s3),

        // ─── Destination
        const NDestinationCard(
          code: 'SIN',
          weather: '31°',
          condition: 'Humid clearing',
          arrival: '17:40 SGT',
          prep: 'LIGHT · LINEN',
        ),
      ],
    );
  }
}
