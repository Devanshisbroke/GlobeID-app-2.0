import 'package:flutter/material.dart';

import '../app/theme/app_tokens.dart';
import 'bible/liquid_glass.dart';

/// Premium card built on the unified [LiquidGlass] material primitive.
///
/// `glass=true` (the default) routes through `LiquidGlass(thickness: regular)`
/// so every premium card in the app shares the same:
///   - saturate-then-blur composition (iOS-17 chrome trick)
///   - 0.5-pt specular top edge
///   - hairline stroke
///   - cinematic ambient shadow
///   - continuous-curve squircle corners
///   - reduce-transparency accessibility fallback
///
/// `gradient`-painted cards (used for some hero panels) keep their
/// painted body but render the body inside a glass wrapper so the
/// outline / shadow / specular language is consistent. Setting
/// `glass=false` produces a flat opaque card via the [PremiumCard.flat]
/// factory.
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
    // Map elevation → LiquidGlass shadow tier.
    final shadow = switch (elevation) {
      PremiumElevation.none => LiquidGlassShadow.none,
      PremiumElevation.sm => LiquidGlassShadow.resting,
      PremiumElevation.md => LiquidGlassShadow.cinematic,
      PremiumElevation.lg => LiquidGlassShadow.floating,
    };

    // Gradient hero variant: paint the gradient as the body, wrap in
    // the same shadow + stroke language but without glass blur.
    if (gradient != null) {
      return LiquidGlass(
        thickness: LiquidGlassThickness.ultraThin,
        radius: radius,
        tint: tint,
        shadow: shadow,
        stroke: true,
        specular: true,
        // Clip the gradient inside the same continuous-curve clip.
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: gradient),
          child: Padding(padding: padding, child: child),
        ),
      );
    }

    return LiquidGlass(
      // `glass=false` collapses to ultraThin so the surface is
      // virtually opaque but still inherits the unified language.
      thickness:
          glass ? LiquidGlassThickness.regular : LiquidGlassThickness.ultraThin,
      radius: radius,
      tint: tint,
      padding: padding,
      shadow: shadow,
      stroke: true,
      specular: true,
      child: child,
    );
  }
}

enum PremiumElevation { none, sm, md, lg }
