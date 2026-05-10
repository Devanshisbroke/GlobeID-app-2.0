import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../app/theme/emotional_palette.dart';
import '../bible/liquid_glass.dart';

/// A morphing surface that adapts its tint, elevation, and shape to
/// the surrounding emotional context.
///
/// Now built on top of [LiquidGlass] (the unified Apple-grade material
/// primitive). The previous bespoke `Stack`+`BackdropFilter` pipeline
/// has been replaced by a single `LiquidGlass(thickness: regular)` so
/// every surface in the app shares the same:
///
///   - saturate-then-blur composition (iOS-17 chrome trick)
///   - 0.5-pt specular top edge
///   - hairline stroke
///   - cinematic ambient shadow
///   - reduce-transparency accessibility fallback
///
/// The emotional accent (gold/cool/warm depending on [EmotionalContext])
/// is forwarded as the [LiquidGlass.tint] so it still inherits the
/// screen's bible tone, but only as a low-alpha colour bleed — the
/// glass body itself is luminosity-aware, not painted with a flat
/// gradient.
class ContextualSurface extends StatelessWidget {
  const ContextualSurface({
    super.key,
    required this.child,
    this.context,
    this.padding = const EdgeInsets.all(AppTokens.space5),
    this.radius = AppTokens.radius2xl,
    this.glass = true,
    this.tint,
    this.outlined = false,
  });

  final Widget child;
  final EmotionalContext? context;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool glass;
  final Color? tint;
  final bool outlined;

  @override
  Widget build(BuildContext build) {
    final theme = Theme.of(build);
    final shift = context == null
        ? const EmotionalShift()
        : EmotionalPalette.shiftFor(context!);

    final accent = tint ?? shift.accentOverride ?? theme.colorScheme.primary;

    return LiquidGlass(
      thickness:
          glass ? LiquidGlassThickness.regular : LiquidGlassThickness.ultraThin,
      radius: radius,
      tint: accent,
      padding: padding,
      shadow: outlined
          ? LiquidGlassShadow.resting
          : LiquidGlassShadow.cinematic,
      stroke: true,
      specular: true,
      child: child,
    );
  }
}
