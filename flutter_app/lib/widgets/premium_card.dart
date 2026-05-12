import 'package:flutter/material.dart';

import '../app/theme/app_tokens.dart';
import '../nexus/nexus_tokens.dart';

/// Premium card — **Nexus-aligned hairline panel.**
///
/// Was previously a multi-layer LiquidGlass surface with blur + sheen +
/// ambient shadows. After the canonical Travel-OS / Wallet redesign
/// migration, this primitive now renders the Lovable hairline-card
/// language across the entire legacy feature tree:
///
///   - flat dark surface (`N.surface`) sitting directly on the OLED bg
///   - 0.5pt `N.hairline` border
///   - generous radius (defaults to `N.rCard = 18`)
///   - **no shadow** and **no specular** — depth is conveyed by the
///     hairline alone (Nothing-OS / Linear language)
///   - hero variant keeps a soft tinted wash + 1px tonal border for
///     focal surfaces, still without blur
///
/// The public API is preserved so all 51 callers across the legacy
/// `lib/features/*` tree get the new visual language for free.
class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTokens.space5),
    this.radius = AppTokens.radiusXl,
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
    double radius = AppTokens.radiusLg,
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
    double radius = AppTokens.radius2xl,
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
    // Hero gradient variant — paint the gradient under a hairline; no
    // shadow. The brand wash is the only visual lift.
    if (gradient != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor ??
                  N.tierGold.withValues(alpha: 0.32),
              width: 0.5,
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      );
    }

    // Optional tint wash for focal panels (used by a few wallet /
    // identity hero cards). Tone-only, no neon.
    final Color background = tint == null
        ? N.surface
        : Color.alphaBlend(
            tint!.withValues(alpha: 0.05),
            N.surface,
          );

    final Color border = borderColor ??
        (tint == null
            ? N.hairline
            : tint!.withValues(alpha: 0.28));

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: border,
          width: 0.5,
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

enum PremiumElevation { none, sm, md, lg }
