import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/api/api_provider.dart';
import '../../widgets/cinematic_button.dart';
import '../../widgets/premium_card.dart';
import '_bespoke_scaffold.dart';

/// Transport — trains/buses/metro with mode filters and a detail sheet
/// showing line strip, departure board, and book CTA.
class TransportScreen extends ConsumerWidget {
  const TransportScreen({super.key});

  static const _tone = Color(0xFF1D4ED8);
  static const _filters = [
    BespokeFilter(key: 'train', label: 'Train', icon: Icons.train_rounded),
    BespokeFilter(key: 'metro', label: 'Metro', icon: Icons.subway_rounded),
    BespokeFilter(key: 'bus', label: 'Bus', icon: Icons.directions_bus_rounded),
    BespokeFilter(
        key: 'ferry', label: 'Ferry', icon: Icons.directions_boat_rounded),
    BespokeFilter(
        key: 'airport', label: 'Airport', icon: Icons.flight_takeoff_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(globeIdApiProvider);
    return BespokeServiceShell<Map<String, dynamic>>(
      title: 'Transport',
      subtitle: 'Trains, metro, ferries and airport links',
      icon: Icons.train_rounded,
      tone: _tone,
      heroAccent: const Color(0xFF38BDF8),
      filters: _filters,
      fetcher: (active) async {
        final data = await api.localServices({
          'city': 'San Francisco',
          'kind': 'transport',
          if (active != null) 'mode': active,
        });
        return ((data['items'] as List?) ?? const [])
            .cast<Map<String, dynamic>>();
      },
      itemBuilder: (ctx, item, _) => _TransportCard(item: item, tone: _tone),
      onItemTap: (ctx, item) => _showTransportDetail(ctx, item),
    );
  }

  void _showTransportDetail(BuildContext context, Map<String, dynamic> item) {
    showBespokeDetail(
      context: context,
      builder: (sheetCtx, scroll) {
        final theme = Theme.of(sheetCtx);
        final title = item['title']?.toString() ?? 'Transit';
        final line = item['line']?.toString() ?? 'Express line';
        final price = item['price']?.toString() ?? '\$8.50';
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
                colors: [Color(0xFF1D4ED8), Color(0xFF38BDF8)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.train_rounded,
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
                        Text(line,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            )),
                      ],
                    ),
                  ),
                  Text(price,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      )),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space5),
            Text('Departures', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTokens.space3),
            for (final d in const [
              ('07:42', 'Platform 3', 'On time'),
              ('08:12', 'Platform 3', 'On time'),
              ('08:42', 'Platform 5', '+4 min'),
              ('09:12', 'Platform 3', 'On time'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.space2),
                child: PremiumCard(
                  padding: const EdgeInsets.all(AppTokens.space4),
                  child: Row(
                    children: [
                      Text(d.$1,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          )),
                      const SizedBox(width: AppTokens.space3),
                      Expanded(
                        child: Text(d.$2, style: theme.textTheme.bodyMedium),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusFull),
                          color: d.$3 == 'On time'
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.18),
                        ),
                        child: Text(d.$3,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: d.$3 == 'On time'
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                              fontWeight: FontWeight.w800,
                            )),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppTokens.space5),
            CinematicButton(
              label: 'Buy ticket · $price',
              icon: Icons.confirmation_number_rounded,
              onPressed: () => Navigator.of(sheetCtx).maybePop(),
            ),
            const SizedBox(height: AppTokens.space4),
          ],
        );
      },
    );
  }
}

class _TransportCard extends StatelessWidget {
  const _TransportCard({required this.item, required this.tone});
  final Map<String, dynamic> item;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = item['title']?.toString() ?? 'Transit';
    final subtitle = item['subtitle']?.toString() ?? '—';
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
            child:
                const Icon(Icons.train_rounded, color: Colors.white, size: 26),
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
                Text(subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(price,
              style: theme.textTheme.titleSmall?.copyWith(
                color: tone,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              )),
        ],
      ),
    );
  }
}
