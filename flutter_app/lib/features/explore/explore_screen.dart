import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/animated_appearance.dart';
import '../../cinematic/states/cinematic_states.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../insights/insights_provider.dart';

/// Explore v3 — flagship discovery surface.
///
/// Composition:
///   1. Featured destinations carousel (parallax + popularity badge)
///   2. Category rail (Places / Food / Stays / Activities / Tours / Hidden)
///   3. Destination grid (4 deterministic destinations × emoji hero)
///   4. Curated suggestion cards from `recommendationsProvider`
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});
  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  String _category = 'all';

  static const _categories = <_ExploreCategory>[
    _ExploreCategory('all', 'All', Icons.travel_explore_rounded),
    _ExploreCategory('place', 'Places', Icons.place_rounded),
    _ExploreCategory('food', 'Food', Icons.restaurant_rounded),
    _ExploreCategory('stay', 'Stays', Icons.hotel_rounded),
    _ExploreCategory('activity', 'Activities', Icons.local_activity_rounded),
    _ExploreCategory('tour', 'Tours', Icons.tour_rounded),
    _ExploreCategory('hidden', 'Hidden', Icons.diamond_rounded),
  ];

  static const _featured = <_FeaturedDest>[
    _FeaturedDest(
      'Tokyo',
      'NRT',
      '🗼',
      'Sakura · sushi · neon',
      0.92,
      [Color(0xFFEC4899), Color(0xFF7C3AED)],
    ),
    _FeaturedDest(
      'Paris',
      'CDG',
      '🗼',
      'Patisseries · Seine · museums',
      0.88,
      [Color(0xFF3B82F6), Color(0xFF06B6D4)],
    ),
    _FeaturedDest(
      'Reykjavik',
      'KEF',
      '🌋',
      'Aurora · geysers · ice caves',
      0.81,
      [Color(0xFF10B981), Color(0xFF06B6D4)],
    ),
    _FeaturedDest(
      'Marrakech',
      'RAK',
      '🏜',
      'Souks · tagine · dunes',
      0.78,
      [Color(0xFFF59E0B), Color(0xFFEF4444)],
    ),
    _FeaturedDest(
      'Singapore',
      'SIN',
      '🌃',
      'Hawker · skyline · garden',
      0.94,
      [Color(0xFF6366F1), Color(0xFFEC4899)],
    ),
  ];

  static const _grid = <_GridDest>[
    _GridDest('Bali', '🏝', 'Surf · temples · rice fields'),
    _GridDest('Lisbon', '🛼', 'Trams · seafood · sunsets'),
    _GridDest('Cape Town', '🦁', 'Mountain · wine · ocean'),
    _GridDest('Seoul', '🍱', 'Markets · K-pop · palaces'),
  ];

  @override
  Widget build(BuildContext context) {
    final reco = ref.watch(recommendationsProvider);
    final theme = Theme.of(context);
    return PageScaffold(
      title: 'Explore',
      subtitle: 'Curated for your next destination',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Featured destinations carousel ────────────────────────
          AnimatedAppearance(
            child: SizedBox(
              height: 220,
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.86),
                itemCount: _featured.length,
                itemBuilder: (_, i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _FeaturedCard(dest: _featured[i]),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          // ── Category rail ────────────────────────────────────────
          AnimatedAppearance(
            delay: const Duration(milliseconds: 80),
            child: SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final c = _categories[i];
                  final selected = _category == c.id;
                  return Pressable(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _category = c.id);
                    },
                    child: AnimatedContainer(
                      duration: AppTokens.durationSm,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppTokens.radiusFull,
                        ),
                        gradient: selected
                            ? LinearGradient(colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ])
                            : null,
                        color: selected
                            ? null
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.06),
                        border: Border.all(
                          color: selected
                              ? Colors.transparent
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.10),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            c.icon,
                            size: 14,
                            color: selected
                                ? Colors.white
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.70),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            c.label,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: selected
                                  ? Colors.white
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.85),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // ── Destination grid ─────────────────────────────────────
          AnimatedAppearance(
            delay: const Duration(milliseconds: 140),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                0,
                AppTokens.space5,
                0,
                AppTokens.space2,
              ),
              child: Text(
                'NEXT-GEN DESTINATIONS',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 180),
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: AppTokens.space3,
              crossAxisSpacing: AppTokens.space3,
              childAspectRatio: 1.05,
              children: [
                for (final g in _grid) _GridCard(dest: g),
              ],
            ),
          ),
          // ── Curated recommendations ──────────────────────────────
          AnimatedAppearance(
            delay: const Duration(milliseconds: 240),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                0,
                AppTokens.space5,
                0,
                AppTokens.space2,
              ),
              child: Text(
                'CURATED FOR YOU',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
          reco.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppTokens.space5),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Os2ErrorState(
              eyebrow: 'DISCOVER · RECOMMENDATIONS',
              title: 'Recommendations unavailable',
              message: 'We couldn\'t reach the recommendations backbone. Retry to pull fresh picks for your journey.',
              errorCode: e.toString(),
            ),
            data: (data) {
              final items = ((data['items'] as List?) ?? const [])
                  .cast<Map<String, dynamic>>();
              final filtered = _category == 'all'
                  ? items
                  : items.where((it) {
                      final k = (it['kind'] ?? it['type'] ?? '')
                          .toString()
                          .toLowerCase();
                      return k.contains(_category);
                    }).toList();
              if (filtered.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTokens.space5,
                  ),
                  child: Os2EmptyState(
                    eyebrow: 'DISCOVER · ${_labelFor(_category).toUpperCase()}',
                    title: 'No matches yet',
                    message:
                        'No “${_labelFor(_category)}” suggestions for now. Try a different category or check back later.',
                    icon: Icons.travel_explore_rounded,
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < filtered.length; i++)
                    AnimatedAppearance(
                      delay: Duration(milliseconds: 60 * i),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppTokens.space3,
                        ),
                        child: _ExploreRow(
                          item: filtered[i],
                          tone: _accentForIndex(i),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppTokens.space9),
        ],
      ),
    );
  }

  String _labelFor(String id) => _categories
      .firstWhere((c) => c.id == id, orElse: () => _categories[0])
      .label;

  Color _accentForIndex(int i) => const [
        Color(0xFF7C3AED),
        Color(0xFF06B6D4),
        Color(0xFF10B981),
        Color(0xFFF59E0B),
        Color(0xFFEF4444),
        Color(0xFF3B82F6),
      ][i % 6];
}

class _ExploreCategory {
  const _ExploreCategory(this.id, this.label, this.icon);
  final String id;
  final String label;
  final IconData icon;
}

class _FeaturedDest {
  const _FeaturedDest(
    this.name,
    this.code,
    this.emoji,
    this.tagline,
    this.popularity,
    this.gradient,
  );
  final String name;
  final String code;
  final String emoji;
  final String tagline;
  final double popularity;
  final List<Color> gradient;
}

class _GridDest {
  const _GridDest(this.name, this.emoji, this.subtitle);
  final String name;
  final String emoji;
  final String subtitle;
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.dest});
  final _FeaturedDest dest;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      scale: 0.98,
      onTap: () {
        HapticFeedback.lightImpact();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusXl),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dest.gradient,
          ),
          boxShadow: AppTokens.shadowLg(tint: dest.gradient.first),
        ),
        child: Stack(
          children: [
            // Soft emoji backdrop.
            Positioned(
              right: -10,
              bottom: -16,
              child: Opacity(
                opacity: 0.30,
                child: Text(
                  dest.emoji,
                  style: const TextStyle(fontSize: 220),
                ),
              ),
            ),
            // Gradient overlay for legibility.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTokens.radiusXl),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.45),
                    ],
                  ),
                ),
              ),
            ),
            // Foreground.
            Padding(
              padding: const EdgeInsets.all(AppTokens.space5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusFull),
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                        child: Text(
                          dest.code,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusFull),
                          color: Colors.black.withValues(alpha: 0.30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              size: 12,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(dest.popularity * 100).round()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    dest.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dest.tagline,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: AppTokens.space3),
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: dest.popularity,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
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

class _GridCard extends StatelessWidget {
  const _GridCard({required this.dest});
  final _GridDest dest;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.30),
                  theme.colorScheme.primary.withValues(alpha: 0.08),
                ],
              ),
            ),
            child: Text(
              dest.emoji,
              style: const TextStyle(fontSize: 26),
            ),
          ),
          const Spacer(),
          Text(
            dest.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            dest.subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/discover');
      },
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
                  Text(
                    item['title']?.toString() ?? 'Suggestion',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (item['subtitle'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item['subtitle'].toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
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
