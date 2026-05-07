import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/agentic_chip.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/cinematic_button.dart';
import '../../widgets/cinematic_hero.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/section_header.dart';

/// CountryProfileScreen — civilization-grade country dossier.
///
/// Replaces a thousand wiki tabs with one cinematic page: weather,
/// currency, plug, tipping, etiquette, do/don't, cultural insights,
/// and a chain of agentic next-steps wired into the rest of the app.
class CountryProfileScreen extends StatelessWidget {
  const CountryProfileScreen({
    super.key,
    this.country = 'Japan',
    this.flag = '🇯🇵',
    this.tone = const Color(0xFFE11D48),
  });

  final String country;
  final String flag;
  final Color tone;

  static const _stats = <(IconData, String, String)>[
    (Icons.thermostat_rounded, 'Weather', '17° clear'),
    (Icons.currency_yen_rounded, 'Currency', 'JPY · ¥1 = \$0.0064'),
    (Icons.power_rounded, 'Power', 'Type A · 100V'),
    (Icons.access_time_rounded, 'Time', 'JST · UTC+9'),
    (Icons.translate_rounded, 'Language', 'Japanese · 日本語'),
    (Icons.savings_rounded, 'Tipping', 'Not customary'),
  ];

  static const _dos = <(IconData, String)>[
    (Icons.front_hand_rounded, 'Bow when greeting'),
    (Icons.no_drinks_rounded, 'Stand left, walk right (Tokyo escalators)'),
    (Icons.wallet_rounded, 'Hand cash with two hands or on the tray'),
    (Icons.no_meals_rounded, 'Slurp ramen — it is a compliment'),
  ];

  static const _donts = <(IconData, String)>[
    (Icons.no_food_rounded, "Don't eat while walking"),
    (Icons.phone_disabled_rounded, "Don't take phone calls on trains"),
    (Icons.no_drinks_rounded, "Don't tip in restaurants"),
    (Icons.no_photography_rounded, "Don't photograph people without asking"),
  ];

  static const _insights = <(IconData, String, String)>[
    (Icons.savings_rounded, 'Cash still rules',
        'Many small ramen shops & shrines are cash-only. Withdraw at 7-Eleven.'),
    (Icons.train_rounded, 'IC card unlocks the country',
        'A Suica or Pasmo card pays trains, buses, vending machines, and most konbini.'),
    (Icons.spa_rounded, 'Onsen etiquette',
        'Wash thoroughly before entering the bath. Tattoos may be turned away — covers help.'),
    (Icons.emoji_food_beverage_rounded, 'Convenience-store gold',
        'Konbini sushi, onigiri, and sandwiches are surprisingly excellent. Embrace them.'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PageScaffold(
      title: 'Country profile',
      subtitle: '$flag $country · live dossier',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          AnimatedAppearance(
            child: CinematicHero(
              eyebrow: 'COUNTRY DOSSIER',
              title: country,
              subtitle: 'Everything your trip will need, on one page.',
              flag: flag,
              tone: tone,
              icon: Icons.public_rounded,
              badges: const [
                HeroBadge(label: 'Live weather', icon: Icons.cloud_rounded),
                HeroBadge(label: 'FX rate', icon: Icons.show_chart_rounded),
                HeroBadge(
                    label: 'Cultural intel', icon: Icons.menu_book_rounded),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space5),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 60),
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              mainAxisSpacing: AppTokens.space2,
              crossAxisSpacing: AppTokens.space2,
              children: [
                for (final s in _stats)
                  PremiumCard(
                    padding: const EdgeInsets.all(AppTokens.space3),
                    glass: false,
                    elevation: PremiumElevation.sm,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tone.withValues(alpha: 0.18),
                          ),
                          child: Icon(s.$1, color: tone, size: 16),
                        ),
                        Text(s.$3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            )),
                        Text(s.$2,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            )),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SectionHeader(
              title: 'Etiquette · Do',
              subtitle: 'Small things that will make locals smile'),
          for (var i = 0; i < _dos.length; i++)
            AnimatedAppearance(
              delay: Duration(milliseconds: 40 * i),
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.space2),
                child: PremiumCard(
                  padding: const EdgeInsets.all(AppTokens.space3),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF10B981)
                              .withValues(alpha: 0.18),
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Color(0xFF10B981), size: 18),
                      ),
                      const SizedBox(width: AppTokens.space3),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(_dos[i].$1, color: tone, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _dos[i].$2,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SectionHeader(
              title: "Etiquette · Don't",
              subtitle: 'Things that mark you as a tourist'),
          for (var i = 0; i < _donts.length; i++)
            AnimatedAppearance(
              delay: Duration(milliseconds: 40 * i),
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.space2),
                child: PremiumCard(
                  padding: const EdgeInsets.all(AppTokens.space3),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFDC2626)
                              .withValues(alpha: 0.18),
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Color(0xFFDC2626), size: 18),
                      ),
                      const SizedBox(width: AppTokens.space3),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(_donts[i].$1, color: tone, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _donts[i].$2,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SectionHeader(
              title: 'Cultural insights',
              subtitle: 'Why locals do what locals do'),
          for (var i = 0; i < _insights.length; i++)
            AnimatedAppearance(
              delay: Duration(milliseconds: 40 * i),
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.space2),
                child: PremiumCard(
                  padding: const EdgeInsets.all(AppTokens.space3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusLg),
                          color: tone.withValues(alpha: 0.18),
                        ),
                        child:
                            Icon(_insights[i].$1, color: tone, size: 20),
                      ),
                      const SizedBox(width: AppTokens.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_insights[i].$2,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                )),
                            const SizedBox(height: 4),
                            Text(_insights[i].$3,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                  height: 1.35,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppTokens.space4),
          AgenticBand(
            title: 'Common chains from here',
            chips: [
              AgenticChip(
                icon: Icons.translate_rounded,
                label: 'Phrasebook',
                eyebrow: 'language',
                route: '/phrasebook',
                tone: tone,
              ),
              const AgenticChip(
                icon: Icons.luggage_rounded,
                label: 'Packing list',
                eyebrow: 'prep',
                route: '/packing',
                tone: Color(0xFF7C3AED),
              ),
              const AgenticChip(
                icon: Icons.assignment_rounded,
                label: 'Customs form',
                eyebrow: 'arrival',
                route: '/customs',
                tone: Color(0xFF6366F1),
              ),
              const AgenticChip(
                icon: Icons.shield_rounded,
                label: 'Emergency',
                eyebrow: 'safety',
                route: '/emergency',
                tone: Color(0xFFDC2626),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          CinematicButton(
            label: 'Open my Travel OS for $country',
            icon: Icons.hub_rounded,
            gradient: LinearGradient(
              colors: [tone, tone.withValues(alpha: 0.55)],
            ),
            onPressed: () {
              HapticFeedback.heavyImpact();
              GoRouter.of(context).push('/travel-os');
            },
          ),
          const SizedBox(height: AppTokens.space9),
        ],
      ),
    );
  }
}
