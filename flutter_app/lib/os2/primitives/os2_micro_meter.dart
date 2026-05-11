import 'package:flutter/material.dart';

import '../os2_tokens.dart';
import 'os2_text.dart';

/// OS 2.0 — Micro meter.
///
/// Tiny inline linear gauge: monoCap label · 6-cell segmented bar ·
/// monoCap value. Used inside info chips, dense rows, system status
/// panels. Each segment is a tone-tinted hairline-rimmed square.
class Os2MicroMeter extends StatelessWidget {
  const Os2MicroMeter({
    super.key,
    required this.label,
    required this.value, // 0..1
    this.tone = Os2.travelTone,
    this.trailing,
    this.segments = 6,
    this.dense = false,
  });

  final String label;
  final double value;
  final Color tone;
  final String? trailing;
  final int segments;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final filled = (clamped * segments).round().clamp(0, segments);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Os2Text.monoCap(
          label,
          color: Os2.inkLow,
          size: dense ? 9 : 10,
        ),
        const SizedBox(width: Os2.space2),
        Expanded(
          child: Row(
            children: [
              for (var i = 0; i < segments; i++) ...[
                Expanded(
                  child: Container(
                    height: dense ? 6 : 8,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: i < filled
                          ? tone.withValues(alpha: 0.85)
                          : Os2.floor3,
                      boxShadow: i < filled
                          ? [
                              BoxShadow(
                                color: tone.withValues(alpha: 0.35),
                                blurRadius: 4,
                                spreadRadius: -1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: Os2.space2),
          Os2Text.monoCap(
            trailing!,
            color: tone,
            size: dense ? 9 : 10,
          ),
        ],
      ],
    );
  }
}
