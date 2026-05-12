import 'package:flutter/material.dart';

import '../nexus_tokens.dart';
import 'nexus_chip.dart';

/// Pipeline strip — `PLAN · PACK · CHECK-IN · SECURITY · LOUNGE · BOARD · LAND`.
/// The current stage gets the active variant; everything before is success;
/// everything after is muted.
class NPipeline extends StatelessWidget {
  const NPipeline({
    super.key,
    required this.stages,
    required this.activeIndex,
  });

  final List<String> stages;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (_, i) {
          final variant = i < activeIndex
              ? NChipVariant.success
              : i == activeIndex
                  ? NChipVariant.active
                  : NChipVariant.muted;
          return NChip(
            label: stages[i],
            variant: variant,
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: N.s2),
        itemCount: stages.length,
      ),
    );
  }
}
