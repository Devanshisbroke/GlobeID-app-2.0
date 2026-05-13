import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../app/theme/app_tokens.dart';
import '../nexus/nexus_tokens.dart';
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
    final accent = tone ?? N.tierGold;
    return Pressable(
      scale: 0.96,
      semanticLabel: eyebrow != null ? '$eyebrow, $label' : label,
      semanticHint: 'recommended action',
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
          borderRadius: BorderRadius.circular(N.rChip),
          color: N.surface,
          border: Border.all(
            color: accent.withValues(alpha: 0.34),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.10),
                border: Border.all(
                  color: accent.withValues(alpha: 0.30),
                  width: 0.5,
                ),
              ),
              child: Icon(icon, size: 12, color: accent),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eyebrow != null)
                  Text(
                    eyebrow!.toUpperCase(),
                    style: TextStyle(
                      color: accent.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                      letterSpacing: 1.2,
                    ),
                  ),
                Text(
                  label,
                  style: TextStyle(
                    color: N.inkHi,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded,
                size: 14, color: accent.withValues(alpha: 0.6)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: N.tierGold,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                fontSize: 10,
                color: N.inkMid,
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
