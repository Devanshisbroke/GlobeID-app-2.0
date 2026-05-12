import 'package:flutter/material.dart';

import '../app/theme/app_tokens.dart';
import '../nexus/nexus_tokens.dart';

/// Frosted-glass card — **Nexus-aligned hairline panel.**
///
/// Was a LiquidGlass wrapper with saturate-then-blur, specular edge,
/// cinematic shadow. After the canonical Travel-OS / Wallet migration
/// this primitive is now a flat hairline panel on the OLED substrate
/// — the same language as [PremiumCard], used across all 10 callers.
/// Public API preserved 1:1.
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
    final Color background = tint == null
        ? N.surface
        : Color.alphaBlend(
            tint!.withValues(alpha: 0.05),
            N.surface,
          );

    final Color border = tint == null
        ? N.hairline
        : tint!.withValues(alpha: 0.28);

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

/// Lightweight pill chip — **Nexus-aligned hairline chip.**
///
/// Previously alpha-fill + tonal border. Now: 6% tone wash + hairline
/// stroke (matches the canonical Nexus chip language).
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
    final color = tone ?? N.tierGold;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space3,
        vertical: AppTokens.space1 + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(N.rChip),
        border: Border.all(
          color: color.withValues(alpha: 0.36),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
