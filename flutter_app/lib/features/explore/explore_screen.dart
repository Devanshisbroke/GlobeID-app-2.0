import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../insights/insights_provider.dart';

/// Explore v2 — premium curation of place / activity / food
/// suggestions with hero gradient cards, brand accent dot, pressable.
class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  static const _accents = [
    Color(0xFF7C3AED),
    Color(0xFF06B6D4),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF3B82F6),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reco = ref.watch(recommendationsProvider);
    final theme = Theme.of(context);
    return PageScaffold(
      title: 'Explore',
      subtitle: 'Curated for your next destination',
      body: reco.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          title: 'Recommendations unavailable',
          message: e.toString(),
          icon: Icons.cloud_off_rounded,
        ),
        data: (data) {
          final items = ((data['items'] as List?) ?? const [])
              .cast<Map<String, dynamic>>();
          if (items.isEmpty) {
            return const EmptyState(
              title: 'No recommendations yet',
              message: 'Add a trip and we\'ll surface things to do.',
              icon: Icons.travel_explore_rounded,
            );
          }
          return ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              AnimatedAppearance(
                child: PremiumCard(
                  padding: const EdgeInsets.all(AppTokens.space5),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.34),
                      theme.colorScheme.primary.withValues(alpha: 0.06),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusFull),
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                          child: Text('FOR YOU',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                              )),
                        ),
                      ]),
                      const SizedBox(height: AppTokens.space3),
                      Text('${items.length} ideas to explore',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          )),
                      const SizedBox(height: 4),
                      Text(
                        'Hand-picked from your trip context — places, food, activities.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space4),
              for (var i = 0; i < items.length; i++)
                AnimatedAppearance(
                  delay: Duration(milliseconds: 60 * i),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.space3),
                    child: _ExploreRow(
                      item: items[i],
                      tone: _accents[i % _accents.length],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ExploreRow extends StatelessWidget {
  const _ExploreRow({required this.item, required this.tone});
  final Map<String, dynamic> item;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kind = (item['kind'] ?? item['type'] ?? '').toString().toLowerCase();
    final icon = _iconFor(kind);
    return Pressable(
      scale: 0.98,
      onTap: () => HapticFeedback.lightImpact(),
      child: PremiumCard(
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                gradient: LinearGradient(
                  colors: [
                    tone.withValues(alpha: 0.34),
                    tone.withValues(alpha: 0.10),
                  ],
                ),
              ),
              child: Icon(icon, color: tone, size: 24),
            ),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title']?.toString() ?? 'Suggestion',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
                  if (item['subtitle'] != null) ...[
                    const SizedBox(height: 2),
                    Text(item['subtitle'].toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        )),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String kind) {
    if (kind.contains('food') || kind.contains('rest')) {
      return Icons.restaurant_rounded;
    }
    if (kind.contains('hotel') || kind.contains('stay')) {
      return Icons.hotel_rounded;
    }
    if (kind.contains('activity') || kind.contains('tour')) {
      return Icons.local_activity_rounded;
    }
    if (kind.contains('view') || kind.contains('place')) {
      return Icons.landscape_rounded;
    }
    return Icons.place_rounded;
  }
}
