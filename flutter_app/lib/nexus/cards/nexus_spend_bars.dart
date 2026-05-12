import 'package:flutter/material.dart';

import '../nexus_materials.dart';
import '../nexus_tokens.dart';
import '../nexus_typography.dart';

class NSpendCategory {
  const NSpendCategory({
    required this.label,
    required this.percent,
    required this.tone,
  });
  final String label;
  final double percent;
  final Color tone;
}

class NSpendBars extends StatelessWidget {
  const NSpendBars({
    super.key,
    required this.title,
    required this.subtitle,
    required this.total,
    required this.delta,
    required this.categories,
  });

  final String title;
  final String subtitle;
  final String total;
  final String delta;
  final List<NSpendCategory> categories;

  @override
  Widget build(BuildContext context) {
    return NPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NText.eyebrow11(title),
                    const SizedBox(height: N.s1),
                    NText.body12(subtitle, color: N.inkLow),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(total, style: NType.display28(color: N.inkHi)),
                  NText.body12(delta, color: N.success),
                ],
              ),
            ],
          ),
          const SizedBox(height: N.s5),
          // The bar
          ClipRRect(
            borderRadius: BorderRadius.circular(N.rPill),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  for (final c in categories)
                    Expanded(
                      flex: (c.percent * 100).round(),
                      child: Container(
                        margin: const EdgeInsets.only(right: 1.5),
                        color: c.tone,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: N.s4),
          // Legend
          Wrap(
            spacing: N.s4,
            runSpacing: N.s2,
            children: [
              for (final c in categories)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.tone,
                      ),
                    ),
                    const SizedBox(width: N.s2),
                    NText.eyebrow11(c.label),
                    const SizedBox(width: N.s2),
                    NText.mono12(
                      '${(c.percent * 100).round()}%',
                      color: N.inkLow,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
