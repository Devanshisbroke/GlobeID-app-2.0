import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/api/api_provider.dart';
import '../../nexus/nexus_tokens.dart';
import '../../widgets/cinematic_button.dart';
import '_bespoke_scaffold.dart';

/// Activities — local experiences with category filters and a detail
/// sheet showing time-slot picker and reserve CTA.
class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});

  static const _tone = Color(0xFF059669);
  static const _filters = [
    BespokeFilter(key: 'tour', label: 'Tours', icon: Icons.tour_rounded),
    BespokeFilter(key: 'museum', label: 'Museums', icon: Icons.museum_rounded),
    BespokeFilter(
        key: 'food', label: 'Food tours', icon: Icons.restaurant_menu_rounded),
    BespokeFilter(
        key: 'outdoor', label: 'Outdoors', icon: Icons.terrain_rounded),
    BespokeFilter(
        key: 'kids', label: 'Family', icon: Icons.family_restroom_rounded),
    BespokeFilter(
        key: 'nightlife', label: 'Nightlife', icon: Icons.nightlife_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(globeIdApiProvider);
    return BespokeServiceShell<Map<String, dynamic>>(
      title: 'Activities',
      subtitle: 'Tours, museums and local experiences',
      icon: Icons.local_activity_rounded,
      tone: _tone,
      heroAccent: const Color(0xFF22D3EE),
      filters: _filters,
      fetcher: (active) async {
        final data = await api.localServices({
          'city': 'San Francisco',
          if (active != null) 'category': active,
        });
        return ((data['items'] as List?) ?? const [])
            .cast<Map<String, dynamic>>();
      },
      itemBuilder: (ctx, item, _) => _ActivityCard(item: item, tone: _tone),
      onItemTap: (ctx, item) => _showActivityDetail(ctx, item),
    );
  }

  void _showActivityDetail(BuildContext context, Map<String, dynamic> item) {
    showBespokeDetail(
      context: context,
      builder: (sheetCtx, scroll) {
        final title = item['title']?.toString() ?? 'Activity';
        final subtitle = item['subtitle']?.toString() ?? 'Local experience';
        final price = item['price']?.toString() ?? '\$24';
        final duration = item['duration']?.toString() ?? '90 min';
        return ListView(
          controller: scroll,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space5,
            vertical: AppTokens.space3,
          ),
          children: [
            BespokeDetailHeader(
              icon: Icons.local_activity_rounded,
              tone: _tone,
              title: title,
              subtitle: subtitle,
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
            const SizedBox(height: N.s4),
            Row(
              children: [
                _Tag(icon: Icons.schedule_rounded, label: duration),
              ],
            ),
            const SizedBox(height: AppTokens.space5),
            const Text(
              'PICK A SLOT',
              style: TextStyle(
                color: N.inkLow,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: N.s3),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (final s in const [
                    ('09:00', 'Today'),
                    ('11:30', 'Today'),
                    ('14:00', 'Today'),
                    ('16:30', 'Tomorrow'),
                    ('10:00', 'Tomorrow'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: AppTokens.space2),
                      child: _SlotPill(time: s.$1, day: s.$2),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space5),
            CinematicButton(
              label: 'Reserve · $price',
              icon: Icons.check_circle_rounded,
              onPressed: () => Navigator.of(sheetCtx).maybePop(),
            ),
            const SizedBox(height: AppTokens.space4),
          ],
        );
      },
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(N.rPill),
        color: N.surface,
        border: Border.all(color: N.hairline, width: N.strokeHair),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: N.inkMid),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: N.inkHi,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotPill extends StatelessWidget {
  const _SlotPill({required this.time, required this.day});
  final String time;
  final String day;
  @override
  Widget build(BuildContext context) {
    const tone = Color(0xFF059669);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: N.s4, vertical: N.s2 + 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(N.rCard),
        color: N.surface,
        border: Border.all(
          color: tone.withValues(alpha: 0.36),
          width: N.strokeHair,
        ),
      ),
      child: Column(
        children: [
          Text(
            time,
            style: const TextStyle(
              color: N.inkHi,
              fontWeight: FontWeight.w800,
              fontSize: 15,
              height: 1.0,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            day.toUpperCase(),
            style: const TextStyle(
              color: N.inkLow,
              fontWeight: FontWeight.w700,
              fontSize: 9,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item, required this.tone});
  final Map<String, dynamic> item;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    final title = item['title']?.toString() ?? 'Activity';
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
            child:
                Icon(Icons.local_activity_rounded, color: tone, size: 22),
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
