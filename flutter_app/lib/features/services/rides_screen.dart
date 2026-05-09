import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/api/api_provider.dart';
import '../../widgets/cinematic_button.dart';
import '../../widgets/premium_card.dart';
import '_bespoke_scaffold.dart';

/// Rides — bespoke vertical with vehicle-class filters and a detail
/// sheet showing the dispatch path, ETA breakdown, and book CTA.
class RidesScreen extends ConsumerWidget {
  const RidesScreen({super.key});

  static const _tone = Color(0xFFEA580C);
  static const _filters = [
    BespokeFilter(key: 'eco', label: 'Eco', icon: Icons.eco_rounded),
    BespokeFilter(
        key: 'standard', label: 'Standard', icon: Icons.directions_car_rounded),
    BespokeFilter(
        key: 'premium',
        label: 'Premium',
        icon: Icons.airline_seat_recline_extra_rounded),
    BespokeFilter(key: 'xl', label: 'XL', icon: Icons.airport_shuttle_rounded),
    BespokeFilter(key: 'airport', label: 'Airport', icon: Icons.flight_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(globeIdApiProvider);
    return BespokeServiceShell<Map<String, dynamic>>(
      title: 'Rides',
      subtitle: 'Airport runs and city hops, on demand',
      icon: Icons.directions_car_rounded,
      tone: _tone,
      heroAccent: const Color(0xFFFACC15),
      filters: _filters,
      fetcher: (active) async {
        final data = await api.ridesSearch({
          'city': 'San Francisco',
          if (active != null) 'class': active,
        });
        return ((data['items'] as List?) ?? const [])
            .cast<Map<String, dynamic>>();
      },
      itemBuilder: (ctx, item, _) => _RideCard(item: item, tone: _tone),
      onItemTap: (ctx, item) => _showRideDetail(ctx, item),
    );
  }

  void _showRideDetail(BuildContext context, Map<String, dynamic> item) {
    showBespokeDetail(
      context: context,
      builder: (sheetCtx, scroll) {
        final theme = Theme.of(sheetCtx);
        final title = item['title']?.toString() ?? 'Ride';
        final eta = item['eta']?.toString() ?? '4 min';
        final price = item['price']?.toString() ?? '\$24';
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
                colors: [Color(0xFFEA580C), Color(0xFFFACC15)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.directions_car_rounded,
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
                            Text('ETA $eta',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                )),
                          ],
                        ),
                      ),
                      Text(price,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          )),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space5),
            const _RouteStrip(),
            const SizedBox(height: AppTokens.space5),
            Text('Fare breakdown', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTokens.space3),
            for (final r in const [
              ('Base fare', '\$8.00'),
              ('Distance · 7.4 km', '\$11.20'),
              ('Service fee', '\$2.40'),
              ('Tip', '\$0.00'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.space2),
                child: PremiumCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.space4, vertical: AppTokens.space3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r.$1, style: theme.textTheme.bodyMedium),
                      Text(r.$2,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          )),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppTokens.space5),
            CinematicButton(
              label: 'Book ride · $price',
              icon: Icons.local_taxi_rounded,
              onPressed: () => Navigator.of(sheetCtx).maybePop(),
            ),
            const SizedBox(height: AppTokens.space4),
          ],
        );
      },
    );
  }
}

class _RouteStrip extends StatelessWidget {
  const _RouteStrip();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary,
                ),
              ),
              Container(
                width: 1.5,
                height: 36,
                margin: const EdgeInsets.symmetric(vertical: 2),
                color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEA580C),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pickup · Embarcadero',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 18),
                Text('Drop · SFO Terminal 2',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  const _RideCard({required this.item, required this.tone});
  final Map<String, dynamic> item;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = item['title']?.toString() ?? 'Ride';
    final eta = item['eta']?.toString() ?? '4 min';
    final price = item['price']?.toString() ?? '\$—';
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
            child: const Icon(Icons.directions_car_rounded,
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
                    )),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 13,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Text('ETA $eta',
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
