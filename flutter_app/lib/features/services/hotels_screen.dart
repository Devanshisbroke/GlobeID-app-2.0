import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/api/api_provider.dart';
import '../../nexus/nexus_tokens.dart';
import '../../widgets/cinematic_button.dart';
import '_bespoke_scaffold.dart';
import 'hotel_detail_screen.dart';

/// Hotels — bespoke vertical with curated filters (price band,
/// rating, distance) and detail sheet showing rooms, amenities and a
/// reserve CTA.
class HotelsScreen extends ConsumerWidget {
  const HotelsScreen({super.key});

  static const _tone = Color(0xFF7E22CE);
  static const _filters = [
    BespokeFilter(key: 'all', label: 'All', icon: Icons.hotel_rounded),
    BespokeFilter(
        key: '\$\$', label: 'Mid-range', icon: Icons.attach_money_rounded),
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
            BespokeDetailHeader(
              icon: Icons.hotel_rounded,
              tone: _tone,
              title: title,
              subtitle: '★ ${rating.toStringAsFixed(1)} · $price',
              trailing: Text(
                price,
                style: const TextStyle(
                  color: N.inkHi,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: AppTokens.space5),
            const Text(
              'AMENITIES',
              style: TextStyle(
                color: N.inkLow,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: N.s3),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final a in amenities)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: N.surface,
                      borderRadius: BorderRadius.circular(N.rPill),
                      border:
                          Border.all(color: N.hairline, width: N.strokeHair),
                    ),
                    child: Text(
                      a.toString(),
                      style: const TextStyle(
                        color: N.inkHi,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTokens.space5),
            const Text(
              'ROOMS',
              style: TextStyle(
                color: N.inkLow,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: N.s3),
            for (final r in const [
              ('Deluxe King', 'King bed · City view', '\$240/nt'),
              ('Twin Suite', 'Two queens · Premium tower', '\$310/nt'),
              ('Penthouse', 'Bay view · Lounge access', '\$680/nt'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(N.s4),
                  decoration: BoxDecoration(
                    color: N.surface,
                    borderRadius: BorderRadius.circular(N.rCard),
                    border: Border.all(color: N.hairline, width: N.strokeHair),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _tone.withValues(alpha: 0.14),
                          border: Border.all(
                            color: _tone.withValues(alpha: 0.36),
                            width: N.strokeHair,
                          ),
                        ),
                        child: const Icon(Icons.bed_rounded,
                            color: _tone, size: 18),
                      ),
                      const SizedBox(width: N.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.$1,
                              style: const TextStyle(
                                color: N.inkHi,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              r.$2,
                              style: const TextStyle(
                                color: N.inkMid,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        r.$3,
                        style: const TextStyle(
                          color: N.inkHi,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppTokens.space5),
            Row(
              children: [
                Expanded(
                  child: CinematicButton(
                    label: 'View suite',
                    icon: Icons.image_search_rounded,
                    onPressed: () {
                      Navigator.of(sheetCtx).maybePop();
                      final priceNum =
                          (item['priceValue'] as num?)?.toDouble() ??
                              double.tryParse(
                                  price.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                              280;
                      final city = item['city']?.toString() ?? 'San Francisco';
                      final country =
                          item['country']?.toString() ?? 'United States';
                      final flag = item['flag']?.toString() ?? '🌍';
                      context.push(
                        '/services/hotels/detail',
                        extra: HotelDetailArgs(
                          hotelName: title,
                          city: city,
                          country: country,
                          tonality: _tone,
                          rating: rating,
                          pricePerNight: priceNum,
                          flag: flag,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppTokens.space2),
                Expanded(
                  child: CinematicButton(
                    label: 'Reserve · $price',
                    icon: Icons.event_available_rounded,
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

class _HotelCard extends StatelessWidget {
  const _HotelCard({required this.item, required this.tone});
  final Map<String, dynamic> item;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final title = item['title']?.toString() ?? 'Hotel';
    final subtitle = item['subtitle']?.toString() ?? '—';
    final price = item['price']?.toString() ?? '\$—';
    final rating = (item['rating'] as num?)?.toDouble();
    return Container(
      padding: const EdgeInsets.all(N.s4),
      decoration: BoxDecoration(
        color: N.surface,
        borderRadius: BorderRadius.circular(N.rCard),
        border: Border.all(color: N.hairline, width: N.strokeHair),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tonal hotel disc — flat fill, hairline ring, no halo.
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(N.rSmall),
              color: tone.withValues(alpha: 0.14),
              border: Border.all(
                color: tone.withValues(alpha: 0.36),
                width: N.strokeHair,
              ),
            ),
            child: Icon(Icons.hotel_rounded, color: tone, size: 24),
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: N.inkMid,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
                    const Icon(Icons.location_on_rounded,
                        size: 11, color: N.inkLow),
                    const SizedBox(width: 2),
                    const Text(
                      '1.2 km',
                      style: TextStyle(
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(
                  color: N.inkHi,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  height: 1.0,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'per night',
                style: TextStyle(
                  color: N.inkLow,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
