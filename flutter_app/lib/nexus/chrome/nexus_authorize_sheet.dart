import 'package:flutter/material.dart';

import '../nexus_haptics.dart';
import '../nexus_motion.dart';
import '../nexus_tokens.dart';
import '../nexus_typography.dart';

/// Bottom authorize sheet — "Hold to pay · Face ID" with factor count
/// and a primary Authorize CTA.
class NAuthorizeSheet extends StatelessWidget {
  const NAuthorizeSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onAuthorize,
    this.icon = Icons.face_retouching_natural_rounded,
  });

  final String title;
  final String subtitle;
  final VoidCallback onAuthorize;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(N.s4, N.s4, N.s4, N.s5),
      padding: const EdgeInsets.fromLTRB(N.s5, N.s4, N.s2, N.s4),
      decoration: BoxDecoration(
        color: N.surfaceRaised,
        borderRadius: BorderRadius.circular(N.rCardLg),
        border: Border.all(color: N.hairline, width: N.strokeHair),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: N.tierGold.withValues(alpha: 0.10),
              border: Border.all(
                color: N.tierGold.withValues(alpha: 0.45),
                width: N.strokeHair,
              ),
            ),
            child: Icon(icon, color: N.tierGoldHi, size: N.iconMd),
          ),
          const SizedBox(width: N.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: NType.title16(color: N.ink)),
                const SizedBox(height: N.s1),
                NText.body12(subtitle, color: N.inkLow),
              ],
            ),
          ),
          NPressable(
            onTap: () {
              NHaptics.confirm();
              onAuthorize();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: N.s5,
                vertical: N.s3,
              ),
              decoration: BoxDecoration(
                color: N.tierGold,
                borderRadius: BorderRadius.circular(N.rPill),
              ),
              child: Text(
                'Authorize',
                style: NType.title16(color: N.bg).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
