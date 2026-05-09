import 'dart:ui';

import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../app/theme/app_tokens.dart';

/// Frosted-glass card that respects the user's reduce-transparency setting.
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
    // `GlassExtension.of` returns a registered extension or a neutral
    // fallback — never null. Pre-Phase-1 this line used `()!` and
    // crashed the entire page if any sub-tree was rendered without the
    // extension registered.
    final glass = GlassExtension.of(context);
    final reduce = glass.reduceTransparency;
    final radiusObj = BorderRadius.circular(radius);
    final base = tint ?? glass.surface;

    final body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: reduce ? base.withValues(alpha: 0.96) : base,
        borderRadius: radiusObj,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );

    if (reduce) {
      return ClipRRect(borderRadius: radiusObj, child: body);
    }

    return ClipRRect(
      borderRadius: radiusObj,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: body,
      ),
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
