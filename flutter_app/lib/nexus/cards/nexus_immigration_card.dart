import 'package:flutter/material.dart';

import '../nexus_materials.dart';
import '../nexus_tokens.dart';
import '../nexus_typography.dart';

class NImmigrationItem {
  const NImmigrationItem({
    required this.label,
    required this.state,
  });
  final String label;

  /// `'done'` / `'pending'` / `'active'`
  final String state;
}

class NImmigrationCard extends StatelessWidget {
  const NImmigrationCard({
    super.key,
    required this.percent,
    required this.items,
  });

  final double percent;
  final List<NImmigrationItem> items;

  Color _stateColor(String s) {
    switch (s) {
      case 'done':
        return N.success;
      case 'active':
        return N.tierGoldHi;
      default:
        return N.inkLow;
    }
  }

  IconData _stateIcon(String s) {
    switch (s) {
      case 'done':
        return Icons.check_circle_outline_rounded;
      case 'active':
        return Icons.adjust_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NText.eyebrow11('Immigration · Readiness'),
              const Spacer(),
              Text(
                '${(percent * 100).round()}%',
                style: NType.title22(color: N.inkHi),
              ),
            ],
          ),
          const SizedBox(height: N.s3),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(N.rPill),
            child: Stack(
              children: [
                Container(height: 4, color: N.surfaceInset),
                FractionallySizedBox(
                  widthFactor: percent.clamp(0.0, 1.0),
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          N.tierGold.withValues(alpha: 0.7),
                          N.tierGoldHi,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: N.s4),
          for (final it in items) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: N.s1 + 2),
              child: Row(
                children: [
                  Icon(
                    _stateIcon(it.state),
                    size: 14,
                    color: _stateColor(it.state),
                  ),
                  const SizedBox(width: N.s3),
                  Expanded(
                    child: NText.body13(it.label, color: N.ink),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
