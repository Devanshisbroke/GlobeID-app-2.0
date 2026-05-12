import 'package:flutter/material.dart';

import '../nexus_motion.dart';
import '../nexus_tokens.dart';
import '../nexus_typography.dart';

class NQuickAction {
  const NQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accented = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool accented;
}

/// 4-up quick action row — Tap NFC · Scan Pay · Convert · Transfer.
/// Equally weighted, single hairline border, icon + small caps label.
class NQuickActionsRow extends StatelessWidget {
  const NQuickActionsRow({
    super.key,
    required this.actions,
  });

  final List<NQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          Expanded(child: _QuickActionTile(action: actions[i])),
          if (i != actions.length - 1) const SizedBox(width: N.s2),
        ],
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});
  final NQuickAction action;

  @override
  Widget build(BuildContext context) {
    final bg = action.accented
        ? N.tierGold.withValues(alpha: 0.10)
        : N.surface;
    final border = action.accented
        ? N.tierGold.withValues(alpha: 0.45)
        : N.hairline;
    final fg = action.accented ? N.tierGoldHi : N.ink;
    return NPressable(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: N.s2,
          vertical: N.s4,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(N.rCard),
          border: Border.all(color: border, width: N.strokeHair),
        ),
        child: Column(
          children: [
            Icon(action.icon, size: N.iconLg, color: fg),
            const SizedBox(height: N.s2),
            NText.eyebrow10(action.label, color: fg.withValues(alpha: 0.92)),
          ],
        ),
      ),
    );
  }
}
