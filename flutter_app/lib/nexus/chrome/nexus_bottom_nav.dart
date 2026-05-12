import 'package:flutter/material.dart';

import '../nexus_motion.dart';
import '../nexus_tokens.dart';
import '../nexus_typography.dart';

class NNavItem {
  const NNavItem({
    required this.label,
    required this.icon,
    required this.path,
  });
  final String label;
  final IconData icon;
  final String path;
}

/// Flat 3-tab bottom nav — Travel OS · Passport · Wallet.
/// Sits on the substrate (no shadow), separated by a top hairline.
class NBottomNav extends StatelessWidget {
  const NBottomNav({
    super.key,
    required this.items,
    required this.activeIndex,
    required this.onTap,
  });

  final List<NNavItem> items;
  final int activeIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: N.bg,
        border: Border(
          top: BorderSide(color: N.hairline, width: N.strokeHair),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(N.s4, N.s3, N.s4, N.s4),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: NPressable(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: N.dQuick,
                  curve: N.ease,
                  padding: const EdgeInsets.symmetric(vertical: N.s2),
                  child: Column(
                    children: [
                      Icon(
                        items[i].icon,
                        size: N.iconMd,
                        color: i == activeIndex ? N.tierGoldHi : N.inkLow,
                      ),
                      const SizedBox(height: N.s1 + 2),
                      Text(
                        items[i].label,
                        style: NType.eyebrow10(
                          color:
                              i == activeIndex ? N.tierGoldHi : N.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
