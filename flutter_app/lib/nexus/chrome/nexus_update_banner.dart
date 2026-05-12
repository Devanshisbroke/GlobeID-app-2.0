import 'package:flutter/material.dart';

import '../nexus_motion.dart';
import '../nexus_tokens.dart';
import '../nexus_typography.dart';

/// Pinned-top update banner — "Gate change · B32 → B14" with
/// Dismiss / Details actions. Restrained warning tone.
class NUpdateBanner extends StatelessWidget {
  const NUpdateBanner({
    super.key,
    required this.eyebrow,
    required this.message,
    this.onDetails,
    this.onDismiss,
    this.tone = N.warning,
  });

  final String eyebrow;
  final String message;
  final VoidCallback? onDetails;
  final VoidCallback? onDismiss;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: N.s4,
        vertical: N.s3,
      ),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(N.rCard),
        border: Border.all(
          color: tone.withValues(alpha: 0.32),
          width: N.strokeHair,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: N.s3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tone,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NText.eyebrow10(eyebrow, color: tone),
                const SizedBox(height: N.s1),
                NText.body13(message, color: N.ink),
              ],
            ),
          ),
          if (onDismiss != null)
            NPressable(
              onTap: onDismiss,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: N.s2,
                  vertical: N.s2,
                ),
                child: NText.eyebrow11('Dismiss', color: N.inkLow),
              ),
            ),
          if (onDetails != null) ...[
            const SizedBox(width: N.s1),
            NPressable(
              onTap: onDetails,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: N.s3,
                  vertical: N.s2,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(N.rChip),
                  border: Border.all(
                    color: tone.withValues(alpha: 0.40),
                    width: N.strokeHair,
                  ),
                ),
                child: NText.eyebrow11('Details', color: tone),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
