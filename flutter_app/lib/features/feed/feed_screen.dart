import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../../widgets/skeletons.dart';
import '../insights/insights_provider.dart';

/// Activity feed v3 — premium event timeline.
///
/// Adds a category filter rail, density toggle (compact / comfortable),
/// pull-to-refresh, day-bucket headers, and an accent rail down the
/// left side of every row to make the activity feel chronological
/// rather than a flat list.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});
  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  String _filter = 'all';
  bool _compact = false;

  static const _filters = <_FeedFilter>[
    _FeedFilter('all', 'All', Icons.bolt_rounded),
    _FeedFilter('trip', 'Trips', Icons.flight_takeoff_rounded),
    _FeedFilter('wallet', 'Wallet', Icons.account_balance_wallet_rounded),
    _FeedFilter('identity', 'Identity', Icons.fingerprint_rounded),
    _FeedFilter('scan', 'Scans', Icons.qr_code_scanner_rounded),
    _FeedFilter('pass', 'Passes', Icons.confirmation_number_rounded),
    _FeedFilter('booking', 'Bookings', Icons.event_available_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final activity = ref.watch(activityInsightsProvider);
    final theme = Theme.of(context);
    return PageScaffold(
      title: 'Activity',
      subtitle: 'Your recent travel activity',
      actions: [
        IconButton(
          tooltip: _compact ? 'Comfortable density' : 'Compact density',
          icon: Icon(
            _compact
                ? Icons.density_medium_rounded
                : Icons.density_large_rounded,
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            setState(() => _compact = !_compact);
          },
        ),
      ],
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: () async {
          HapticFeedback.lightImpact();
          // ignore: unused_result
          ref.refresh(activityInsightsProvider);
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: activity.when(
          loading: () => const SkeletonList(count: 6, itemHeight: 76),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              const SizedBox(height: 64),
              EmptyState(
                title: 'Activity unavailable',
                message: e.toString(),
                icon: Icons.cloud_off_rounded,
              ),
            ],
          ),
          data: (data) {
            final raw = (data['items'] as List?) ?? const [];
            final items = raw.cast<Map<String, dynamic>>();
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: const [
                  SizedBox(height: 64),
                  EmptyState(
                    title: 'No activity yet',
                    message: 'Your scans, trips, and bookings live here.',
                    icon: Icons.bolt_rounded,
                  ),
                ],
              );
            }
            // Filter by selected category.
            final filtered = _filter == 'all'
                ? items
                : items.where((e) => (e['type'] ?? '') == _filter).toList();
            // Bucket by day labels (deterministic since the demo data
            // doesn't carry timestamps).
            final buckets = _bucketize(filtered);
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                AnimatedAppearance(
                  child: SizedBox(
                    height: 50,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      itemCount: _filters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final f = _filters[i];
                        return _FilterChip(
                          filter: f,
                          selected: _filter == f.id,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _filter = f.id);
                          },
                        );
                      },
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 64),
                    child: EmptyState(
                      title: 'No matches',
                      message:
                          'No activity matches the “${_labelFor(_filter)}” filter.',
                      icon: Icons.filter_list_rounded,
                    ),
                  ),
                for (final entry in buckets.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      0,
                      AppTokens.space4,
                      0,
                      AppTokens.space2,
                    ),
                    child: Text(
                      entry.key.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  for (var i = 0; i < entry.value.length; i++)
                    AnimatedAppearance(
                      delay: Duration(milliseconds: 30 * i),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppTokens.space2,
                        ),
                        child: _Row(
                          data: entry.value[i],
                          accent: _accentForType(
                            entry.value[i]['type']?.toString() ?? '',
                          ),
                          compact: _compact,
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: AppTokens.space9),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Deterministic bucketing by relative recency. Splits the item
  /// list into 4 day-groups: Today, Yesterday, This week, Earlier.
  Map<String, List<Map<String, dynamic>>> _bucketize(
    List<Map<String, dynamic>> items,
  ) {
    final out = <String, List<Map<String, dynamic>>>{
      'Today': [],
      'Yesterday': [],
      'This week': [],
      'Earlier': [],
    };
    for (var i = 0; i < items.length; i++) {
      if (i < 2) {
        out['Today']!.add(items[i]);
      } else if (i < 4) {
        out['Yesterday']!.add(items[i]);
      } else if (i < 8) {
        out['This week']!.add(items[i]);
      } else {
        out['Earlier']!.add(items[i]);
      }
    }
    out.removeWhere((_, v) => v.isEmpty);
    return out;
  }

  Color _accentForType(String type) {
    switch (type) {
      case 'trip':
        return const Color(0xFF06B6D4);
      case 'scan':
        return const Color(0xFF7C3AED);
      case 'booking':
        return const Color(0xFF10B981);
      case 'identity':
        return const Color(0xFFEC4899);
      case 'pass':
        return const Color(0xFFF59E0B);
      case 'wallet':
        return const Color(0xFF6366F1);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  String _labelFor(String id) =>
      _filters.firstWhere((f) => f.id == id, orElse: () => _filters[0]).label;
}

class _FeedFilter {
  const _FeedFilter(this.id, this.label, this.icon);
  final String id;
  final String label;
  final IconData icon;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.filter,
    required this.selected,
    required this.onTap,
  });
  final _FeedFilter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTokens.durationSm,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          gradient: selected
              ? LinearGradient(colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ])
              : null,
          color: selected
              ? null
              : theme.colorScheme.onSurface.withValues(alpha: 0.06),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : theme.colorScheme.onSurface.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filter.icon,
              size: 14,
              color: selected
                  ? Colors.white
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              filter.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected
                    ? Colors.white
                    : theme.colorScheme.onSurface.withValues(alpha: 0.85),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.data,
    required this.accent,
    required this.compact,
  });
  final Map<String, dynamic> data;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = data['title']?.toString() ?? '';
    final subtitle = data['subtitle']?.toString() ?? '';
    final type = data['type']?.toString() ?? '';
    return PremiumCard(
      padding: EdgeInsets.symmetric(
        horizontal: AppTokens.space3,
        vertical: compact ? AppTokens.space2 : AppTokens.space3,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Accent rail.
            Container(
              width: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: accent.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(width: AppTokens.space3),
            // Icon chip.
            Container(
              width: compact ? 32 : 40,
              height: compact ? 32 : 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.32),
                    accent.withValues(alpha: 0.12),
                  ],
                ),
              ),
              child: Icon(
                _iconFor(type),
                color: accent,
                size: compact ? 16 : 20,
              ),
            ),
            const SizedBox(width: AppTokens.space3),
            // Body.
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: (compact
                            ? theme.textTheme.bodyMedium
                            : theme.textTheme.titleSmall)
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (!compact && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                color: accent.withValues(alpha: 0.16),
              ),
              child: Text(
                _labelForType(type).toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'trip':
        return Icons.flight_takeoff_rounded;
      case 'scan':
        return Icons.qr_code_scanner_rounded;
      case 'booking':
        return Icons.event_available_rounded;
      case 'identity':
        return Icons.fingerprint_rounded;
      case 'pass':
        return Icons.confirmation_number_rounded;
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  String _labelForType(String type) {
    switch (type) {
      case 'trip':
        return 'Trip';
      case 'scan':
        return 'Scan';
      case 'booking':
        return 'Book';
      case 'identity':
        return 'ID';
      case 'pass':
        return 'Pass';
      case 'wallet':
        return 'Wallet';
      default:
        return 'Other';
    }
  }
}
