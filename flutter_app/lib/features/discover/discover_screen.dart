import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../../widgets/section_header.dart';

/// Discover — flagship intelligence feed for the GlobeID ecosystem.
///
/// Mirrors the original TS Discover surface: a long, layered scroll
/// of premium cards aggregating travel intel, FX moves, route alerts,
/// social signals, weather windows, and visa changes. Each card type
/// has its own visual personality (color, glyph, density) but all
/// inherit the same PremiumCard glass treatment.
class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageScaffold(
      title: 'Discover',
      subtitle: 'Briefings, alerts, signals tuned for you',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // Filter strip.
          AnimatedAppearance(
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemCount: 7,
                itemBuilder: (_, i) {
                  final f = const [
                    'For you',
                    'Travel',
                    'Identity',
                    'Money',
                    'Weather',
                    'Visa',
                    'Social',
                  ][i];
                  return _FilterChip(label: f, selected: i == 0);
                },
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space4),

          // Featured destination hero.
          const SectionHeader(title: 'Featured destination', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 80),
            child: _FeaturedHero(
              accent: const Color(0xFF06B6D4),
              tag: 'Cherry-blossom window opens',
              title: 'Tokyo · Japan',
              body:
                  'Your Sakura window predicts peak bloom 28 Mar – 3 Apr. Direct flights from FRA from €642 r/t.',
              cta: 'Plan trip',
              onTap: () {},
            ),
          ),

          // Intelligence briefings.
          const SectionHeader(title: 'Intelligence briefings', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 120),
            child: _BriefingCard(
              icon: Icons.flight_rounded,
              tone: const Color(0xFF3B82F6),
              tag: 'TRAVEL · 4 MIN READ',
              title: 'Why FRA → JFK departures clustered after 16:00 this week',
              body:
                  'A jet-stream anomaly over the North Atlantic shifted optimal departure windows. Expect 9% longer westbound times until Sunday.',
            ),
          ),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 160),
            child: _BriefingCard(
              icon: Icons.account_balance_wallet_rounded,
              tone: const Color(0xFF10B981),
              tag: 'MONEY · 2 MIN READ',
              title: 'EUR/USD breaks 1.087 — best mid-rate this quarter',
              body:
                  'If you\'re settling USD invoices, today is statistically the strongest moment to convert in the last 87 days.',
            ),
          ),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 200),
            child: _BriefingCard(
              icon: Icons.shield_rounded,
              tone: const Color(0xFF7C3AED),
              tag: 'IDENTITY · 1 MIN READ',
              title: 'Your tier ramp accelerated this month',
              body:
                  '+12 pts from issuer cross-sign verifications. You\'re 28 pts away from Sovereign tier.',
            ),
          ),

          // Deals.
          const SectionHeader(title: 'Smart deals', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 240),
            child: _DealCard(
              title: 'Lufthansa Senator upgrade',
              sub: 'Match offer · -€420 · expires 36h',
              badge: '-€420',
              tone: const Color(0xFFD4AF37),
              icon: Icons.airline_seat_flat_rounded,
            ),
          ),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 280),
            child: _DealCard(
              title: 'Marriott Bonvoy points double',
              sub: 'Tokyo + Osaka · stays through 30 Apr',
              badge: '2× pts',
              tone: const Color(0xFFE11D48),
              icon: Icons.hotel_rounded,
            ),
          ),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 320),
            child: _DealCard(
              title: 'Airalo eSIM region pack',
              sub: 'Eurolink 10 GB · -25%',
              badge: '-25%',
              tone: const Color(0xFF06B6D4),
              icon: Icons.sim_card_rounded,
            ),
          ),

          // Weather windows.
          const SectionHeader(title: 'Weather windows', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 360),
            child: _WindowCard(
              icon: Icons.wb_sunny_rounded,
              tone: const Color(0xFFF59E0B),
              place: 'Lisbon · Portugal',
              window: '7 clear days',
              detail: '24–28 Mar · highs 22°, lows 14°',
            ),
          ),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 380),
            child: _WindowCard(
              icon: Icons.ac_unit_rounded,
              tone: const Color(0xFF3B82F6),
              place: 'Niseko · Japan',
              window: 'Final powder week',
              detail: '60 cm fresh expected · season closes 6 Apr',
            ),
          ),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 400),
            child: _WindowCard(
              icon: Icons.water_drop_rounded,
              tone: const Color(0xFF06B6D4),
              place: 'Bali · Indonesia',
              window: 'Dry season starts',
              detail: '< 4 mm rainfall predicted Apr–Sep',
            ),
          ),

          // Visa changes.
          const SectionHeader(title: 'Visa changes', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 440),
            child: _AlertCard(
              icon: Icons.assignment_ind_rounded,
              tone: const Color(0xFF10B981),
              tag: 'VISA-FREE',
              title: 'Schengen → UK now 6 months visa-free',
              detail: 'Effective 1 Apr · valid for tourism + business',
            ),
          ),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 480),
            child: _AlertCard(
              icon: Icons.warning_amber_rounded,
              tone: const Color(0xFFE11D48),
              tag: 'TIGHTENING',
              title: 'India e-Visa — biometric appointment now required',
              detail:
                  'Applies to first-time applicants from 15 Apr. Plan extra 4–6 days.',
            ),
          ),

          // Route alerts.
          const SectionHeader(title: 'Route alerts', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 520),
            child: _AlertCard(
              icon: Icons.alt_route_rounded,
              tone: const Color(0xFFEAB308),
              tag: 'REROUTE',
              title: 'Eurowings adjusts FRA → BCN via MAD this week',
              detail: 'Adds ~38 min to typical journey. Auto-applied to TRP-002.',
            ),
          ),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 540),
            child: _AlertCard(
              icon: Icons.flight_takeoff_rounded,
              tone: const Color(0xFF06B6D4),
              tag: 'NEW ROUTE',
              title: 'United launches non-stop FRA → ORD',
              detail: 'Mid-May launch. Star Alliance miles eligible.',
            ),
          ),

          // Social signals.
          const SectionHeader(title: 'Social signals', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 580),
            child: _SocialCard(
              avatar: 'MK',
              name: 'Mira K.',
              detail: 'just landed in Tokyo · 2h ago',
              tone: const Color(0xFFEC4899),
            ),
          ),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 600),
            child: _SocialCard(
              avatar: 'AS',
              name: 'Alex S.',
              detail: 'is at Senator Lounge · FRA · A22',
              tone: const Color(0xFF7C3AED),
            ),
          ),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 620),
            child: _SocialCard(
              avatar: 'JV',
              name: 'Jonas V.',
              detail: 'unlocked Sovereign tier · 4h ago',
              tone: const Color(0xFFD4AF37),
            ),
          ),

          const SizedBox(height: AppTokens.space9),
        ],
      ),
    );
  }
}

// ── Cards ─────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected});
  final String label;
  final bool selected;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final accent = t.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected
            ? accent.withValues(alpha: 0.18)
            : t.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        border: Border.all(
          color: selected
              ? accent
              : t.colorScheme.onSurface.withValues(alpha: 0.10),
        ),
      ),
      child: Text(label,
          style: TextStyle(
            color: selected ? accent : t.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          )),
    );
  }
}

class _FeaturedHero extends StatelessWidget {
  const _FeaturedHero({
    required this.accent,
    required this.tag,
    required this.title,
    required this.body,
    required this.cta,
    required this.onTap,
  });
  final Color accent;
  final String tag;
  final String title;
  final String body;
  final String cta;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: PremiumCard(
        padding: const EdgeInsets.all(AppTokens.space5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.32),
            accent.withValues(alpha: 0.10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppTokens.radiusFull),
              ),
              child: Text(tag,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  )),
            ),
            const SizedBox(height: AppTokens.space3),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppTokens.space3),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius:
                        BorderRadius.circular(AppTokens.radiusFull),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(cta,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 16),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BriefingCard extends StatelessWidget {
  const _BriefingCard({
    required this.icon,
    required this.tone,
    required this.tag,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final Color tone;
  final String tag;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
            ),
            child: Icon(icon, color: tone),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tag,
                    style: TextStyle(
                      color: tone,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 0.8,
                    )),
                const SizedBox(height: 4),
                Text(title,
                    style: t.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(body, style: t.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  const _DealCard({
    required this.title,
    required this.sub,
    required this.badge,
    required this.tone,
    required this.icon,
  });
  final String title;
  final String sub;
  final String badge;
  final Color tone;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space3),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          ),
          child: Icon(icon, color: tone),
        ),
        const SizedBox(width: AppTokens.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: t.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              Text(sub,
                  style: t.textTheme.bodySmall?.copyWith(
                      color:
                          t.colorScheme.onSurface.withValues(alpha: 0.60))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          ),
          child: Text(badge,
              style: TextStyle(
                color: tone,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.4,
              )),
        ),
      ]),
    );
  }
}

class _WindowCard extends StatelessWidget {
  const _WindowCard({
    required this.icon,
    required this.tone,
    required this.place,
    required this.window,
    required this.detail,
  });
  final IconData icon;
  final Color tone;
  final String place;
  final String window;
  final String detail;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tone, size: 24),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(place,
                        style: t.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  Text(window,
                      style: TextStyle(
                          color: tone,
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                ]),
                const SizedBox(height: 2),
                Text(detail,
                    style: t.textTheme.bodySmall?.copyWith(
                        color: t.colorScheme.onSurface
                            .withValues(alpha: 0.60))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.icon,
    required this.tone,
    required this.tag,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final Color tone;
  final String tag;
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space3),
      borderColor: tone.withValues(alpha: 0.30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tone, size: 24),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.18),
                    borderRadius:
                        BorderRadius.circular(AppTokens.radiusFull),
                  ),
                  child: Text(tag,
                      style: TextStyle(
                          color: tone,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 0.6)),
                ),
                const SizedBox(height: 6),
                Text(title,
                    style: t.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(detail,
                    style: t.textTheme.bodySmall?.copyWith(
                        color: t.colorScheme.onSurface
                            .withValues(alpha: 0.60))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialCard extends StatelessWidget {
  const _SocialCard({
    required this.avatar,
    required this.name,
    required this.detail,
    required this.tone,
  });
  final String avatar;
  final String name;
  final String detail;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space3),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [tone, tone.withValues(alpha: 0.55)],
            ),
          ),
          child: Text(avatar,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              )),
        ),
        const SizedBox(width: AppTokens.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: t.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              Text(detail,
                  style: t.textTheme.bodySmall?.copyWith(
                      color:
                          t.colorScheme.onSurface.withValues(alpha: 0.60))),
            ],
          ),
        ),
        Icon(Icons.chevron_right_rounded,
            color: t.colorScheme.onSurface.withValues(alpha: 0.32)),
      ]),
    );
  }
}
