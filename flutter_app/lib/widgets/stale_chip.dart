import 'package:flutter/material.dart';

import '../data/offline/stale_text.dart';
import '../os2/os2_tokens.dart';
import '../os2/primitives/os2_text.dart';

/// Renders the canonical GlobeID STALE chip — MONO-CAP label,
/// severity-tinted hairline border, dot pip in the same tone.
///
/// Pure presentation, takes only the cached timestamp and the
/// staleness threshold. Hides itself when fresh unless
/// [renderWhenFresh] is true (which is useful in lab screens).
class StaleChip extends StatelessWidget {
  const StaleChip({
    super.key,
    required this.fetchedAt,
    this.threshold = const Duration(minutes: 5),
    this.now,
    this.renderWhenFresh = false,
  });

  final DateTime fetchedAt;
  final Duration threshold;
  final DateTime? now;
  final bool renderWhenFresh;

  @override
  Widget build(BuildContext context) {
    final age = (now ?? DateTime.now()).difference(fetchedAt);
    final severity = staleSeverity(age);
    if (severity == StaleSeverity.fresh && !renderWhenFresh) {
      return const SizedBox.shrink();
    }
    final tone = Color(severity.tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Os2Text.monoCap(
            staleHandle(age),
            color: tone,
            size: Os2.textTiny,
          ),
        ],
      ),
    );
  }
}
