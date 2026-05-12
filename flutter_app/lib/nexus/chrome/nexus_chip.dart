import 'package:flutter/material.dart';

import '../nexus_motion.dart';
import '../nexus_tokens.dart';
import '../nexus_typography.dart';

enum NChipVariant { muted, active, warn, success }

/// Standard small chip — used for pipeline states, tier marks, status.
class NChip extends StatelessWidget {
  const NChip({
    super.key,
    required this.label,
    this.variant = NChipVariant.muted,
    this.onTap,
    this.icon,
    this.dense = false,
  });

  final String label;
  final NChipVariant variant;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool dense;

  ({Color bg, Color border, Color fg}) _palette() {
    switch (variant) {
      case NChipVariant.muted:
        return (
          bg: N.surface,
          border: N.hairline,
          fg: N.inkMid,
        );
      case NChipVariant.active:
        return (
          bg: N.tierGold.withValues(alpha: 0.10),
          border: N.tierGold.withValues(alpha: 0.50),
          fg: N.tierGoldHi,
        );
      case NChipVariant.warn:
        return (
          bg: N.warning.withValues(alpha: 0.08),
          border: N.warning.withValues(alpha: 0.40),
          fg: N.warning,
        );
      case NChipVariant.success:
        return (
          bg: N.success.withValues(alpha: 0.08),
          border: N.success.withValues(alpha: 0.40),
          fg: N.success,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette();
    final inner = Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? N.s3 : N.s4,
        vertical: dense ? N.s1 + 1 : N.s2,
      ),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(N.rChip),
        border: Border.all(color: p.border, width: N.strokeHair),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 11 : 13, color: p.fg),
            const SizedBox(width: N.s2),
          ],
          NText.eyebrow11(label, color: p.fg),
        ],
      ),
    );
    if (onTap == null) return inner;
    return NPressable(onTap: onTap, child: inner);
  }
}
