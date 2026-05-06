import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/api/api_provider.dart';
import '../../widgets/cinematic_button.dart';
import '../../widgets/premium_card.dart';
import '_bespoke_scaffold.dart';

/// Hotels — bespoke vertical with curated filters (price band,
/// rating, distance) and detail sheet showing rooms, amenities and a
/// reserve CTA.
class HotelsScreen extends ConsumerWidget {
  const HotelsScreen({super.key});

  static const _tone = Color(0xFF7E22CE);
  static const _filters = [
    BespokeFilter(key: 'all', label: 'All', icon: Icons.hotel_rounded),
    BespokeFilter(key: '\$\$', label: 'Mid-range', icon: Icons.attach_money_rounded),
    BespokeFilter(
        key: '\$\$\$', label: 'Premium', icon: Icons.workspace_premium_rounded),
    BespokeFilter(key: '4plus', label: '4★ +', icon: Icons.star_rounded),
    BespokeFilter(key: 'pool', label: 'Pool', icon: Icons.pool_rounded),
    BespokeFilter(key: 'cbd', label: 'City', icon: Icons.location_city_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(globeIdApiProvider);
    return BespokeServiceShell<Map<String, dynamic>>(
      title: 'Hotels',
      subtitle: 'Curated stays, on-itinerary, on-budget',
      icon: Icons.hotel_rounded,
      tone: _tone,
      heroAccent: const Color(0xFFEC4899),
      filters: _filters,
      fetcher: (active) async {
        final data = await api.hotelsSearch({
          'city': 'San Francisco',
          if (active != null) 'filter': active,
        });
        return ((data['items'] as List?) ?? const [])
            .cast<Map<String, dynamic>>();
      },
      itemBuilder: (ctx, item, _) => _HotelCard(item: item, tone: _tone),
      onItemTap: (ctx, item) => _showHotelDetail(ctx, item),
    );
  }

  void _showHotelDetail(BuildContext context, Map<String, dynamic> item) {
    showBespokeDetail(
      context: context,
      builder: (sheetCtx, scroll) {
        final theme = Theme.of(sheetCtx);
        final title = item['title']?.toString() ?? 'Hotel';
        final price = item['price']?.toString() ?? '\$—';
        final rating = (item['rating'] as num?)?.toDouble() ?? 4.5;
        final amenities = (item['amenities'] as List?) ??
            const ['Wi-Fi', 'Pool', 'Breakfast', 'Gym'];
        return ListView(
          controller: scroll,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space5,
            vertical: AppTokens.space3,
          ),
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radius2xl),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7E22CE), Color(0xFFEC4899)],
                ),
              ),
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.all(AppTokens.space5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(rating.toStringAsFixed(1),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTokens.space2),
                      Text(title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          )),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.space3,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusFull),
                    ),
                    child: Text(price,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: const Color(0xFF7E22CE),
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        )),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space5),
            Text('Amenities', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTokens.space3),
            Wrap(
              spacing: AppTokens.space2,
              runSpacing: AppTokens.space2,
              children: [
                for (final a in amenities)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.space3, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.8),
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusFull),
                      border: Border.all(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(a.toString(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                  ),
              ],
            ),
            const SizedBox(height: AppTokens.space5),
            Text('Rooms', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTokens.space3),
            for (final r in const [
              ('Deluxe King', 'King bed · City view', '\$240/nt'),
              ('Twin Suite', 'Two queens · Premium tower', '\$310/nt'),
              ('Penthouse', 'Bay view · Lounge access', '\$680/nt'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.space2),
                child: PremiumCard(
                  padding: const EdgeInsets.all(AppTokens.space4),
                  child: Row(
                    children: [
                      const Icon(Icons.bed_rounded, color: Color(0xFF7E22CE)),
                      const SizedBox(width: AppTokens.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.$1,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                )),
                            Text(r.$2, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Text(r.$3,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: const Color(0xFF7E22CE),
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          )),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppTokens.space5),
            CinematicButton(
              label: 'Reserve · $price',
              icon: Icons.event_available_rounded,
              onPressed: () => Navigator.of(sheetCtx).maybePop(),
            ),
            const SizedBox(height: AppTokens.space4),
          ],
        );
      },
    );
  }
}

class _HotelCard extends StatelessWidget {
  const _HotelCard({required this.item, required this.tone});
  final Map<String, dynamic> item;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = item['title']?.toString() ?? 'Hotel';
    final subtitle = item['subtitle']?.toString() ?? '—';
    final price = item['price']?.toString() ?? '\$—';
    final rating = (item['rating'] as num?)?.toDouble();
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tone,
                  tone.withValues(alpha: 0.55),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: tone.withValues(alpha: 0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child:
                const Icon(Icons.hotel_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
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
                    Icon(Icons.location_on_rounded,
                        size: 13,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5)),
                    const SizedBox(width: 2),
                    Text('1.2 km',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.space2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: tone,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )),
              Text('per night',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  )),
            ],
          ),
        ],
      ),
    );
  }
}
