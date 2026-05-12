import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme/app_tokens.dart';
import '../nexus/nexus_tokens.dart';
import 'pressable.dart';

/// Flagship-grade primary CTA — **Nexus-aligned champagne pill.**
///
/// Previously a multi-layer gradient + sheen + glow surface. After the
/// canonical Travel-OS / Wallet migration, this primitive now renders
/// the Lovable champagne CTA across all 25 callers in the legacy
/// feature tree:
///
///   - flat champagne fill (`N.tierGold`) with a subtle 0.5pt
///     `tierGoldHi` hairline
///   - tabular-feeling sans label (550 weight, +0.2 tracking) on
///     pitch-black ink
///   - leading icon at high contrast (no white-on-white sheen)
///   - press scale 0.965 + `selectionClick` haptic
///   - rounded-full pill shape (matches Wallet Send / Receive refs)
///   - no shadow, no glow, no specular — depth is implied by
///     contrast, not lighting
///
/// `gradient` is still accepted for legacy callers that override the
/// fill (e.g. wallet tone buttons), but the multi-layer blur / sheen
/// stack is gone. Public API preserved.
class CinematicButton extends StatelessWidget {
  const CinematicButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.gradient,
    this.expand = true,
    this.compact = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final bool expand;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(N.rPill);
    final padH = compact ? N.s4 : N.s6;
    final padV = compact ? 10.0 : 14.0;

    // Default fill is the champagne pill — Lovable Wallet Send / Receive
    // language. Legacy callers can still override with a gradient.
    final fillDecoration = gradient != null
        ? BoxDecoration(
            gradient: gradient,
            borderRadius: radius,
            border: Border.all(
              color: N.hairlineHi,
              width: N.strokeHair,
            ),
          )
        : BoxDecoration(
            color: N.tierGold,
            borderRadius: radius,
            border: Border.all(
              color: N.tierGoldHi.withValues(alpha: 0.72),
              width: N.strokeHair,
            ),
          );

    final iconColor = gradient != null ? Colors.white : N.bg;
    final textColor = gradient != null ? Colors.white : N.bg;

    final body = Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: fillDecoration,
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor, size: compact ? 16 : 18),
            SizedBox(width: compact ? 6 : N.s2),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                fontSize: compact ? 13 : 14,
                height: 1.1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    return Pressable(
      scale: 0.965,
      onTap: onPressed,
      haptic: true,
      child: SizedBox(
        width: expand ? double.infinity : null,
        child: body,
      ),
    );
  }
}

/// Glass-only secondary button — **Nexus-aligned hairline pill.**
///
/// Previously a backdrop-blur capsule with a tinted accent border.
/// Now: flat `N.surface` pill with a 0.5pt `N.hairline` border and
/// an `inkHi` label. Sits next to [CinematicButton] in hero footers
/// (CTA + dismiss). No blur, no shadow — pure hairline language.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.97,
      onTap: () {
        HapticFeedback.selectionClick();
        onPressed?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space5,
          vertical: AppTokens.space3,
        ),
        decoration: BoxDecoration(
          color: N.surface,
          borderRadius: BorderRadius.circular(N.rPill),
          border: Border.all(
            color: N.hairline,
            width: N.strokeHair,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: N.inkHi),
              const SizedBox(width: AppTokens.space2),
            ],
            Text(
              label,
              style: const TextStyle(
                color: N.inkHi,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
