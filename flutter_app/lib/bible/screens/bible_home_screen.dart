import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../bible_tokens.dart';
import '../bible_typography.dart';
import '../chrome/bible_pressable.dart';
import '../chrome/bible_premium_card.dart';
import '../chrome/bible_scaffold.dart';
import '../chrome/bible_widgets.dart';
import '../living/bible_breathing.dart';

/// GlobeID — **Home / Today** (§11.2 _The Living Dashboard_).
///
/// Registers: Stillness with bursts of Anticipation.
///
/// The hero is a `_GreetingHeader` paired with a `BiblePremiumHud` that
/// surfaces the single most relevant context — next flight, current
/// city, or last payment — chosen by a deterministic priority function.
/// Below: today's flight card (split-flap-styled), wallet runway strip
/// (FX + balance), trip cards, and a floating concierge orb.
class BibleHomeScreen extends StatelessWidget {
  const BibleHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BiblePageScaffold(
      emotion: BEmotion.anticipation,
      tone: B.runwayAmber.withValues(alpha: 0.06),
      density: BDensity.concourse,
      floatingChrome: const _ConciergeOrb(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          _GreetingHeader(),
          SizedBox(height: B.space5),
          _TodayFlightCard(),
          SizedBox(height: B.space4),
          _WalletRunwayStrip(),
          SizedBox(height: B.space5),
          _AgenticChipRail(),
          SizedBox(height: B.space5),
          BibleSectionHeader(
            eyebrow: 'upcoming trips',
            title: 'Your itinerary',
          ),
          _TripCard(
            city: 'Tokyo',
            iata: 'NRT',
            date: 'Mar 14 → Mar 22',
            tone: B.jetCyan,
            icon: Icons.flight_takeoff_rounded,
          ),
          SizedBox(height: B.space3),
          _TripCard(
            city: 'Lisbon',
            iata: 'LIS',
            date: 'Apr 03 → Apr 08',
            tone: B.honeyAmber,
            icon: Icons.flight_takeoff_rounded,
          ),
          SizedBox(height: B.space3),
          _TripCard(
            city: 'Reykjavik',
            iata: 'KEF',
            date: 'May 12 → May 18',
            tone: B.polarBlue,
            icon: Icons.flight_takeoff_rounded,
          ),
          SizedBox(height: B.space5),
          BibleSectionHeader(
            eyebrow: 'living dashboard',
            title: 'Right now',
          ),
          _NowGrid(),
          SizedBox(height: B.space6),
        ],
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader();
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        BibleBreathing(
          period: const Duration(seconds: 6),
          child: BibleGlyphHalo(
            icon: Icons.person_rounded,
            tone: B.foilGold,
            size: 56,
          ),
        ),
        const SizedBox(width: B.space4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BText.eyebrow('— good morning —'),
              const SizedBox(height: B.space1),
              BText.display('Devansh.', size: 26, maxLines: 1),
              const SizedBox(height: B.space1),
              BText.caption(
                'Three trips ahead. The Tokyo gate opens in 18 days.',
                color: B.inkOnDarkMid,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodayFlightCard extends StatelessWidget {
  const _TodayFlightCard();
  @override
  Widget build(BuildContext context) {
    return BiblePressable(
      onTap: () => context.go('/bible/boarding'),
      child: BiblePremiumCard(
        tone: B.jetCyan,
        padding: const EdgeInsets.all(B.space5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                BibleGlyphHalo(
                  icon: Icons.flight_rounded,
                  tone: B.jetCyan,
                  size: 44,
                ),
                const SizedBox(width: B.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BText.eyebrow('next flight · 18d', color: B.jetCyan),
                      const SizedBox(height: B.space1),
                      BText.title('LHR → NRT', size: 22),
                    ],
                  ),
                ),
                const BibleStatusPill(
                  label: 'gate',
                  value: 'B47',
                  tone: B.jetCyan,
                  breathing: true,
                ),
              ],
            ),
            const SizedBox(height: B.space4),
            // Split-flap-style departure board strip.
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: B.space3,
                vertical: B.space3,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(B.rTile),
                color: Colors.black.withValues(alpha: 0.36),
                border: Border.all(color: B.hairlineLightSoft, width: 0.6),
              ),
              child: Row(
                children: const [
                  Expanded(
                    child: _FlapStat(
                      label: 'flight',
                      value: 'BA 005',
                      tone: B.jetCyan,
                    ),
                  ),
                  _FlapDivider(),
                  Expanded(
                    child: _FlapStat(
                      label: 'departs',
                      value: '09 : 42 GMT',
                      tone: B.jetCyan,
                    ),
                  ),
                  _FlapDivider(),
                  Expanded(
                    child: _FlapStat(
                      label: 'seat',
                      value: '23A',
                      tone: B.jetCyan,
                    ),
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

class _FlapStat extends StatelessWidget {
  const _FlapStat({
    required this.label,
    required this.value,
    required this.tone,
  });
  final String label;
  final String value;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BText.eyebrow(label, color: tone),
        const SizedBox(height: B.space1),
        BText.mono(value, color: B.inkOnDarkHigh, size: 14),
      ],
    );
  }
}

class _FlapDivider extends StatelessWidget {
  const _FlapDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 28,
      color: B.hairlineLight,
      margin: const EdgeInsets.symmetric(horizontal: B.space3),
    );
  }
}

class _WalletRunwayStrip extends StatelessWidget {
  const _WalletRunwayStrip();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _FxTile(
            symbol: 'EUR',
            value: '€ 12,418.20',
            delta: '+0.42%',
            tone: B.treasuryGreen,
            spark: const [3, 4, 3, 5, 6, 5, 7, 8, 7, 8, 9, 8, 9, 10],
          ),
          _FxTile(
            symbol: 'JPY',
            value: '¥ 1,841,002',
            delta: '+0.18%',
            tone: B.foilGold,
            spark: const [5, 4, 4, 5, 5, 6, 6, 5, 7, 7, 8, 8, 8, 9],
          ),
          _FxTile(
            symbol: 'USD',
            value: '\$ 8,210.55',
            delta: '−0.09%',
            tone: B.waxCrimson,
            spark: const [8, 8, 7, 7, 6, 6, 5, 5, 6, 6, 5, 4, 5, 4],
          ),
          _FxTile(
            symbol: 'GBP',
            value: '£ 4,915.40',
            delta: '+0.21%',
            tone: B.polarBlue,
            spark: const [4, 4, 5, 5, 6, 5, 6, 7, 7, 7, 8, 7, 8, 8],
          ),
        ],
      ),
    );
  }
}

class _FxTile extends StatelessWidget {
  const _FxTile({
    required this.symbol,
    required this.value,
    required this.delta,
    required this.tone,
    required this.spark,
  });
  final String symbol;
  final String value;
  final String delta;
  final Color tone;
  final List<int> spark;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 196,
      margin: const EdgeInsets.only(right: B.space3),
      padding: const EdgeInsets.all(B.space3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(B.rCard),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tone.withValues(alpha: 0.12),
            tone.withValues(alpha: 0.0),
          ],
        ),
        border: Border.all(color: tone.withValues(alpha: 0.30), width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BText.eyebrow(symbol, color: tone),
              const Spacer(),
              BText.mono(delta, color: tone, size: 11),
            ],
          ),
          const SizedBox(height: B.space1),
          BText.mono(value, color: B.inkOnDarkHigh, size: 14),
          const SizedBox(height: B.space1),
          Expanded(
            child: BibleSparkline(
              values: spark.map((e) => e.toDouble()).toList(),
              tone: tone,
              strokeWidth: 1.6,
              height: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgenticChipRail extends StatelessWidget {
  const _AgenticChipRail();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: const [
          _AgentChip(
            label: 'Open boarding pass',
            icon: Icons.qr_code_2_rounded,
            tone: B.jetCyan,
          ),
          _AgentChip(
            label: 'Convert €200 → ¥',
            icon: Icons.compare_arrows_rounded,
            tone: B.treasuryGreen,
          ),
          _AgentChip(
            label: 'Plan dinner in Tokyo',
            icon: Icons.restaurant_menu_rounded,
            tone: B.honeyAmber,
          ),
          _AgentChip(
            label: 'Renew Schengen visa',
            icon: Icons.workspace_premium_rounded,
            tone: B.diplomaticGarnet,
          ),
        ],
      ),
    );
  }
}

class _AgentChip extends StatelessWidget {
  const _AgentChip({
    required this.label,
    required this.icon,
    required this.tone,
  });
  final String label;
  final IconData icon;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: B.space2),
      child: BiblePressable(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: B.space3,
            vertical: B.space2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(B.rPill),
            color: tone.withValues(alpha: 0.10),
            border: Border.all(
              color: tone.withValues(alpha: 0.30),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: tone),
              const SizedBox(width: B.space1),
              BText.mono(label, size: 12, color: B.inkOnDarkHigh),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.city,
    required this.iata,
    required this.date,
    required this.tone,
    required this.icon,
  });
  final String city;
  final String iata;
  final String date;
  final Color tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return BiblePressable(
      onTap: () => context.go('/bible/trip'),
      child: BiblePremiumCard(
        tone: tone,
        padding: const EdgeInsets.fromLTRB(
          B.space4,
          B.space4,
          B.space4,
          B.space4,
        ),
        child: Row(
          children: [
            BibleGlyphHalo(icon: icon, tone: tone, size: 44),
            const SizedBox(width: B.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BText.eyebrow(date, color: tone),
                  const SizedBox(height: B.space1),
                  Row(
                    children: [
                      BText.title(city, size: 17),
                      const SizedBox(width: B.space2),
                      BText.monoCap(iata, color: B.inkOnDarkLow),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: B.inkOnDarkLow,
            ),
          ],
        ),
      ),
    );
  }
}

class _NowGrid extends StatelessWidget {
  const _NowGrid();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(
              child: _NowTile(
                eyebrow: 'home time',
                value: '09 : 42',
                caption: 'London · GMT+0',
                tone: B.polarBlue,
                icon: Icons.access_time_rounded,
              ),
            ),
            SizedBox(width: B.space3),
            Expanded(
              child: _NowTile(
                eyebrow: 'destination',
                value: '17 : 42',
                caption: 'Tokyo · JST+9',
                tone: B.jetCyan,
                icon: Icons.public_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: B.space3),
        Row(
          children: const [
            Expanded(
              child: _NowTile(
                eyebrow: 'identity score',
                value: '92',
                caption: '12 of 12 issuers',
                tone: B.foilGold,
                icon: Icons.workspace_premium_rounded,
              ),
            ),
            SizedBox(width: B.space3),
            Expanded(
              child: _NowTile(
                eyebrow: 'concierge',
                value: 'standby',
                caption: 'AGI · 3 jobs queued',
                tone: B.auroraViolet,
                icon: Icons.auto_awesome_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NowTile extends StatelessWidget {
  const _NowTile({
    required this.eyebrow,
    required this.value,
    required this.caption,
    required this.tone,
    required this.icon,
  });
  final String eyebrow;
  final String value;
  final String caption;
  final Color tone;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return BiblePremiumCard(
      tone: tone,
      padding: const EdgeInsets.all(B.space4),
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
          const SizedBox(height: B.space3),
          BText.solari(value, size: 24, color: B.inkOnDarkHigh),
          const SizedBox(height: B.space1),
          BText.caption(caption, color: B.inkOnDarkMid),
        ],
      ),
    );
  }
}

class _ConciergeOrb extends StatelessWidget {
  const _ConciergeOrb();
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, B.space5, B.space5),
        child: BiblePressable(
          onTap: () => context.go('/bible/passport'),
          child: BibleGlowPulse(
            tone: B.auroraViolet,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFF7C3AED),
                    Color(0xFF3B82F6),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.20),
                  width: 0.8,
                ),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
