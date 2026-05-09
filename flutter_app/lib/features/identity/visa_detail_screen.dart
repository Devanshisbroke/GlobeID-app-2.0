import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/cinematic_button.dart';
import '../../widgets/cinematic_hero.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium/premium.dart';
import '../../widgets/section_header.dart';

/// Visa detail surface — picks up `country` + `tone` from the route
/// and renders a sealed crest + readiness ring + expiry countdown.
/// Pure-Dart, deterministic.
class VisaDetailScreen extends StatelessWidget {
  const VisaDetailScreen({
    super.key,
    this.country = 'Japan',
    this.flag = '🇯🇵',
    this.tone = const Color(0xFFE11D48),
    this.percent = 0.86,
    this.daysToExpiry = 213,
    this.visaType = 'Tourist · 90 days',
  });

  final String country;
  final String flag;
  final Color tone;
  final double percent;
  final int daysToExpiry;
  final String visaType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PageScaffold(
      title: 'Visa · $country',
      subtitle: '$flag $visaType',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          AnimatedAppearance(
            child: CinematicHero(
              eyebrow: 'TRAVEL DOC',
              title: '$country visa',
              subtitle: '$visaType · expires in $daysToExpiry days',
              icon: Icons.verified_user_rounded,
              tone: tone,
              flag: flag,
              badges: [
                const HeroBadge(
                  label: 'Sealed',
                  icon: Icons.lock_rounded,
                ),
                HeroBadge(
                  label: '$daysToExpiry days',
                  icon: Icons.event_rounded,
                ),
                const HeroBadge(
                  label: 'eVisa',
                  icon: Icons.verified_rounded,
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Readiness', dense: true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space5),
            child: AnimatedAppearance(
              delay: const Duration(milliseconds: 80),
              child: ContextualSurface(
                child: Row(
                  children: [
                    VisaReadinessRing(
                      percent: percent,
                      label: 'Sealed',
                      tone: tone,
                    ),
                    const SizedBox(width: AppTokens.space4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Travel-doc readiness',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Visa sealed, biometric verified, '
                            'no exit-ban flags. Ready to fly.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
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
          const SectionHeader(title: 'Expiry'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space5),
            child: AnimatedAppearance(
              delay: const Duration(milliseconds: 120),
              child: ContextualSurface(
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: tone, size: 28),
                    const SizedBox(width: AppTokens.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$daysToExpiry days remaining',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Renew automatically when within 30 days.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
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
          const SizedBox(height: AppTokens.space5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space5),
            child: AnimatedAppearance(
              delay: const Duration(milliseconds: 160),
              child: Row(
                children: [
                  Expanded(
                    child: CinematicButton(
                      label: 'View in vault',
                      icon: Icons.shield_moon_rounded,
                      onPressed: () => context.push('/vault'),
                    ),
                  ),
                  const SizedBox(width: AppTokens.space2),
                  Expanded(
                    child: CinematicButton(
                      label: 'Ask copilot',
                      icon: Icons.smart_toy_rounded,
                      onPressed: () => context.push('/copilot'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space9),
        ],
      ),
    );
  }
}
