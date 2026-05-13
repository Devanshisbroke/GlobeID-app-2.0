import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_tokens.dart';
import '../../nexus/nexus_tokens.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/page_scaffold.dart';
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
    return PageScaffold(
      title: widget.title,
      subtitle: widget.subtitle,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: widget.tone,
        backgroundColor: N.surface,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: AnimatedAppearance(
                child: _BespokeHero(
                  title: widget.title,
                  subtitle: widget.subtitle,
                  icon: widget.icon,
                  tone: widget.tone,
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
                            onTap: () => widget.onItemTap(context, items[i]),
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

/// Nexus-grade service hero — hairline panel, tonal icon disc, no
/// shadows, no gradient halo. Sits at the top of every bespoke
/// service vertical and replaces the legacy gradient `PremiumCard.hero`.
class _BespokeHero extends StatelessWidget {
  const _BespokeHero({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tone,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: N.surface,
        borderRadius: BorderRadius.circular(N.rCard),
        border: Border.all(color: N.hairline, width: N.strokeHair),
      ),
      padding: const EdgeInsets.fromLTRB(N.s5, N.s5, N.s5, N.s5),
      child: Row(
        children: [
          // Tonal icon disc — flat fill, hairline ring, no shadow.
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tone.withValues(alpha: 0.14),
              border: Border.all(
                color: tone.withValues(alpha: 0.36),
                width: N.strokeHair,
              ),
            ),
            child: Icon(icon, color: tone, size: 24),
          ),
          const SizedBox(width: N.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: N.inkLow,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: N.inkHi,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    height: 1.25,
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
    return Pressable(
      scale: 0.96,
      onTap: onTap,
      child: AnimatedContainer(
        duration: N.dQuick,
        curve: N.ease,
        padding: const EdgeInsets.symmetric(
          horizontal: N.s4,
          vertical: N.s2,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(N.rPill),
          color: active ? tone.withValues(alpha: 0.16) : N.surface,
          border: Border.all(
            color: active
                ? tone.withValues(alpha: 0.55)
                : N.hairline,
            width: N.strokeHair,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (filter.icon != null) ...[
              Icon(
                filter.icon,
                size: 13,
                color: active ? tone : N.inkMid,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              filter.label,
              style: TextStyle(
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active ? tone : N.inkMid,
                fontSize: 12,
                letterSpacing: 0.2,
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
    const base = Color(0xFF14141A);
    return Shimmer(
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
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(N.rSmall),
              ),
            ),
            const SizedBox(width: N.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
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

/// Nexus-grade detail header used inside service bottom sheets.
///
/// Replaces the legacy `PremiumCard.hero` with a hairline panel +
/// tonal icon disc so the sheet body matches the OLED substrate
/// instead of glowing as a saturated gradient block.
class BespokeDetailHeader extends StatelessWidget {
  const BespokeDetailHeader({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final Color tone;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(N.s5, N.s5, N.s5, N.s5),
      decoration: BoxDecoration(
        color: N.surface,
        borderRadius: BorderRadius.circular(N.rCardLg),
        border: Border.all(color: N.hairline, width: N.strokeHair),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tone.withValues(alpha: 0.14),
              border: Border.all(
                color: tone.withValues(alpha: 0.36),
                width: N.strokeHair,
              ),
            ),
            child: Icon(icon, color: tone, size: 26),
          ),
          const SizedBox(width: N.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: N.inkHi,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: N.inkMid,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: N.s3),
            trailing!,
          ],
        ],
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
    barrierColor: Colors.black.withValues(alpha: 0.62),
    elevation: 0,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (sheetCtx, scroll) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(N.rSheet),
          ),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: N.surface,
              border: Border(
                top: BorderSide(color: N.hairline, width: N.strokeHair),
                left: BorderSide(color: N.hairline, width: N.strokeHair),
                right: BorderSide(color: N.hairline, width: N.strokeHair),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  decoration: BoxDecoration(
                    color: N.hairlineHi,
                    borderRadius: BorderRadius.circular(N.rPill),
                  ),
                ),
                Expanded(child: builder(sheetCtx, scroll)),
              ],
            ),
          ),
        );
      },
    ),
  );
}
