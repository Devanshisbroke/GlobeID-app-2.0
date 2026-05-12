import 'package:flutter/material.dart';

import '../../app/theme/airport_typography.dart';
import '../../app/theme/app_tokens.dart';
import '../../nexus/nexus_tokens.dart';
import 'magnetic_pressable.dart';

/// InboxPremiumRow — **Nexus-aligned inbox row.**
///
/// Was a tactile multi-layer row with pendulum micro-tilt, magnetic
/// affordance, and a glowing severity rail. After the canonical
/// Travel-OS migration this row is now a flat hairline card with a
/// tone-tinted severity rail, eyebrow + body pairing, and a
/// mono-tracked timestamp. Public API preserved.
class InboxPremiumRow extends StatelessWidget {
  const InboxPremiumRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
    this.timestamp,
    this.unread = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color tone;
  final String? timestamp;
  final bool unread;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MagneticPressable(
      onTap: onTap,
      scale: 0.985,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTokens.space5,
          vertical: 4,
        ),
        padding: const EdgeInsets.all(AppTokens.space3),
        decoration: BoxDecoration(
          color: unread
              ? Color.alphaBlend(
                  tone.withValues(alpha: 0.04),
                  N.surface,
                )
              : N.surface,
          borderRadius: BorderRadius.circular(N.rCard),
          border: Border.all(
            color: unread ? tone.withValues(alpha: 0.22) : N.hairline,
            width: 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3,
              height: 40,
              decoration: BoxDecoration(
                color: unread ? tone : tone.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(AppTokens.radiusFull),
              ),
            ),
            const SizedBox(width: AppTokens.space3),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(N.rChip),
                border: Border.all(
                  color: tone.withValues(alpha: 0.24),
                  width: 0.5,
                ),
              ),
              child: Icon(icon, color: tone, size: 18),
            ),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: N.inkHi,
                      fontSize: 14,
                      fontWeight: unread ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: -0.1,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: N.inkMid,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (timestamp != null) ...[
              const SizedBox(width: AppTokens.space2),
              Text(
                timestamp!.toUpperCase(),
                style: AirportFontStack.caption(context).copyWith(
                  color: N.inkLow,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
