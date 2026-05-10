// GlobeID UI/UX Bible — collapsing iOS-grade top bar.
//
// Bible §4.3 "Glass" + §9.2 "The Shell is sacred". Each primary tab
// pins a [BibleTopBar] at the top of its scroll surface. As the user
// scrolls down, the bar collapses from a 116-pt large-title hero
// (Cupertino-style "navigation bar with large title") to a 56-pt
// frosted compact bar. The actions slot — identity pill, inbox bell,
// theme cycler — lives inside this bar, replacing the absolute-
// positioned floating chrome that used to clip behind content on
// narrow Android viewports.
//
// Typography is bible-aligned: large title uses `headlineLarge`
// weight with -0.6 letter-spacing (SF Pro Display feel), subtitle
// uses `bodyMedium` at 0.6 alpha. Compact title uses `titleMedium`
// with the same -0.4 spacing.
//
// Material is a true frosted glass — backdrop blur σ=18 with a 50 %
// luminosity-aware tint and a hair-line border at the bottom that
// fades in as the bar collapses. This is the "ultrathin material"
// effect Apple ships in iOS 17 and OneUI 6.
//
// Usage:
//   CustomScrollView(
//     slivers: [
//       BibleTopBar(
//         title: 'Wallet',
//         subtitle: 'Treasury · 6 currencies',
//         actions: [...],
//       ),
//       ...rest,
//     ],
//   );

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/app_tokens.dart';
import '../../app/theme/ux_bible.dart';

/// iOS / OneUI grade collapsing top bar with frosted material,
/// large title, and a right-side actions slot.
///
/// Typical use: place as the first sliver in a [CustomScrollView],
/// followed by the screen content as further slivers.
class BibleTopBar extends StatelessWidget {
  const BibleTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.leading,
    this.tone,
    this.expandedHeight = 116,
    this.compactHeight = 56,
  });

  /// Large title (e.g. "Wallet"). Also shown collapsed.
  final String title;

  /// Optional one-line subtitle below the large title.
  final String? subtitle;

  /// Right-aligned chrome (identity pill, inbox bell, theme cycler).
  final List<Widget> actions;

  /// Optional leading widget (e.g. back button or avatar).
  final Widget? leading;

  /// Optional accent tone for the title underline / glow.
  final Color? tone;

  /// Height when fully expanded (large-title visible).
  final double expandedHeight;

  /// Height when fully collapsed (compact bar).
  final double compactHeight;

  @override
  Widget build(BuildContext context) {
    final mediaTop = MediaQuery.of(context).padding.top;
    return SliverPersistentHeader(
      pinned: true,
      delegate: _BibleTopBarDelegate(
        title: title,
        subtitle: subtitle,
        actions: actions,
        leading: leading,
        tone: tone,
        topInset: mediaTop,
        expandedHeight: expandedHeight + mediaTop,
        compactHeight: compactHeight + mediaTop,
      ),
    );
  }
}

class _BibleTopBarDelegate extends SliverPersistentHeaderDelegate {
  _BibleTopBarDelegate({
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.leading,
    required this.tone,
    required this.topInset,
    required this.expandedHeight,
    required this.compactHeight,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? leading;
  final Color? tone;
  final double topInset;
  final double expandedHeight;
  final double compactHeight;

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => compactHeight;

  @override
  bool shouldRebuild(covariant _BibleTopBarDelegate old) {
    return title != old.title ||
        subtitle != old.subtitle ||
        actions.length != old.actions.length ||
        leading != old.leading ||
        tone != old.tone ||
        topInset != old.topInset ||
        expandedHeight != old.expandedHeight ||
        compactHeight != old.compactHeight;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final glass = GlassExtension.of(context);
    final delta = (expandedHeight - compactHeight).clamp(1.0, double.infinity);
    final t = (shrinkOffset / delta).clamp(0.0, 1.0);
    final accent = tone ?? theme.colorScheme.primary;

    // Bible §4.3 — frost intensity rises as the bar collapses. At full
    // extent the bar is fully transparent so the wallpaper / living
    // gradient is visible; at full collapse it's a true frosted slab.
    // The ramp uses easeOutCubic so the frost lands quickly once the
    // user starts scrolling, then plateaus.
    final frost = Curves.easeOutCubic.transform(t);

    // Scroll-reactive blur sigma — ramps 0 → 24 with the collapse so
    // the bar feels weightless at full extent and becomes a heavy
    // material slab when content is sliding under it.
    final blurSigma = 24.0 * frost;

    final largeTitleOpacity = (1.0 - t * 1.4).clamp(0.0, 1.0);
    final compactTitleOpacity = ((t - 0.55) / 0.45).clamp(0.0, 1.0);
    // Bible §6.2 — large title parallax: slide up faster than the
    // scroll velocity so it tucks under the compact bar with a sense
    // of depth, not a 1:1 slide. -12 px at full collapse.
    final largeTitleSlide = -12.0 * Curves.easeOutQuad.transform(t);

    final compact = compactHeight;
    final actionsRow = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          actions[i],
        ],
      ],
    );

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Frosted backdrop — scroll-reactive blur σ from 0→24 as
          // the bar collapses. Bible §4.3 ultrathin material: heavier
          // tint in dark mode (0→0.42 alpha black) so OLED-first
          // canvas reads as a true layer above content; light mode
          // uses a luminosity-aware white veil.
          if (!glass.reduceTransparency)
            Positioned.fill(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: blurSigma,
                  sigmaY: blurSigma,
                ),
                child: Container(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.42 * frost)
                      : Colors.white.withValues(alpha: 0.62 * frost),
                ),
              ),
            )
          else
            Positioned.fill(
              child: Opacity(
                opacity: frost,
                child: Container(color: glass.surface.withValues(alpha: 0.92)),
              ),
            ),
          // Specular top edge — a 1-pt glint along the top edge
          // simulates light catching the frosted surface (iOS 17 /
          // OneUI 6 ultrathin material trick). Only visible when the
          // bar has frost (avoids drawing on a transparent expanded
          // bar).
          if (!glass.reduceTransparency)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Opacity(
                opacity: frost * 0.9,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.10),
                              Colors.transparent,
                            ]
                          : [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.55),
                              Colors.transparent,
                            ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          // Hair-line bottom border (fades in with frost).
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Opacity(
              opacity: frost,
              child: Container(
                height: 0.6,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
              ),
            ),
          ),
          // Compact title (centred-left, fades in late).
          Positioned(
            top: topInset,
            left: 0,
            right: 0,
            height: compact - topInset,
            child: Opacity(
              opacity: compactTitleOpacity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (leading != null) ...[leading!, const SizedBox(width: 8)],
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    actionsRow,
                  ],
                ),
              ),
            ),
          ),
          // Large title block (fades / slides out as we collapse).
          Positioned(
            left: 16,
            right: 12,
            top: topInset + 4,
            child: IgnorePointer(
              ignoring: t > 0.7,
              child: Opacity(
                opacity: largeTitleOpacity,
                child: Transform.translate(
                  offset: Offset(0, largeTitleSlide),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                                height: 1.05,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.62),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      actionsRow,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Bible §4.4 — accent underline glows softly under the
          // large title at full extent and recedes on collapse.
          Positioned(
            left: 16,
            top: topInset + 52,
            child: Opacity(
              opacity: largeTitleOpacity * 0.85,
              child: Container(
                width: 28,
                height: 2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [
                      accent,
                      accent.withValues(alpha: 0.0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: -2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Convenience: a compact circular icon-button that fits the
/// [BibleTopBar.actions] slot. Uses ultrathin frosted material so it
/// reads clearly against any backdrop.
class BibleTopBarAction extends StatelessWidget {
  const BibleTopBarAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.badgeCount = 0,
    this.tone,
    this.onLongPress,
  });

  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? tooltip;
  final int badgeCount;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final glass = GlassExtension.of(context);
    final core = Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        onLongPress: onLongPress == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onLongPress!();
              },
        child: Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: glass.reduceTransparency
                ? glass.surface.withValues(alpha: 0.94)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.58)),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
              width: 0.6,
            ),
            boxShadow: AppTokens.shadowSm(),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: tone ??
                    theme.colorScheme.onSurface.withValues(alpha: 0.82),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: BibleSignal.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return tooltip == null
        ? core
        : Tooltip(message: tooltip!, child: core);
  }
}
