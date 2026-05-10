import 'package:flutter/material.dart';

import '../app/theme/app_tokens.dart';
import 'bible/liquid_glass.dart';

/// Frosted-glass card.
///
/// Now a thin wrapper over [LiquidGlass] with `thickness: regular`
/// so every glass surface in the app shares the same Apple-grade
/// material pipeline (saturate-then-blur, specular edge, hairline
/// stroke, cinematic shadow, continuous-curve squircle corners,
/// reduce-transparency fallback). The original `GlassSurface` API
/// is preserved 1:1 so existing callers continue to work without
/// any source changes.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTokens.space5),
    this.radius = AppTokens.radiusXl,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      thickness: LiquidGlassThickness.regular,
      radius: radius,
      tint: tint,
      padding: padding,
      shadow: LiquidGlassShadow.cinematic,
      stroke: true,
      specular: true,
      child: child,
    );
  }
}

/// Lightweight pill chip.
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    this.icon,
    this.tone,
  });

  final String label;
  final IconData? icon;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = tone ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space3,
        vertical: AppTokens.space1 + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.32), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
