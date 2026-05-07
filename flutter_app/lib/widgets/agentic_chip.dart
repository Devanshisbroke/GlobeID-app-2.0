import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../app/theme/app_tokens.dart';
import 'pressable.dart';

/// AgenticChip — a single chained recommendation rendered as a
/// glassy pill with leading glyph + concise label + chevron.
///
/// Used by the cross-service orchestration band that appears on
/// detail pages: "Add visa", "Find hotel near gate", "Reserve lounge",
/// "Pre-order food", etc.
///
/// Tap pushes [route] (or invokes [onTap]) and sends a haptic.
class AgenticChip extends StatelessWidget {
  const AgenticChip({
    super.key,
    required this.label,
    required this.icon,
    this.tone,
    this.route,
    this.onTap,
    this.eyebrow,
  });

  final String label;
  final IconData icon;
  final Color? tone;
  final String? route;
  final VoidCallback? onTap;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = tone ?? theme.colorScheme.primary;
    return Pressable(
      scale: 0.95,
      onTap: () {
        HapticFeedback.lightImpact();
        if (onTap != null) {
          onTap!();
        } else if (route != null) {
          GoRouter.of(context).push(route!);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space3, vertical: AppTokens.space2 + 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          color: accent.withValues(alpha: isDark ? 0.16 : 0.10),
          border: Border.all(color: accent.withValues(alpha: 0.32)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.22),
              ),
              child: Icon(icon, size: 14, color: accent),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eyebrow != null)
                  Text(
                    eyebrow!.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accent.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                      letterSpacing: 1.0,
                    ),
                  ),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 11, color: accent.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

/// AgenticBand — horizontally scrolling cluster of [AgenticChip]s
/// rendered with a soft "AGENTIC" eyebrow above. Used at the
/// bottom of detail sheets to chain into the next service.
class AgenticBand extends StatelessWidget {
  const AgenticBand({
    super.key,
    required this.title,
    required this.chips,
  });

  final String title;
  final List<AgenticChip> chips;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              title.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space2 + 2),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Row(
            children: [
              for (final c in chips) ...[
                c,
                const SizedBox(width: AppTokens.space2),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
