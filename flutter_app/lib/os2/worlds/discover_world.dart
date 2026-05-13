import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/identity_tier.dart';
import '../../features/trip/trip_country_intel.dart';
import '../../features/user/user_provider.dart';
import '../../motion/haptic_refresh.dart';
import '../os2_tokens.dart';
import '../primitives/os2_action_card.dart';
import '../primitives/os2_beacon.dart';
import '../primitives/os2_chip.dart';
import '../primitives/os2_divider_rule.dart';
import '../primitives/os2_info_strip.dart';
import '../primitives/os2_magnetic.dart';
import '../primitives/os2_marquee.dart';
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
class DiscoverWorld extends ConsumerStatefulWidget {
  const DiscoverWorld({super.key});

  @override
  ConsumerState<DiscoverWorld> createState() => _DiscoverWorldState();
}

class _DiscoverWorldState extends ConsumerState<DiscoverWorld> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final tier = IdentityTier.forScore(user.profile.identityScore);
    final tierIdx = IdentityTier.tiers.indexOf(tier);
    final nextTier = tierIdx < IdentityTier.tiers.length - 1
        ? IdentityTier.tiers[tierIdx + 1]
        : null;
    final ptsToNext = nextTier == null
        ? 0
        : (nextTier.threshold - user.profile.identityScore).clamp(0, 1000);
    // Marquee numbers anchored to real data so they don't read like
    // fiction. Atlas count is the real curated atlas length, deals
    // and briefings stay typographic counts but match the rest of
    // the world.
    final atlasCount = _atlas.length;
    final briefings = 3 + (user.records.length ~/ 2).clamp(0, 6);

    return SafeArea(
      bottom: false,
      child: HapticRefresh(
        onRefresh: () => ref.read(userProvider.notifier).hydrate(),
        color: Os2.discoverTone,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
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
            const SizedBox(height: Os2.space2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
              child: Os2Marquee(
                items: [
                  'CURATING \u00b7 $atlasCount CITIES',
                  'INTEL \u00b7 $briefings BRIEFINGS THIS WEEK',
                  'SMART DEALS \u00b7 LIVE',
                  'CONCIERGE \u00b7 STANDING BY',
                  'TIER \u00b7 ${tier.label.toUpperCase()}',
                ],
                tone: Os2.discoverTone,
              ),
            ),
            const SizedBox(height: Os2.space3),
            Os2InfoStrip(
              entries: [
                Os2InfoEntry(
                  icon: Icons.flight_takeoff_rounded,
                  label: 'FLIGHTS',
                  value: 'BROWSE',
                  tone: Os2.travelTone,
                  onTap: () => GoRouter.of(context).push('/flights'),
                ),
                Os2InfoEntry(
                  icon: Icons.hotel_rounded,
                  label: 'HOTELS',
                  value: 'BROWSE',
                  tone: Os2.identityTone,
                  onTap: () => GoRouter.of(context).push('/hotels'),
                ),
                Os2InfoEntry(
                  icon: Icons.restaurant_rounded,
                  label: 'DINING',
                  value: 'NEAR',
                  tone: Os2.servicesTone,
                  onTap: () => GoRouter.of(context).push('/restaurants'),
                ),
                Os2InfoEntry(
                  icon: Icons.directions_car_rounded,
                  label: 'TRANSPORT',
                  value: 'PLAN',
                  tone: Os2.travelTone,
                  onTap: () => GoRouter.of(context).push('/transport'),
                ),
                Os2InfoEntry(
                  icon: Icons.museum_rounded,
                  label: 'CULTURE',
                  value: 'EXPLORE',
                  tone: Os2.discoverTone,
                ),
              ],
            ),
            const SizedBox(height: Os2.space4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
              child: _DiscoverActionGrid(),
            ),
            const SizedBox(height: Os2.space5),
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
                children: [
                  const _BriefingSlab(
                    tone: Os2.discoverTone,
                    tag: 'TRAVEL \u00b7 4 MIN READ',
                    title:
                        'Why FRA \u2192 JFK departures clustered after 16:00 this week',
                    body:
                        'Jet-stream anomaly over the North Atlantic. 9% longer westbound times until Sunday.',
                  ),
                  const SizedBox(height: Os2.space3),
                  const _BriefingSlab(
                    tone: Os2.walletTone,
                    tag: 'MONEY \u00b7 2 MIN READ',
                    title:
                        'EUR / USD breaks 1.087 \u2014 best mid-rate this quarter',
                    body:
                        'If you\'re settling USD invoices, today is statistically the strongest moment in 87 days.',
                  ),
                  const SizedBox(height: Os2.space3),
                  // Identity tier briefing derived from the user's
                  // real identity score + the next-tier threshold,
                  // so the "Sovereign in 28 pts" string actually
                  // matches the bearer instead of being fixed.
                  _BriefingSlab(
                    tone: Os2.identityTone,
                    tag: 'IDENTITY \u00b7 1 MIN READ',
                    title: nextTier == null
                        ? 'You\'re at the top of the tier ladder'
                        : 'Your tier ramp accelerated this month',
                    body: nextTier == null
                        ? 'All issuer cross-signs current. Sovereign tier retained.'
                        : 'Identity score ${user.profile.identityScore} / 1000. '
                            '$ptsToNext pts to ${nextTier.label} tier.',
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
                children: [
                  _DealStrip(
                    icon: Icons.airline_seat_flat_rounded,
                    title: 'Lufthansa Senator upgrade',
                    sub: 'Match offer \u00b7 expires 36h',
                    badge: '-\u20ac420',
                    tone: Os2.identityTone,
                    onTap: () => GoRouter.of(context).push('/flights'),
                  ),
                  _DealStrip(
                    icon: Icons.hotel_rounded,
                    title: 'Marriott Bonvoy points double',
                    sub: 'Tokyo + Osaka stays through 30 Apr',
                    badge: '2\u00d7 pts',
                    tone: Os2.servicesTone,
                    onTap: () => GoRouter.of(context).push('/hotels'),
                  ),
                  _DealStrip(
                    icon: Icons.sim_card_rounded,
                    title: 'Airalo eSIM Eurolink',
                    sub: '10 GB region pack',
                    badge: '-25%',
                    tone: Os2.discoverTone,
                    onTap: () => GoRouter.of(context).push('/esim'),
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
    // Resolve the destination IATA → ISO-2 country code so the tap
    // bloom lands on the right Country Live page. Previously the
    // route was `/country/<IATA>` which 404'd into the catch-all
    // CountryProfileScreen with no country context.
    final iso2 = CountryIntel.fromIata(entry.code).iso2;
    return Os2Magnetic(
      onTap: () =>
          GoRouter.of(context).push('/country-live/$iso2'),
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
                Os2Magnetic(
                  onTap: () =>
                      GoRouter.of(context).push('/itinerary'),
                  child: Os2Chip(
                    label: 'PLAN TRIP',
                    tone: entry.tone,
                    icon: Icons.flight_takeoff_rounded,
                    intensity: Os2ChipIntensity.solid,
                  ),
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
          Os2Text.title(title, color: Os2.inkBright, size: Os2.textLg, maxLines: 2),
          const SizedBox(height: 6),
          Os2Text.body(body, color: Os2.inkMid, size: Os2.textMd, maxLines: 3),
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
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String sub;
  final String badge;
  final Color tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Os2.space3),
      child: Os2Magnetic(
        onTap: onTap ?? () {},
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
                  Os2Text.body(sub, color: Os2.inkMid, size: Os2.textSm, maxLines: 1),
                ],
              ),
            ),
            Os2Chip(label: badge, tone: tone, intensity: Os2ChipIntensity.solid),
          ],
        ),
      ),
      ),
    );
  }
}

// ─────────────────────────────────────────── Discover action grid

class _DiscoverActionGrid extends StatelessWidget {
  const _DiscoverActionGrid();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _Act('Curate trip', Icons.tune_rounded, Os2.discoverTone, '/itinerary'),
      _Act('Smart routes', Icons.alt_route_rounded, Os2.travelTone,
          '/travel-os'),
      _Act('Visa scout', Icons.assignment_turned_in_rounded,
          Os2.identityTone, '/visa'),
      _Act('Concierge brief', Icons.psychology_rounded, Os2.pulseTone,
          '/copilot'),
    ];
    return Column(
      children: [
        Os2DividerRule(
          eyebrow: 'INTELLIGENCE',
          tone: Os2.discoverTone,
          trailing: 'AGI · IDLE',
        ),
        const SizedBox(height: Os2.space3),
        Row(
          children: [
            for (var i = 0; i < 2; i++) ...[
              Expanded(
                child: Os2ActionCard(
                  title: actions[i].title,
                  icon: actions[i].icon,
                  tone: actions[i].tone,
                  caption: 'Tap to summon',
                  dense: true,
                  onTap: () => GoRouter.of(context).push(actions[i].route),
                ),
              ),
              if (i == 0) const SizedBox(width: Os2.space3),
            ],
          ],
        ),
        const SizedBox(height: Os2.space3),
        Row(
          children: [
            for (var i = 2; i < 4; i++) ...[
              Expanded(
                child: Os2ActionCard(
                  title: actions[i].title,
                  icon: actions[i].icon,
                  tone: actions[i].tone,
                  caption: 'Tap to summon',
                  dense: true,
                  onTap: () => GoRouter.of(context).push(actions[i].route),
                ),
              ),
              if (i == 2) const SizedBox(width: Os2.space3),
            ],
          ],
        ),
      ],
    );
  }
}

class _Act {
  const _Act(this.title, this.icon, this.tone, this.route);
  final String title;
  final IconData icon;
  final Color tone;
  final String route;
}
