import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../bible_tokens.dart';
import '../bible_typography.dart';
import 'bible_pressable.dart';

/// GlobeID — **CinematicButton** (§10).
///
/// The primary CTA. Gradient, icon, label, optional shimmer.
/// Used for hero actions only — there is **one** of these per screen
/// or zero. Multiple cinematic buttons on a single surface is a smell.
class BibleCinematicButton extends StatelessWidget {
  const BibleCinematicButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = B.jetCyan,
    this.dense = false,
    this.shimmer = true,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color tone;
  final bool dense;
  final bool shimmer;

  @override
  Widget build(BuildContext context) {
    final h = dense ? 44.0 : 56.0;
    return BiblePressable(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        height: h,
        padding: EdgeInsets.symmetric(
          horizontal: dense ? B.space4 : B.space5,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(h / 2),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tone.withValues(alpha: 0.92),
              tone.withValues(alpha: 0.62),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: tone.withValues(alpha: 0.30),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: B.inkOnDark, size: dense ? 16 : 18),
              const SizedBox(width: B.space2),
            ],
            BText.title(
              label,
              size: dense ? 14.5 : 16,
              color: B.inkOnDark,
            ),
          ],
        ),
      ),
    );
  }
}

/// GlobeID — **MagneticButton** (§10).
///
/// Secondary CTA with subtle attraction-to-finger effect.
/// Same shape as cinematic but glass surface + hairline border.
class BibleMagneticButton extends StatelessWidget {
  const BibleMagneticButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = B.foilGold,
    this.dense = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color tone;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final h = dense ? 42.0 : 50.0;
    return BiblePressable(
      onTap: () {
        HapticFeedback.selectionClick();
        onPressed();
      },
      child: Container(
        height: h,
        padding: EdgeInsets.symmetric(
          horizontal: dense ? B.space4 : B.space5,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(h / 2),
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(
            color: tone.withValues(alpha: 0.36),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: tone, size: dense ? 16 : 18),
              const SizedBox(width: B.space2),
            ],
            BText.title(
              label,
              size: dense ? 14 : 15,
              color: B.inkOnDarkHigh,
            ),
          ],
        ),
      ),
    );
  }
}

/// Quiet ghost CTA — minimal label + chevron, dense rows.
class BibleGhostButton extends StatelessWidget {
  const BibleGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = B.inkOnDarkMid,
  });
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return BiblePressable(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: B.space3,
          vertical: B.space2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BText.monoCap(label, color: tone),
            const SizedBox(width: B.space1),
            Icon(icon ?? Icons.arrow_forward_ios_rounded,
                size: 10, color: tone),
          ],
        ),
      ),
    );
  }
}
