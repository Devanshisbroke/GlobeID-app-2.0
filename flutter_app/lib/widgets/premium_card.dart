import 'dart:ui';

import 'package:flutter/material.dart';

import '../app/theme/app_tokens.dart';

/// Multi-layer premium card. Uses:
///   1. base canvas tint (theme card color or override)
///   2. inner gradient sheen (subtle, top-down white wash)
///   3. 1px hairline border on dark to add definition
///   4. soft shadow ladder
///
/// `glass=true` adds a 24px BackdropFilter blur (auto-disabled when
/// reduce-transparency is on via the theme `GlassExtension`).
class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTokens.space5),
    this.radius = AppTokens.radius2xl,
    this.tint,
    this.gradient,
    this.glass = true,
    this.elevation = PremiumElevation.md,
    this.borderColor,
  });

  factory PremiumCard.flat({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppTokens.space5),
    double radius = AppTokens.radius2xl,
    Color? tint,
  }) =>
      PremiumCard(
        key: key,
        padding: padding,
        radius: radius,
        tint: tint,
        glass: false,
        elevation: PremiumElevation.sm,
        child: child,
      );

  factory PremiumCard.hero({
    Key? key,
    required Widget child,
    required Gradient gradient,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppTokens.space6),
    double radius = AppTokens.radius3xl,
  }) =>
      PremiumCard(
        key: key,
        padding: padding,
        radius: radius,
        gradient: gradient,
        glass: false,
        elevation: PremiumElevation.lg,
        child: child,
      );

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;
  final Gradient? gradient;
  final bool glass;
  final PremiumElevation elevation;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reduceTransparency = MediaQuery.of(context).disableAnimations;
    final allowGlass = glass && !reduceTransparency;

    final base = tint ??
        (gradient != null
            ? Colors.transparent
            : (isDark ? AppTokens.cardDark : AppTokens.cardLight));

    final shadows = switch (elevation) {
      PremiumElevation.none => const <BoxShadow>[],
      PremiumElevation.sm => AppTokens.shadowSm(),
      PremiumElevation.md => AppTokens.shadowMd(),
      PremiumElevation.lg => AppTokens.shadowLg(),
    };

    final border = Border.all(
      color: borderColor ??
          (isDark ? AppTokens.borderDark : AppTokens.borderLight),
      width: 0.6,
    );

    final clip = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        children: [
          // Base tint layer (gradient or solid).
          if (gradient != null)
            Positioned.fill(
                child:
                    DecoratedBox(decoration: BoxDecoration(gradient: gradient)))
          else
            Positioned.fill(
                child: ColoredBox(
                    color: base.withValues(alpha: allowGlass ? 0.55 : 0.92))),
          // Sheen layer — top-down faint white wash.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: isDark ? 0.06 : 0.4),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );

    final outer = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadows,
        border: border,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: allowGlass
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: clip,
              )
            : clip,
      ),
    );

    return outer;
  }
}

enum PremiumElevation { none, sm, md, lg }
