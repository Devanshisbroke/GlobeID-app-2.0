import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/api/api_provider.dart';
import '../../nexus/nexus_tokens.dart';
import '../../widgets/cinematic_button.dart';
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
            BespokeDetailHeader(
              icon: Icons.restaurant_rounded,
              tone: _tone,
              title: title,
              subtitle: '$cuisine · ETA $eta · $price',
            ),
            const SizedBox(height: AppTokens.space5),
            const Text(
              'MENU HIGHLIGHTS',
              style: TextStyle(
                color: N.inkLow,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: N.s3),
            Container(
              decoration: BoxDecoration(
                color: N.surface,
                borderRadius: BorderRadius.circular(N.rCard),
                border: Border.all(color: N.hairline, width: N.strokeHair),
              ),
              child: Column(
                children: [
                  for (final entry in const [
                    ('Tasting plate', 'Chef\'s rotating selection', '\$32',
                        false),
                    ('Wagyu burger', 'Brioche · truffle aioli · fries', '\$22',
                        false),
                    ('Garden bowl', 'Quinoa · roasted veg · feta', '\$16',
                        false),
                    ('Citrus mocktail', 'Yuzu · lime · soda', '\$8', true),
                  ])
                    _MenuRow(
                      title: entry.$1,
                      subtitle: entry.$2,
                      price: entry.$3,
                      isLast: entry.$4,
                    ),
                ],
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
    final title = item['title']?.toString() ?? 'Restaurant';
    final cuisine = item['cuisine']?.toString() ?? '';
    final rating = (item['rating'] as num?)?.toDouble();
    final eta = item['eta']?.toString() ?? '25 min';
    final price = item['price']?.toString() ?? '\$\$';
    return Container(
      padding: const EdgeInsets.all(N.s4),
      decoration: BoxDecoration(
        color: N.surface,
        borderRadius: BorderRadius.circular(N.rCard),
        border: Border.all(color: N.hairline, width: N.strokeHair),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(N.rSmall),
              color: tone.withValues(alpha: 0.14),
              border: Border.all(
                color: tone.withValues(alpha: 0.36),
                width: N.strokeHair,
              ),
            ),
            child: Icon(Icons.restaurant_rounded, color: tone, size: 22),
          ),
          const SizedBox(width: N.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: N.inkHi,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (cuisine.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    cuisine,
                    style: const TextStyle(
                      color: N.inkMid,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (rating != null) ...[
                      const Icon(Icons.star_rounded,
                          size: 12, color: N.tierGold),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: N.inkHi,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 2,
                        height: 2,
                        decoration: const BoxDecoration(
                          color: N.inkLow,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Icon(Icons.access_time_rounded,
                        size: 11, color: N.inkLow),
                    const SizedBox(width: 2),
                    Text(
                      eta,
                      style: const TextStyle(
                        color: N.inkLow,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: N.s2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(N.rPill),
              border: Border.all(color: N.hairline, width: N.strokeHair),
            ),
            child: Text(
              price,
              style: const TextStyle(
                color: N.inkHi,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Menu row used inside the food detail-sheet receipt block.
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.isLast,
  });

  final String title;
  final String subtitle;
  final String price;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: N.s4, vertical: N.s3),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast ? Colors.transparent : N.hairline,
            width: N.strokeHair,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: N.inkHi,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: N.inkMid,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              color: N.inkHi,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
