import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme/app_tokens.dart';
import 'pressable.dart';

/// Flagship-grade primary CTA. Layered gradient surface, animated
/// glow, leading icon, optional trailing chevron, integrated haptic.
class CinematicButton extends StatelessWidget {
  const CinematicButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.gradient,
    this.expand = true,
    this.compact = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final bool expand;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final glow = theme.colorScheme.secondary;

    final g = gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [glow, accent],
        );

    final radius = BorderRadius.circular(AppTokens.radiusFull);
    final padH = compact ? AppTokens.space4 : AppTokens.space6;
    final padV = compact ? AppTokens.space2 + 2 : AppTokens.space3 + 2;

    final body = Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        gradient: g,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: compact ? 16 : 18),
            SizedBox(width: compact ? AppTokens.space1 + 2 : AppTokens.space2),
          ],
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                fontSize: compact ? 13 : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    final layered = ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: [
          body,
          // Sheen
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
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

    return Pressable(
      scale: 0.965,
      onTap: onPressed,
      haptic: true,
      child: SizedBox(
        width: expand ? double.infinity : null,
        child: layered,
      ),
    );
  }
}

/// Glass-only secondary button — used next to [CinematicButton] in
/// hero footers (CTA + dismiss).
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Pressable(
      scale: 0.97,
      onTap: () {
        HapticFeedback.selectionClick();
        onPressed?.call();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space5,
              vertical: AppTokens.space3,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppTokens.radiusFull),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.30),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: AppTokens.space2),
                ],
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
