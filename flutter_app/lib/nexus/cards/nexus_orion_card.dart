import 'package:flutter/material.dart';

import '../chrome/nexus_chip.dart';
import '../nexus_materials.dart';
import '../nexus_motion.dart';
import '../nexus_tokens.dart';
import '../nexus_typography.dart';

/// Orion AI concierge card — single-paragraph status with a subtle
/// breathing dot to feel "live".
class NOrionCard extends StatelessWidget {
  const NOrionCard({
    super.key,
    required this.message,
  });
  final String message;

  @override
  Widget build(BuildContext context) {
    return NPanel(
      tone: N.steel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NBreath(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: N.steelHi,
                  ),
                ),
              ),
              const SizedBox(width: N.s2),
              NText.eyebrow11('AI · Orion', color: N.steelHi),
              const Spacer(),
              const NChip(
                label: 'Active',
                variant: NChipVariant.muted,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: N.s3),
          NText.body14(message, color: N.ink),
        ],
      ),
    );
  }
}
