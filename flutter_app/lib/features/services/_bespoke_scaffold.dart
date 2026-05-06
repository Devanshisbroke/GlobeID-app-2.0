import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../../widgets/shimmer.dart';

/// Bespoke service shell — used by Hotels / Rides / Food / Activities /
/// Transport screens. Provides:
///   • Hero gradient + service icon
///   • Live filter chips
///   • Skeleton loader (Shimmer'd row stand-ins)
///   • RefreshIndicator + FutureBuilder
///   • Pluggable row/detail builders so each vertical can have its
///     own card layout + drilldown sheet without duplicating the
///     scaffold.
class BespokeServiceShell<T> extends StatefulWidget {
  const BespokeServiceShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tone,
    required this.fetcher,
    required this.itemBuilder,
    required this.onItemTap,
    this.filters = const [],
    this.heroAccent,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tone;
  final Color? heroAccent;
  final Future<List<T>> Function(String? activeFilter) fetcher;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final void Function(BuildContext context, T item) onItemTap;
  final List<BespokeFilter> filters;

  @override
  State<BespokeServiceShell<T>> createState() => _BespokeServiceShellState<T>();
}

class _BespokeServiceShellState<T> extends State<BespokeServiceShell<T>> {
  String? _activeFilter;
  late Future<List<T>> _future = widget.fetcher(_activeFilter);

  Future<void> _refresh() async {
    HapticFeedback.lightImpact();
    setState(() => _future = widget.fetcher(_activeFilter));
    await _future;
  }

  void _setFilter(String? key) {
    if (_activeFilter == key) return;
    HapticFeedback.selectionClick();
    setState(() {
      _activeFilter = key;
      _future = widget.fetcher(key);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PageScaffold(
      title: widget.title,
      subtitle: widget.subtitle,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: widget.tone,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: AnimatedAppearance(
                child: PremiumCard.hero(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.tone.withValues(alpha: 0.42),
                      (widget.heroAccent ?? widget.tone)
                          .withValues(alpha: 0.18),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.20),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withValues(alpha: 0.18),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(widget.icon,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: AppTokens.space4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.title,
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                )),
                            Text(widget.subtitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white
                                      .withValues(alpha: 0.85),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.filters.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppTokens.space4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Row(
                      children: [
                        for (final f in widget.filters)
                          Padding(
                            padding:
                                const EdgeInsets.only(right: AppTokens.space2),
                            child: _FilterPill(
                              filter: f,
                              active: _activeFilter == f.key,
                              tone: widget.tone,
                              onTap: () => _setFilter(
                                _activeFilter == f.key ? null : f.key,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.space3),
              sliver: FutureBuilder<List<T>>(
                future: _future,
                builder: (_, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => const Padding(
                          padding: EdgeInsets.only(bottom: AppTokens.space3),
                          child: _BespokeSkeleton(),
                        ),
                        childCount: 5,
                      ),
                    );
                  }
                  if (snap.hasError) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        title: '${widget.title} unavailable',
                        message: snap.error.toString(),
                        icon: Icons.cloud_off_rounded,
                      ),
                    );
                  }
                  final items = snap.data ?? const [];
                  if (items.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        title: 'Nothing nearby',
                        message:
                            'Tell us where you\'re heading and we\'ll find ${widget.title.toLowerCase()}.',
                        icon: widget.icon,
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => AnimatedAppearance(
                        delay: Duration(milliseconds: 50 * i),
                        child: Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppTokens.space3),
                          child: Pressable(
                            scale: 0.985,
                            onTap: () =>
                                widget.onItemTap(context, items[i]),
                            child: widget.itemBuilder(context, items[i], i),
                          ),
                        ),
                      ),
                      childCount: items.length,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BespokeFilter {
  const BespokeFilter({required this.key, required this.label, this.icon});
  final String key;
  final String label;
  final IconData? icon;
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.filter,
    required this.active,
    required this.tone,
    required this.onTap,
  });
  final BespokeFilter filter;
  final bool active;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      scale: 0.96,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTokens.durationSm,
        curve: AppTokens.easeOutSoft,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space3,
          vertical: AppTokens.space2,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          color: active
              ? tone.withValues(alpha: 0.20)
              : theme.colorScheme.surface.withValues(alpha: 0.55),
          border: Border.all(
            color: active
                ? tone.withValues(alpha: 0.55)
                : theme.colorScheme.onSurface.withValues(alpha: 0.10),
            width: 0.7,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: tone.withValues(alpha: 0.20),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (filter.icon != null) ...[
              Icon(filter.icon,
                  size: 14,
                  color: active
                      ? tone
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7)),
              const SizedBox(width: 5),
            ],
            Text(
              filter.label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active
                    ? tone
                    : theme.colorScheme.onSurface.withValues(alpha: 0.78),
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BespokeSkeleton extends StatelessWidget {
  const _BespokeSkeleton();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.onSurface.withValues(alpha: 0.06);
    return Shimmer(
      child: PremiumCard(
        padding: const EdgeInsets.all(AppTokens.space4),
        glass: false,
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              ),
            ),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 180,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: 120,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: 90,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Open a polished bottom-sheet detail view. Receives a builder that
/// renders the body — the sheet handles backdrop blur, drag handle,
/// and theming.
Future<void> showBespokeDetail({
  required BuildContext context,
  required Widget Function(BuildContext, ScrollController) builder,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (sheetCtx, scroll) {
        final theme = Theme.of(sheetCtx);
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.86),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                    ),
                  ),
                  Expanded(child: builder(sheetCtx, scroll)),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
