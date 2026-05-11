import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../bible_tokens.dart';
import '../bible_typography.dart';
import '../chrome/bible_buttons.dart';
import '../chrome/bible_pressable.dart';
import '../chrome/bible_premium_card.dart';
import '../chrome/bible_scaffold.dart';
import '../chrome/bible_widgets.dart';

/// GlobeID — **Trip Detail** (§11.6 _The Itinerary Engine_).
///
/// Registers: Anticipation. Spine: Travel.
///
/// Vertical timeline of every leg + sub-leg, a currency card with FX
/// preview, timezone strip, pre-trip intel, ground ops, and a small
/// wallet sandbox that lets the user pre-load JPY before takeoff.
class BibleTripScreen extends StatelessWidget {
  const BibleTripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BiblePageScaffold(
      emotion: BEmotion.anticipation,
      tone: B.jetCyan.withValues(alpha: 0.08),
      density: BDensity.cabin,
      eyebrow: '— trip · march 14 → march 22 —',
      title: 'Tokyo · NRT',
      trailing: const BibleStatusPill(
        label: 'departs',
        value: '18d',
        tone: B.runwayAmber,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TripHeader(),
          const SizedBox(height: B.space5),
          const BibleSectionHeader(
            eyebrow: 'itinerary',
            title: 'Vertical timeline',
          ),
          _Itinerary(),
          const SizedBox(height: B.space5),
          const BibleSectionHeader(
            eyebrow: 'currency · pre-load',
            title: 'Wallet sandbox',
          ),
          _CurrencyCard(),
          const SizedBox(height: B.space5),
          const BibleSectionHeader(
            eyebrow: 'pre-trip intel',
            title: 'What you should know',
          ),
          _PreTripGrid(),
          const SizedBox(height: B.space5),
          const BibleSectionHeader(
            eyebrow: 'ground ops',
            title: 'Booked / pending',
          ),
          _GroundOps(),
          const SizedBox(height: B.space5),
          const BibleSectionHeader(
            eyebrow: 'time zone strip',
            title: 'Across the journey',
          ),
          _TimezoneStrip(),
          const SizedBox(height: B.space6),
        ],
      ),
    );
  }
}

class _TripHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BiblePremiumCard(
      tone: B.jetCyan,
      padding: const EdgeInsets.all(B.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BibleGlyphHalo(
                icon: Icons.flight_takeoff_rounded,
                tone: B.jetCyan,
                size: 48,
              ),
              const SizedBox(width: B.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BText.eyebrow('LHR ↔ NRT · business', color: B.jetCyan),
                    BText.title('British Airways · BA 005', size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: B.space3),
          BibleInfoRail(
            entries: const [
              BibleInfoEntry(
                icon: Icons.calendar_today_rounded,
                label: 'departs',
                value: 'Mar 14 · 09:42 GMT',
                tone: B.jetCyan,
              ),
              BibleInfoEntry(
                icon: Icons.public_rounded,
                label: 'arrives',
                value: 'Mar 15 · 07:42 JST',
                tone: B.runwayAmber,
              ),
              BibleInfoEntry(
                icon: Icons.timeline_rounded,
                label: 'duration',
                value: '13h 0m',
                tone: B.foilGold,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Itinerary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BiblePremiumCard(
      tone: B.jetCyan,
      padding: const EdgeInsets.all(B.space4),
      child: BibleTimeline(
        tone: B.jetCyan,
        nodes: const [
          BibleTimelineNode(
            title: 'Home → LHR · T5',
            caption: 'Uber Premier · 1h 20m',
            trailing: 'Mar 14 · 06:18',
            state: BiblePipState.pending,
          ),
          BibleTimelineNode(
            title: 'Check-in · online',
            caption: 'Cleared 30 days ahead',
            trailing: 'Mar 14 · 08:00',
            state: BiblePipState.pending,
          ),
          BibleTimelineNode(
            title: 'Fast-track security',
            caption: 'Avg wait · 4m',
            trailing: 'Mar 14 · 08:30',
            state: BiblePipState.pending,
          ),
          BibleTimelineNode(
            title: 'BA Concorde Room',
            caption: 'Lounge access · 1h slot',
            trailing: 'Mar 14 · 08:45',
            state: BiblePipState.pending,
          ),
          BibleTimelineNode(
            title: 'Gate B47 boarding',
            caption: 'Group 02',
            trailing: 'Mar 14 · 09:12',
            state: BiblePipState.pending,
          ),
          BibleTimelineNode(
            title: 'Takeoff · LHR',
            caption: 'Runway 27R',
            trailing: 'Mar 14 · 09:42',
            state: BiblePipState.pending,
          ),
          BibleTimelineNode(
            title: 'Inflight · 13h 0m',
            caption: 'B777-300ER · seat 23A',
            trailing: 'cabin',
            state: BiblePipState.pending,
          ),
          BibleTimelineNode(
            title: 'Landing · NRT',
            caption: 'Runway 16L',
            trailing: 'Mar 15 · 07:42',
            state: BiblePipState.pending,
          ),
          BibleTimelineNode(
            title: 'JAL Sakura · pod',
            caption: '2h sanctuary slot',
            trailing: 'Mar 15 · 08:30',
            state: BiblePipState.pending,
          ),
          BibleTimelineNode(
            title: 'Tokyo Limo · Aman',
            caption: 'Driver · Hiroshi K',
            trailing: 'Mar 15 · 11:00',
            state: BiblePipState.pending,
          ),
        ],
      ),
    );
  }
}

class _CurrencyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BiblePressable(
      onTap: () => context.go('/bible/wallet'),
      child: BiblePremiumCard(
        tone: B.treasuryGreen,
        padding: const EdgeInsets.all(B.space4),
        child: Column(
          children: [
            Row(
              children: [
                BibleGlyphHalo(
                  icon: Icons.currency_yen_rounded,
                  tone: B.treasuryGreen,
                  size: 44,
                ),
                const SizedBox(width: B.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BText.eyebrow('pre-load yen', color: B.treasuryGreen),
                      const SizedBox(height: B.space1),
                      BText.title('£200 → ¥38,142', size: 17),
                      BText.caption(
                        '1 GBP = ¥190.71 · mid-market',
                        color: B.inkOnDarkMid,
                      ),
                    ],
                  ),
                ),
                BibleGhostButton(
                  label: 'open wallet',
                  onPressed: () => context.go('/bible/wallet'),
                  tone: B.treasuryGreen,
                ),
              ],
            ),
            const SizedBox(height: B.space3),
            BibleSparkline(
              values: const [
                189, 189, 190, 190, 190, 191, 191, 190, 191, 191, 192, 191, 191, 190,
              ].map((e) => e.toDouble()).toList(),
              tone: B.treasuryGreen,
              height: 56,
              strokeWidth: 1.6,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreTripGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(
              child: _IntelTile(
                eyebrow: 'visa',
                title: 'Japan · eVisa',
                caption: 'Single-entry · 90 days',
                tone: B.diplomaticGarnet,
                icon: Icons.workspace_premium_rounded,
              ),
            ),
            SizedBox(width: B.space3),
            Expanded(
              child: _IntelTile(
                eyebrow: 'weather',
                title: 'Spring · 14°C avg',
                caption: 'Cherry-blossom window',
                tone: B.polarBlue,
                icon: Icons.wb_sunny_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: B.space3),
        Row(
          children: const [
            Expanded(
              child: _IntelTile(
                eyebrow: 'cellular',
                title: 'NTT 5G — 8 GB',
                caption: 'Auto-activate on landing',
                tone: B.jetCyan,
                icon: Icons.sim_card_rounded,
              ),
            ),
            SizedBox(width: B.space3),
            Expanded(
              child: _IntelTile(
                eyebrow: 'health',
                title: 'No advisories',
                caption: 'Routine vaccinations ok',
                tone: B.equatorTeal,
                icon: Icons.health_and_safety_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _IntelTile extends StatelessWidget {
  const _IntelTile({
    required this.eyebrow,
    required this.title,
    required this.caption,
    required this.tone,
    required this.icon,
  });
  final String eyebrow;
  final String title;
  final String caption;
  final Color tone;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return BiblePremiumCard(
      tone: tone,
      padding: const EdgeInsets.all(B.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: tone),
              const SizedBox(width: B.space1),
              BText.eyebrow(eyebrow, color: tone),
            ],
          ),
          const SizedBox(height: B.space2),
          BText.title(title, size: 14),
          BText.caption(caption, color: B.inkOnDarkMid, maxLines: 2),
        ],
      ),
    );
  }
}

class _GroundOps extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _OpsRow(
          icon: Icons.local_taxi_rounded,
          eyebrow: 'taxi · LHR',
          title: 'Uber Premier · S-Class',
          caption: 'Booked · driver assigned',
          status: 'confirmed',
          tone: B.honeyAmber,
        ),
        _OpsRow(
          icon: Icons.weekend_rounded,
          eyebrow: 'lounge · LHR',
          title: 'BA Concorde Room',
          caption: '08:45 → 09:00 slot',
          status: 'confirmed',
          tone: B.foilGold,
        ),
        _OpsRow(
          icon: Icons.flight_rounded,
          eyebrow: 'flight · BA 005',
          title: 'Seat 23A · Club World',
          caption: 'Pre-departure menu chosen',
          status: 'confirmed',
          tone: B.jetCyan,
        ),
        _OpsRow(
          icon: Icons.weekend_outlined,
          eyebrow: 'lounge · NRT',
          title: 'JAL Sakura · pod',
          caption: '2h slot · 08:30 → 10:30',
          status: 'reserved',
          tone: B.velvetMauve,
        ),
        _OpsRow(
          icon: Icons.hotel_rounded,
          eyebrow: 'hotel',
          title: 'Aman Tokyo · Suite 31',
          caption: 'Early check-in · 11:00 JST',
          status: 'confirmed',
          tone: B.diplomaticGarnet,
        ),
        _OpsRow(
          icon: Icons.directions_car_rounded,
          eyebrow: 'transfer · NRT',
          title: 'Tokyo Limo · Hiroshi K',
          caption: 'Bay 04 · plate XYZ-12-04',
          status: 'pending',
          tone: B.equatorTeal,
        ),
      ],
    );
  }
}

class _OpsRow extends StatelessWidget {
  const _OpsRow({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.caption,
    required this.status,
    required this.tone,
  });
  final IconData icon;
  final String eyebrow;
  final String title;
  final String caption;
  final String status;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return BiblePressable(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: B.space1),
        padding: const EdgeInsets.all(B.space3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(B.rTile),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: B.hairlineLightSoft, width: 0.5),
        ),
        child: Row(
          children: [
            BibleGlyphHalo(icon: icon, tone: tone, size: 36),
            const SizedBox(width: B.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BText.eyebrow(eyebrow, color: tone),
                  BText.title(title, size: 13),
                  BText.caption(caption, color: B.inkOnDarkMid),
                ],
              ),
            ),
            BibleStatusPill(label: status, tone: tone, dense: true),
          ],
        ),
      ),
    );
  }
}

class _TimezoneStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BiblePremiumCard(
      tone: B.polarBlue,
      padding: const EdgeInsets.all(B.space3),
      child: Row(
        children: [
          Expanded(
            child: _TzCell(
              eyebrow: 'london · GMT',
              value: '09 : 42',
              caption: 'You are here',
              tone: B.polarBlue,
            ),
          ),
          Container(
            width: 0.5,
            height: 56,
            color: B.hairlineLight,
            margin: const EdgeInsets.symmetric(horizontal: B.space2),
          ),
          Expanded(
            child: _TzCell(
              eyebrow: 'cabin · UTC',
              value: '12 : 42',
              caption: 'Mid-flight',
              tone: B.jetCyan,
            ),
          ),
          Container(
            width: 0.5,
            height: 56,
            color: B.hairlineLight,
            margin: const EdgeInsets.symmetric(horizontal: B.space2),
          ),
          Expanded(
            child: _TzCell(
              eyebrow: 'tokyo · JST',
              value: '17 : 42',
              caption: 'Touchdown',
              tone: B.runwayAmber,
            ),
          ),
        ],
      ),
    );
  }
}

class _TzCell extends StatelessWidget {
  const _TzCell({
    required this.eyebrow,
    required this.value,
    required this.caption,
    required this.tone,
  });
  final String eyebrow;
  final String value;
  final String caption;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BText.eyebrow(eyebrow, color: tone),
        const SizedBox(height: B.space1),
        BText.solari(value, size: 18, color: B.inkOnDarkHigh),
        BText.caption(caption, color: B.inkOnDarkMid),
      ],
    );
  }
}
