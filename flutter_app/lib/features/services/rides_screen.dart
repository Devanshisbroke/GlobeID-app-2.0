import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/api/api_provider.dart';
import '../../nexus/nexus_tokens.dart';
import '../../widgets/cinematic_button.dart';
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
            BespokeDetailHeader(
              icon: Icons.directions_car_rounded,
              tone: _tone,
              title: title,
              subtitle: 'ETA $eta',
              trailing: Text(
                price,
                style: const TextStyle(
                  color: N.inkHi,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: AppTokens.space5),
            const _RouteStrip(),
            const SizedBox(height: AppTokens.space5),
            const Text(
              'FARE BREAKDOWN',
              style: TextStyle(
                color: N.inkLow,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: N.s3),
            // Hairline-framed receipt block.
            Container(
              decoration: BoxDecoration(
                color: N.surface,
                borderRadius: BorderRadius.circular(N.rCard),
                border: Border.all(color: N.hairline, width: N.strokeHair),
              ),
              child: Column(
                children: [
                  for (final entry in const [
                    ('Base fare', '\$8.00', false),
                    ('Distance · 7.4 km', '\$11.20', false),
                    ('Service fee', '\$2.40', false),
                    ('Tip', '\$0.00', true),
                  ])
                    _FareRow(
                        label: entry.$1, value: entry.$2, isLast: entry.$3),
                ],
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
    return Container(
      padding: const EdgeInsets.all(N.s4),
      decoration: BoxDecoration(
        color: N.surface,
        borderRadius: BorderRadius.circular(N.rCard),
        border: Border.all(color: N.hairline, width: N.strokeHair),
      ),
      child: Row(
        children: [
          // Origin / destination axis — small filled disc, hairline
          // connector, terminal tone disc.
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: N.inkMid,
                ),
              ),
              Container(
                width: 1,
                height: 30,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: N.hairlineHi,
              ),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEA580C),
                ),
              ),
            ],
          ),
          const SizedBox(width: N.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'PICKUP',
                  style: TextStyle(
                    color: N.inkLow,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    letterSpacing: 1.4,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Embarcadero',
                  style: TextStyle(
                    color: N.inkHi,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'DROP',
                  style: TextStyle(
                    color: N.inkLow,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    letterSpacing: 1.4,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'SFO Terminal 2',
                  style: TextStyle(
                    color: N.inkHi,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
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
    final title = item['title']?.toString() ?? 'Ride';
    final eta = item['eta']?.toString() ?? '4 min';
    final price = item['price']?.toString() ?? '\$—';
    return Container(
      padding: const EdgeInsets.all(N.s4),
      decoration: BoxDecoration(
        color: N.surface,
        borderRadius: BorderRadius.circular(N.rCard),
        border: Border.all(color: N.hairline, width: N.strokeHair),
      ),
      child: Row(
        children: [
          // Vehicle disc — tonal fill, hairline ring.
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
            child: Icon(Icons.directions_car_rounded, color: tone, size: 24),
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
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 11, color: N.inkMid),
                    const SizedBox(width: 4),
                    Text(
                      'ETA $eta',
                      style: const TextStyle(
                        color: N.inkMid,
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
          // Price pill — hairline frame, tabular numerals.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(N.rPill),
              color: tone.withValues(alpha: 0.14),
              border: Border.all(
                color: tone.withValues(alpha: 0.36),
                width: N.strokeHair,
              ),
            ),
            child: Text(
              price,
              style: TextStyle(
                color: tone,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0.2,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single hairline-bordered row inside the rides fare-breakdown receipt.
class _FareRow extends StatelessWidget {
  const _FareRow({
    required this.label,
    required this.value,
    required this.isLast,
  });

  final String label;
  final String value;
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: N.inkMid,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: N.inkHi,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
