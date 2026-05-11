import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../os2_tokens.dart';
import '../primitives/os2_beacon.dart';
import '../primitives/os2_chip.dart';
import '../primitives/os2_magnetic.dart';
import '../primitives/os2_slab.dart';
import '../primitives/os2_solari.dart';
import '../primitives/os2_text.dart';
import '../primitives/os2_world_header.dart';

/// OS 2.0 — Discover world.
///
/// Destination atlas. No map. No arc. No globe. Pure typographic +
/// spatial cinematic full-bleed slabs. Hierarchy:
///   1. World header (Discover · GMT · CURATING beacon).
///   2. Atlas — vertical stack of full-bleed destination slabs. Each
///      slab is a single city: city name as huge display, country
///      caption, GMT offset Solari, ambient mood gradient, tagline.
///   3. Intelligence section — briefing cards (typographic).
///   4. Smart deals — typographic ribbon rows.
class DiscoverWorld extends ConsumerWidget {
  const DiscoverWorld({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Os2WorldHeader(
              world: Os2World.discover,
              title: 'Atlas',
              subtitle: 'Curated cities \u00b7 intelligence briefings',
              beacon: 'CURATING',
            ),
            const SizedBox(height: Os2.space4),
            // Atlas — full-bleed vertical destination slabs.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
              child: Column(
                children: [
                  for (int i = 0; i < _atlas.length; i++) ...[
                    _DestinationSlab(entry: _atlas[i]),
                    if (i < _atlas.length - 1)
                      const SizedBox(height: Os2.space4),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Os2.space6),
            // Intelligence.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Os2.space5),
              child: _SectionLabel(label: 'INTELLIGENCE'),
            ),
            const SizedBox(height: Os2.space3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
              child: Column(
                children: const [
                  _BriefingSlab(
                    tone: Os2.discoverTone,
                    tag: 'TRAVEL \u00b7 4 MIN READ',
                    title:
                        'Why FRA \u2192 JFK departures clustered after 16:00 this week',
                    body:
                        'Jet-stream anomaly over the North Atlantic. 9% longer westbound times until Sunday.',
                  ),
                  SizedBox(height: Os2.space3),
                  _BriefingSlab(
                    tone: Os2.walletTone,
                    tag: 'MONEY \u00b7 2 MIN READ',
                    title:
                        'EUR / USD breaks 1.087 \u2014 best mid-rate this quarter',
                    body:
                        'If you\'re settling USD invoices, today is statistically the strongest moment in 87 days.',
                  ),
                  SizedBox(height: Os2.space3),
                  _BriefingSlab(
                    tone: Os2.identityTone,
                    tag: 'IDENTITY \u00b7 1 MIN READ',
                    title: 'Your tier ramp accelerated this month',
                    body:
                        '+12 pts from issuer cross-sign verifications. 28 pts to Sovereign tier.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: Os2.space6),
            // Smart deals.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Os2.space5),
              child: _SectionLabel(label: 'SMART DEALS'),
            ),
            const SizedBox(height: Os2.space3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
              child: Column(
                children: const [
                  _DealStrip(
                    icon: Icons.airline_seat_flat_rounded,
                    title: 'Lufthansa Senator upgrade',
                    sub: 'Match offer \u00b7 expires 36h',
                    badge: '-\u20ac420',
                    tone: Os2.identityTone,
                  ),
                  _DealStrip(
                    icon: Icons.hotel_rounded,
                    title: 'Marriott Bonvoy points double',
                    sub: 'Tokyo + Osaka stays through 30 Apr',
                    badge: '2\u00d7 pts',
                    tone: Os2.servicesTone,
                  ),
                  _DealStrip(
                    icon: Icons.sim_card_rounded,
                    title: 'Airalo eSIM Eurolink',
                    sub: '10 GB region pack',
                    badge: '-25%',
                    tone: Os2.discoverTone,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 18, height: 1, color: Os2.discoverTone.withValues(alpha: 0.55)),
        const SizedBox(width: 8),
        Os2Text.caption(label, color: Os2.discoverTone),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────── Atlas data

class _AtlasEntry {
  const _AtlasEntry({
    required this.city,
    required this.country,
    required this.flag,
    required this.gmt,
    required this.mood,
    required this.tagline,
    required this.code,
    required this.tone,
  });
  final String city;
  final String country;
  final String flag;
  final String gmt;
  final String mood;
  final String tagline;
  final String code;
  final Color tone;
}

const _atlas = [
  _AtlasEntry(
    city: 'Tokyo',
    country: 'Japan',
    flag: '🇯🇵',
    gmt: 'GMT+9',
    mood: 'CHERRY BLOSSOM WINDOW',
    tagline: 'Sakura peak 28 Mar \u2014 3 Apr \u00b7 FRA \u2192 NRT from \u20ac642 r/t.',
    code: 'NRT',
    tone: Os2.discoverTone,
  ),
  _AtlasEntry(
    city: 'Lisbon',
    country: 'Portugal',
    flag: '🇵🇹',
    gmt: 'GMT+1',
    mood: 'LATE SPRING CALM',
    tagline: 'Shoulder season \u00b7 mild Atlantic light \u00b7 LIS rooms from \u20ac128.',
    code: 'LIS',
    tone: Os2.servicesTone,
  ),
  _AtlasEntry(
    city: 'Reykjavík',
    country: 'Iceland',
    flag: '🇮🇸',
    gmt: 'GMT+0',
    mood: 'AURORA WINDOW CLOSING',
    tagline: 'Last 11 days of strong forecast \u00b7 KEF direct from CDG \u20ac318.',
    code: 'KEF',
    tone: Os2.travelTone,
  ),
  _AtlasEntry(
    city: 'Singapore',
    country: 'Singapore',
    flag: '🇸🇬',
    gmt: 'GMT+8',
    mood: 'MONSOON BREAK',
    tagline: 'Two weeks dry forecast \u00b7 SIN \u2192 KUL day trips < \u20ac80.',
    code: 'SIN',
    tone: Os2.discoverTone,
  ),
  _AtlasEntry(
    city: 'Marrakech',
    country: 'Morocco',
    flag: '🇲🇦',
    gmt: 'GMT+1',
    mood: 'DESERT NIGHT WINDOW',
    tagline: 'Riad rates -22% \u00b7 RAK direct from FRA from \u20ac184.',
    code: 'RAK',
    tone: Os2.pulseTone,
  ),
];

class _DestinationSlab extends StatelessWidget {
  const _DestinationSlab({required this.entry});
  final _AtlasEntry entry;

  @override
  Widget build(BuildContext context) {
    return Os2Magnetic(
      onTap: () => GoRouter.of(context).push('/country/${entry.code}'),
      child: Os2Slab(
        tone: entry.tone,
        tier: Os2SlabTier.floor2,
        radius: Os2.rHero,
        halo: Os2SlabHalo.full,
        elevation: Os2SlabElevation.raised,
        padding: const EdgeInsets.all(Os2.space5),
        breath: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(entry.flag, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Os2Text.caption(entry.country.toUpperCase(),
                    color: Os2.inkLow),
                const Spacer(),
                Os2Beacon(label: entry.mood, tone: entry.tone),
              ],
            ),
            const SizedBox(height: Os2.space3),
            Os2Text.display(
              entry.city,
              color: Os2.inkBright,
              size: 48,
              maxLines: 1,
            ),
            const SizedBox(height: Os2.space2),
            Os2Text.body(
              entry.tagline,
              color: Os2.inkMid,
              size: 13,
              maxLines: 3,
            ),
            const SizedBox(height: Os2.space4),
            Row(
              children: [
                Os2Solari(
                  text: entry.code,
                  tone: entry.tone,
                  cellWidth: 18,
                  cellHeight: 26,
                  fontSize: 18,
                ),
                const SizedBox(width: 10),
                Container(width: 1, height: 18, color: Os2.hairline),
                const SizedBox(width: 10),
                Os2Text.monoCap(entry.gmt, color: entry.tone),
                const Spacer(),
                Os2Chip(
                  label: 'PLAN TRIP',
                  tone: entry.tone,
                  icon: Icons.flight_takeoff_rounded,
                  intensity: Os2ChipIntensity.solid,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BriefingSlab extends StatelessWidget {
  const _BriefingSlab({
    required this.tone,
    required this.tag,
    required this.title,
    required this.body,
  });
  final Color tone;
  final String tag;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Os2Slab(
      tone: tone,
      radius: Os2.rCard,
      tier: Os2SlabTier.floor1,
      halo: Os2SlabHalo.corner,
      elevation: Os2SlabElevation.resting,
      padding: const EdgeInsets.all(Os2.space4),
      breath: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Os2Text.caption(tag, color: tone),
          const SizedBox(height: Os2.space2),
          Os2Text.title(title, color: Os2.inkBright, size: 16, maxLines: 2),
          const SizedBox(height: 6),
          Os2Text.body(body, color: Os2.inkMid, size: 13, maxLines: 3),
        ],
      ),
    );
  }
}

class _DealStrip extends StatelessWidget {
  const _DealStrip({
    required this.icon,
    required this.title,
    required this.sub,
    required this.badge,
    required this.tone,
  });
  final IconData icon;
  final String title;
  final String sub;
  final String badge;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Os2.space3),
      child: Os2Slab(
        tone: tone,
        radius: Os2.rCard,
        tier: Os2SlabTier.floor1,
        halo: Os2SlabHalo.corner,
        elevation: Os2SlabElevation.resting,
        padding: const EdgeInsets.symmetric(
          horizontal: Os2.space4,
          vertical: Os2.space4,
        ),
        breath: false,
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: tone.withValues(alpha: 0.32),
                  width: Os2.strokeFine,
                ),
              ),
              child: Icon(icon, color: tone, size: 17),
            ),
            const SizedBox(width: Os2.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Os2Text.title(title,
                      color: Os2.inkBright, size: 14, maxLines: 1),
                  const SizedBox(height: 2),
                  Os2Text.body(sub, color: Os2.inkMid, size: 12, maxLines: 1),
                ],
              ),
            ),
            Os2Chip(label: badge, tone: tone, intensity: Os2ChipIntensity.solid),
          ],
        ),
      ),
    );
  }
}
