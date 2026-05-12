import 'package:flutter/material.dart';

import '../app/theme/app_tokens.dart';
import '../nexus/nexus_motion.dart';
import '../nexus/nexus_tokens.dart';
import '../nexus/nexus_typography.dart';

/// Section header — **Nexus-aligned eyebrow + display pairing.**
///
/// Was previously a Material `titleLarge` + `bodySmall` row with an
/// optional `TextButton` action. After the canonical Travel-OS /
/// Wallet migration, this primitive now renders the Lovable pairing
/// — small caps eyebrow (subtitle promoted) + display title + a
/// hairline-bordered trailing chip for the action — across all 34
/// legacy callers without any per-screen edits.
///
/// Behavior:
///
///   - `subtitle` is rendered as a small-caps eyebrow ABOVE the title
///     (Travel-OS hierarchy) when present.
///   - `title` becomes a `display22` line.
///   - `action` (when paired with `onAction`) renders as a hairline
///     champagne chip on the trailing edge.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.onAction,
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final eyebrow = (subtitle ?? '').toUpperCase();
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppTokens.space5,
        vertical: dense ? AppTokens.space2 : AppTokens.space4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow.isNotEmpty) ...[
                  NText.eyebrow11(eyebrow, color: N.inkMid),
                  const SizedBox(height: N.s1),
                ],
                Text(
                  title,
                  style: dense
                      ? NType.title18(color: N.inkHi)
                      : NType.title22(color: N.inkHi),
                ),
              ],
            ),
          ),
          if (action != null && onAction != null) ...[
            const SizedBox(width: N.s3),
            NPressable(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: N.s3,
                  vertical: N.s2,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(N.rChip),
                  border: Border.all(
                    color: N.tierGold.withValues(alpha: 0.36),
                    width: N.strokeHair,
                  ),
                ),
                child: NText.eyebrow11(
                  action!,
                  color: N.tierGoldHi,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
