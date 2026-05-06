import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/api/api_provider.dart';
import '../../widgets/cinematic_button.dart';
import '../../widgets/premium_card.dart';
import '_bespoke_scaffold.dart';

/// Activities — local experiences with category filters and a detail
/// sheet showing time-slot picker and reserve CTA.
class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});

  static const _tone = Color(0xFF059669);
  static const _filters = [
    BespokeFilter(key: 'tour', label: 'Tours', icon: Icons.tour_rounded),
    BespokeFilter(
        key: 'museum', label: 'Museums', icon: Icons.museum_rounded),
    BespokeFilter(
        key: 'food', label: 'Food tours', icon: Icons.restaurant_menu_rounded),
    BespokeFilter(
        key: 'outdoor', label: 'Outdoors', icon: Icons.terrain_rounded),
    BespokeFilter(key: 'kids', label: 'Family', icon: Icons.family_restroom_rounded),
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
        final theme = Theme.of(sheetCtx);
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
            PremiumCard.hero(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF059669), Color(0xFF22D3EE)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_activity_rounded,
                          color: Colors.white, size: 30),
                      const SizedBox(width: AppTokens.space3),
                      Expanded(
                        child: Text(title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            )),
                      ),
                      Text(price,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          )),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space2),
                  Text(subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      )),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space5),
            _Tag(icon: Icons.schedule_rounded, label: duration),
            const SizedBox(height: AppTokens.space5),
            Text('Pick a slot', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTokens.space3),
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
                      padding:
                          const EdgeInsets.only(right: AppTokens.space2),
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space3, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        color: theme.colorScheme.surface.withValues(alpha: 0.7),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              )),
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space4, vertical: AppTokens.space2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        color: const Color(0xFF059669).withValues(alpha: 0.14),
        border: Border.all(
          color: const Color(0xFF059669).withValues(alpha: 0.40),
        ),
      ),
      child: Column(
        children: [
          Text(time,
              style: theme.textTheme.titleSmall?.copyWith(
                color: const Color(0xFF059669),
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              )),
          Text(day,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              )),
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
    final theme = Theme.of(context);
    final title = item['title']?.toString() ?? 'Activity';
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
            child: const Icon(Icons.local_activity_rounded,
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
                Text(subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
