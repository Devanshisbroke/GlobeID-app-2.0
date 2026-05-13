import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../nexus/chrome/nexus_legacy_scaffold.dart';
import '../../widgets/animated_appearance.dart';
import '../../cinematic/states/cinematic_states.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/premium/premium.dart';
import '../../widgets/pressable.dart';
import 'inbox_models.dart';
import 'inbox_provider.dart';

/// Full-screen inbox with grouped sections, kind filters, swipe-to-
/// dismiss, mark-all-read, and deep-link navigation. Routes from
/// `/inbox`. Designed to feel like Apple Notification Center crossed
/// with Linear's notifications panel.
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  InboxKind? _filter; // null = all

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = ref.watch(inboxProvider);
    final filtered =
        _filter == null ? all : all.where((i) => i.kind == _filter).toList();
    final unread = all.where((i) => !i.read).length;

    final groups = _groupByDay(filtered);

    return NexusLegacyScaffold(
      eyebrow: 'GLOBE ID · INBOX',
      title: 'Inbox',
      subtitle: unread > 0
          ? '$unread unread · ${all.length} total'
          : 'All caught up · ${all.length} total',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Mark all read',
            onPressed: unread == 0
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    ref.read(inboxProvider.notifier).markAllRead();
                  },
            icon: const Icon(Icons.done_all_rounded, size: 20),
          ),
          IconButton(
            tooltip: 'Clear all',
            onPressed: all.isEmpty
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    ref.read(inboxProvider.notifier).clear();
                  },
            icon: const Icon(Icons.delete_sweep_rounded, size: 20),
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Filter chip strip.
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: AppTokens.space5),
                children: [
                  _FilterChip(
                    label: 'All',
                    count: all.length,
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  for (final k in InboxKind.values)
                    Builder(builder: (_) {
                      final res = resolveInboxKind(k);
                      final n = all.where((i) => i.kind == k).length;
                      return _FilterChip(
                        label: res.label,
                        count: n,
                        accent: res.accent,
                        icon: res.icon,
                        selected: _filter == k,
                        onTap: () => setState(() => _filter = k),
                      );
                    }),
                ],
              ),
            ),
          ),

          if (filtered.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Os2EmptyState(
                eyebrow: 'GLOBEID · INBOX',
                title: 'All caught up',
                message: 'New notifications will appear here — boarding calls, gate changes, advisories, and signed receipts.',
                icon: Icons.notifications_off_rounded,
              ),
            ),

          // Pinned premium rail of the most recent unread items.
          if (filtered.isNotEmpty)
            SliverToBoxAdapter(
              child: _PinnedPremiumRail(items: filtered.take(2).toList()),
            ),

          for (final g in groups) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.space5,
                  AppTokens.space5,
                  AppTokens.space5,
                  AppTokens.space2,
                ),
                child: Text(
                  g.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
            SliverList.builder(
              itemCount: g.items.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.space5,
                  AppTokens.space2,
                  AppTokens.space5,
                  0,
                ),
                child: AnimatedAppearance(
                  delay: Duration(milliseconds: 30 * i),
                  child: _InboxRow(item: g.items[i]),
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space9)),
        ],
      ),
    );
  }

  List<_DayGroup> _groupByDay(List<InboxItem> items) {
    if (items.isEmpty) return const [];
    final sorted = [...items]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final earlier = <InboxItem>[];
    final t = <InboxItem>[];
    final y = <InboxItem>[];
    for (final it in sorted) {
      final d =
          DateTime(it.timestamp.year, it.timestamp.month, it.timestamp.day);
      if (d == today) {
        t.add(it);
      } else if (d == yesterday) {
        y.add(it);
      } else {
        earlier.add(it);
      }
    }
    return [
      if (t.isNotEmpty) _DayGroup('Today', t),
      if (y.isNotEmpty) _DayGroup('Yesterday', y),
      if (earlier.isNotEmpty) _DayGroup('Earlier', earlier),
    ];
  }
}

class _DayGroup {
  const _DayGroup(this.label, this.items);
  final String label;
  final List<InboxItem> items;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.accent,
    this.icon,
  });
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final Color? accent;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = accent ?? theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(right: AppTokens.space2),
      child: Pressable(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space3, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? tone.withValues(alpha: 0.18)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTokens.radiusFull),
            border: Border.all(
              color: selected
                  ? tone.withValues(alpha: 0.55)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: selected ? tone : null),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? tone : null,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InboxRow extends ConsumerWidget {
  const _InboxRow({required this.item});
  final InboxItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final res = resolveInboxKind(item.kind);
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        ref.read(inboxProvider.notifier).dismiss(item.id);
      },
      background: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space5),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: const Color(0xFFE11D48).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTokens.radiusXl),
        ),
        child:
            const Icon(Icons.delete_outline_rounded, color: Color(0xFFE11D48)),
      ),
      child: Pressable(
        scale: 0.99,
        onTap: () {
          HapticFeedback.lightImpact();
          ref.read(inboxProvider.notifier).markRead(item.id);
          GoRouter.of(context).push(item.deeplink);
        },
        child: GlassSurface(
          radius: AppTokens.radiusXl,
          padding: const EdgeInsets.all(AppTokens.space4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: res.accent.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                ),
                child: Icon(item.heroIcon ?? res.icon,
                    color: res.accent, size: 20),
              ),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight:
                                  item.read ? FontWeight.w600 : FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _relative(item.timestamp),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.70),
                      ),
                    ),
                    const SizedBox(height: AppTokens.space2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: res.accent.withValues(alpha: 0.14),
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusFull),
                          ),
                          child: Row(
                            children: [
                              Icon(res.icon, size: 10, color: res.accent),
                              const SizedBox(width: 4),
                              Text(
                                res.label,
                                style: TextStyle(
                                  color: res.accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (item.priority == InboxPriority.high ||
                            item.priority == InboxPriority.critical) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE11D48)
                                  .withValues(alpha: 0.14),
                              borderRadius:
                                  BorderRadius.circular(AppTokens.radiusFull),
                            ),
                            child: const Text(
                              'PRIORITY',
                              style: TextStyle(
                                color: Color(0xFFE11D48),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (!item.read)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _relative(DateTime ts) {
    final d = DateTime.now().difference(ts);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }
}

class _PinnedPremiumRail extends ConsumerWidget {
  const _PinnedPremiumRail({required this.items});
  final List<InboxItem> items;

  String _relative(DateTime ts) {
    final d = DateTime.now().difference(ts);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppTokens.space2),
      child: Column(
        children: [
          for (final item in items)
            InboxPremiumRow(
              icon: item.heroIcon ?? resolveInboxKind(item.kind).icon,
              title: item.title,
              subtitle: item.body,
              tone: resolveInboxKind(item.kind).accent,
              timestamp: _relative(item.timestamp),
              unread: !item.read,
              onTap: () {
                ref.read(inboxProvider.notifier).markRead(item.id);
                GoRouter.of(context).push(item.deeplink);
              },
            ),
        ],
      ),
    );
  }
}
