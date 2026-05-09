import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/app_tokens.dart';
import '../../app/theme/emotional_palette.dart';

/// A morphing surface that adapts its tint, elevation, and shape to
/// the surrounding emotional context.
///
/// On a focus-mode home, it renders flat and quiet. On a celebration
/// screen, it warms with gold and lifts. On a stress / urgent state
/// (gate change, missed connection) it cools and tightens.
///
/// Built on the existing [EmotionalContext] enum — every screen can
/// inject its own context, including time-of-day stage flowing in
/// from `AmbientLightingLayer`.
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
    final isDark = theme.brightness == Brightness.dark;
    final glassExt = theme.extension<GlassExtension>();
    final reduce = (glassExt?.reduceTransparency ?? false) ||
        MediaQuery.of(build).disableAnimations;
    final allowGlass = glass && !reduce;
    final shift = context == null
        ? const EmotionalShift()
        : EmotionalPalette.shiftFor(context!);

    final base = tint ??
        (isDark ? AppTokens.cardDark : AppTokens.cardLight)
            .withValues(alpha: allowGlass ? 0.55 : 0.94);

    final accent = shift.accentOverride ?? theme.colorScheme.primary;
    final radiusObj = BorderRadius.circular(radius);

    final body = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            base,
            Color.lerp(base, accent, 0.06 + shift.glowIntensity * 0.18)!,
          ],
        ),
        borderRadius: radiusObj,
        border: Border.all(
          color: outlined
              ? accent.withValues(alpha: 0.35)
              : (isDark ? AppTokens.borderDark : AppTokens.borderLight),
          width: outlined ? 0.8 : 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.05 + shift.glowIntensity * 0.10),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    final clipped = ClipRRect(
      borderRadius: radiusObj,
      child: Stack(
        children: [
          Positioned.fill(child: body),
          // Sheen that biases toward the accent
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.white.withValues(alpha: isDark ? 0.06 : 0.34),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (!allowGlass) return clipped;
    return ClipRRect(
      borderRadius: radiusObj,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: clipped,
      ),
    );
  }
}
