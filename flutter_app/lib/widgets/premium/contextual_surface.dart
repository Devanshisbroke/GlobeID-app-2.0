import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../app/theme/emotional_palette.dart';
import '../../nexus/nexus_tokens.dart';

/// A morphing surface that adapts its tint to the surrounding
/// emotional context — **Nexus-aligned hairline panel.**
///
/// Was a LiquidGlass wrapper with saturate-then-blur + specular edge
/// + cinematic shadow. After the canonical Travel-OS / Wallet
/// migration this primitive renders the flat hairline language:
///
///   - flat `N.surface` (with optional tone wash at 5%)
///   - 0.5pt `N.hairline` border (or tone-tinted hairline when
///     `tint` is provided)
///   - generous radius (defaults to `N.rCardLg`)
///   - **no shadow, no specular, no blur**
///
/// The emotional accent (gold/cool/warm depending on
/// [EmotionalContext]) is still forwarded but only as a low-alpha
/// colour bleed. Public API preserved 1:1.
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
    final shift = context == null
        ? const EmotionalShift()
        : EmotionalPalette.shiftFor(context!);

    final Color? accent = tint ?? shift.accentOverride;

    final Color background = accent == null
        ? N.surface
        : Color.alphaBlend(
            accent.withValues(alpha: 0.05),
            N.surface,
          );

    final Color border = accent == null
        ? N.hairline
        : accent.withValues(alpha: 0.26);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: border,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
