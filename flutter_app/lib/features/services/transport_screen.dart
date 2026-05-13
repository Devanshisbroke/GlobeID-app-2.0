import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/api/api_provider.dart';
import '../../nexus/nexus_tokens.dart';
import '../../widgets/cinematic_button.dart';
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
            BespokeDetailHeader(
              icon: Icons.train_rounded,
              tone: _tone,
              title: title,
              subtitle: line,
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
              'DEPARTURES',
              style: TextStyle(
                color: N.inkLow,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: N.s3),
            // Departure-board style block: hairline frame, tabular times,
            // restrained tonal status chips.
            Container(
              decoration: BoxDecoration(
                color: N.surface,
                borderRadius: BorderRadius.circular(N.rCard),
                border: Border.all(color: N.hairline, width: N.strokeHair),
              ),
              child: Column(
                children: [
                  for (final entry in const [
                    ('07:42', 'Platform 3', 'On time', false),
                    ('08:12', 'Platform 3', 'On time', false),
                    ('08:42', 'Platform 5', '+4 min', false),
                    ('09:12', 'Platform 3', 'On time', true),
                  ])
                    _DepartureRow(
                      time: entry.$1,
                      platform: entry.$2,
                      status: entry.$3,
                      isLast: entry.$4,
                    ),
                ],
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
    final title = item['title']?.toString() ?? 'Transit';
    final subtitle = item['subtitle']?.toString() ?? '—';
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
            child: Icon(Icons.train_rounded, color: tone, size: 22),
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
              ],
            ),
          ),
          const SizedBox(width: N.s2),
          Text(
            price,
            style: const TextStyle(
              color: N.inkHi,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Single departure-board row inside the transport detail sheet.
class _DepartureRow extends StatelessWidget {
  const _DepartureRow({
    required this.time,
    required this.platform,
    required this.status,
    required this.isLast,
  });

  final String time;
  final String platform;
  final String status;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final onTime = status.toLowerCase() == 'on time';
    final tone = onTime ? N.success : const Color(0xFFF59E0B);
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
          // Tabular time — reads like a Solari board.
          SizedBox(
            width: 56,
            child: Text(
              time,
              style: const TextStyle(
                color: N.inkHi,
                fontWeight: FontWeight.w800,
                fontSize: 17,
                letterSpacing: 0.5,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            child: Text(
              platform,
              style: const TextStyle(
                color: N.inkMid,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(N.rPill),
              color: tone.withValues(alpha: 0.14),
              border: Border.all(
                color: tone.withValues(alpha: 0.36),
                width: N.strokeHair,
              ),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: tone,
                fontWeight: FontWeight.w800,
                fontSize: 9,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
