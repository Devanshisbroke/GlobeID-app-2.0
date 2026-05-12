import 'package:flutter/material.dart';

import '../chrome/nexus_chip.dart';
import '../nexus_materials.dart';
import '../nexus_tokens.dart';
import '../nexus_typography.dart';

/// Live navigation card — `12 min · East Concourse · Level 2 → Gate B14`.
class NNavigationCard extends StatelessWidget {
  const NNavigationCard({
    super.key,
    required this.minutes,
    required this.direction,
    required this.destination,
  });

  final int minutes;
  final String direction;
  final String destination;

  @override
  Widget build(BuildContext context) {
    return NPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: N.steel.withValues(alpha: 0.10),
              border: Border.all(
                color: N.steel.withValues(alpha: 0.40),
                width: N.strokeHair,
              ),
            ),
            child: const Icon(
              Icons.navigation_rounded,
              size: 22,
              color: N.steelHi,
            ),
          ),
          const SizedBox(width: N.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    NText.eyebrow10('navigation', color: N.inkLow),
                    const SizedBox(width: N.s2),
                    const NChip(
                      label: 'Live',
                      variant: NChipVariant.success,
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: N.s2),
                Text(
                  '$minutes min',
                  style: NType.display28(color: N.inkHi),
                ),
                const SizedBox(height: N.s1),
                NText.body13(
                  '$direction\nto $destination',
                  color: N.inkMid,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
