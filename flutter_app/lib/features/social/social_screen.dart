import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';

/// Social v2 — placeholder that still feels premium. Hero card with
/// gradient bloom, follow-suggestion list, soft locked state.
class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const suggestions = [
      ('Aria', '12 trips · GBP', '🇬🇧'),
      ('Kenji', '8 trips · JPY', '🇯🇵'),
      ('Marcus', '21 trips · USD', '🇺🇸'),
      ('Lina', '6 trips · EUR', '🇩🇪'),
    ];
    return PageScaffold(
      title: 'Social',
      subtitle: 'Follow your traveller circle',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          AnimatedAppearance(
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space7),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFEC4899).withValues(alpha: 0.32),
                  const Color(0xFF7C3AED).withValues(alpha: 0.18),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.group_rounded,
                      color: Colors.white, size: 32),
                  const SizedBox(height: AppTokens.space4),
                  Text('Coming online soon',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      )),
                  const SizedBox(height: AppTokens.space2),
                  Text(
                      'Follow friends, share pinned trips, and react to milestones across your traveller network.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.5,
                      )),
                ],
              ),
            ),
          ),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 120),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, AppTokens.space5, 0, 0),
              child: Text('Suggested travellers',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    letterSpacing: 0.6,
                  )),
            ),
          ),
          for (var i = 0; i < suggestions.length; i++)
            AnimatedAppearance(
              delay: Duration(milliseconds: 200 + 60 * i),
              child: Padding(
                padding: const EdgeInsets.only(top: AppTokens.space3),
                child: PremiumCard(
                  padding: const EdgeInsets.all(AppTokens.space4),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.6),
                              theme.colorScheme.primary.withValues(alpha: 0.2),
                            ],
                          ),
                        ),
                        child: Text(suggestions[i].$3,
                            style: const TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: AppTokens.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(suggestions[i].$1,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                )),
                            Text(suggestions[i].$2,
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Pressable(
                        scale: 0.96,
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusFull),
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.12),
                            border: Border.all(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.32)),
                          ),
                          child: Text('Follow',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              )),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
