import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/api/api_provider.dart';
import '../../widgets/cinematic_button.dart';
import '../../widgets/premium_card.dart';
import '_bespoke_scaffold.dart';
import 'restaurant_detail_screen.dart';

/// Food — bespoke vertical with cuisine filters and a detail sheet
/// showing the menu highlights and order CTA.
class FoodScreen extends ConsumerWidget {
  const FoodScreen({super.key});

  static const _tone = Color(0xFFE11D48);
  static const _filters = [
    BespokeFilter(key: 'now', label: 'Now', icon: Icons.flash_on_rounded),
    BespokeFilter(
        key: 'breakfast', label: 'Breakfast', icon: Icons.coffee_rounded),
    BespokeFilter(
        key: 'lunch', label: 'Lunch', icon: Icons.lunch_dining_rounded),
    BespokeFilter(
        key: 'dinner', label: 'Dinner', icon: Icons.dinner_dining_rounded),
    BespokeFilter(key: 'sushi', label: 'Sushi', icon: Icons.set_meal_rounded),
    BespokeFilter(key: 'vegan', label: 'Vegan', icon: Icons.eco_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(globeIdApiProvider);
    return BespokeServiceShell<Map<String, dynamic>>(
      title: 'Food',
      subtitle: 'Local favourites, delivered or in-room',
      icon: Icons.restaurant_rounded,
      tone: _tone,
      heroAccent: const Color(0xFFFB923C),
      filters: _filters,
      fetcher: (active) async {
        final data = await api.foodSearch({
          'city': 'San Francisco',
          if (active != null) 'category': active,
        });
        return ((data['items'] as List?) ?? const [])
            .cast<Map<String, dynamic>>();
      },
      itemBuilder: (ctx, item, _) => _FoodCard(item: item, tone: _tone),
      onItemTap: (ctx, item) => _showFoodDetail(ctx, item),
    );
  }

  void _showFoodDetail(BuildContext context, Map<String, dynamic> item) {
    showBespokeDetail(
      context: context,
      builder: (sheetCtx, scroll) {
        final theme = Theme.of(sheetCtx);
        final title = item['title']?.toString() ?? 'Restaurant';
        final cuisine = item['cuisine']?.toString() ?? 'Modern';
        final eta = item['eta']?.toString() ?? '25 min';
        final price = item['price']?.toString() ?? '\$';
        return ListView(
          controller: scroll,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space5,
            vertical: AppTokens.space3,
          ),
          children: [
            PremiumCard.hero(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE11D48), Color(0xFFFB923C)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.restaurant_rounded,
                      color: Colors.white, size: 32),
                  const SizedBox(width: AppTokens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            )),
                        Text('$cuisine · ETA $eta · $price',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space5),
            Text('Menu highlights', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTokens.space3),
            for (final dish in const [
              ('Tasting plate', 'Chef\'s rotating selection', '\$32'),
              ('Wagyu burger', 'Brioche · truffle aioli · fries', '\$22'),
              ('Garden bowl', 'Quinoa · roasted veg · feta', '\$16'),
              ('Citrus mocktail', 'Yuzu · lime · soda', '\$8'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.space2),
                child: PremiumCard(
                  padding: const EdgeInsets.all(AppTokens.space4),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusLg),
                          color:
                              const Color(0xFFE11D48).withValues(alpha: 0.16),
                        ),
                        child: const Icon(Icons.restaurant_menu_rounded,
                            color: Color(0xFFE11D48)),
                      ),
                      const SizedBox(width: AppTokens.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dish.$1,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                )),
                            Text(dish.$2, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Text(dish.$3,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: const Color(0xFFE11D48),
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          )),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppTokens.space5),
            Row(
              children: [
                Expanded(
                  child: CinematicButton(
                    label: 'View menu',
                    icon: Icons.menu_book_rounded,
                    onPressed: () {
                      Navigator.of(sheetCtx).maybePop();
                      final rating =
                          (item['rating'] as num?)?.toDouble() ?? 4.5;
                      final priceTier = price
                          .replaceAll(RegExp(r'[^\$]'), '')
                          .length
                          .clamp(1, 4);
                      final flag = item['flag']?.toString() ?? '🌍';
                      final city = item['city']?.toString() ?? 'San Francisco';
                      context.push(
                        '/services/food/detail',
                        extra: RestaurantDetailArgs(
                          name: title,
                          cuisine: cuisine,
                          city: city,
                          rating: rating,
                          tonality: _tone,
                          flag: flag,
                          priceTier: priceTier == 0 ? 2 : priceTier,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppTokens.space2),
                Expanded(
                  child: CinematicButton(
                    label: 'Order now',
                    icon: Icons.shopping_bag_rounded,
                    onPressed: () => Navigator.of(sheetCtx).maybePop(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space4),
          ],
        );
      },
    );
  }
}

class _FoodCard extends StatelessWidget {
  const _FoodCard({required this.item, required this.tone});
  final Map<String, dynamic> item;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = item['title']?.toString() ?? 'Restaurant';
    final cuisine = item['cuisine']?.toString() ?? '';
    final rating = (item['rating'] as num?)?.toDouble();
    final eta = item['eta']?.toString() ?? '25 min';
    final price = item['price']?.toString() ?? '\$\$';
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              gradient: LinearGradient(
                colors: [tone, tone.withValues(alpha: 0.55)],
              ),
            ),
            child: const Icon(Icons.restaurant_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (cuisine.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(cuisine,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      )),
                ],
                const SizedBox(height: AppTokens.space2),
                Row(
                  children: [
                    if (rating != null) ...[
                      const Icon(Icons.star_rounded,
                          size: 14, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 2),
                      Text(rating.toStringAsFixed(1),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(width: AppTokens.space3),
                    ],
                    Icon(Icons.access_time_rounded,
                        size: 13,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    const SizedBox(width: 2),
                    Text(eta,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space3, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusFull),
              color: tone.withValues(alpha: 0.14),
              border: Border.all(color: tone.withValues(alpha: 0.32)),
            ),
            child: Text(price,
                style: TextStyle(
                  color: tone,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                )),
          ),
        ],
      ),
    );
  }
}
