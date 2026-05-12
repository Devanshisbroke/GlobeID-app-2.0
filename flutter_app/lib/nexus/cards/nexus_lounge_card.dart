import 'package:flutter/material.dart';

import '../chrome/nexus_chip.dart';
import '../nexus_materials.dart';
import '../nexus_tokens.dart';
import '../nexus_typography.dart';

class NLoungeCard extends StatelessWidget {
  const NLoungeCard({
    super.key,
    required this.name,
    required this.openUntil,
    required this.eligibility,
  });

  final String name;
  final String openUntil;
  final String eligibility;

  @override
  Widget build(BuildContext context) {
    return NPanel(
      tone: N.tierGold,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: N.tierGold.withValues(alpha: 0.10),
              border: Border.all(
                color: N.tierGold.withValues(alpha: 0.50),
                width: N.strokeHair,
              ),
            ),
            child: const Icon(
              Icons.weekend_rounded,
              size: 22,
              color: N.tierGoldHi,
            ),
          ),
          const SizedBox(width: N.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NText.eyebrow10('lounge', color: N.inkLow),
                const SizedBox(height: N.s1),
                Text(name, style: NType.title18(color: N.inkHi)),
                const SizedBox(height: N.s2),
                NText.body13('Open until $openUntil', color: N.inkMid),
                const SizedBox(height: N.s3),
                NChip(
                  label: eligibility,
                  variant: NChipVariant.active,
                  dense: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
