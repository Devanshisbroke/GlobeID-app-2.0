import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/pressable.dart';
import '../live/live_primitives.dart';

/// `CopilotSuggestionStrip` — the GlobeID Copilot's hero recommendation
/// card. Renders one card, one CTA, one clear instruction.
///
/// Composes existing GlobeID primitives only:
///
///   • mono-cap eyebrow `COPILOT · NOW` painted in champagne gold
///   • OLED `Os2.floor1` substrate with a gold-hairline frame
///   • optional `BreathingHalo` rim that breathes faster as the
///     suggestion becomes more urgent
///   • the single `cta` rendered with the same shape language used by
///     `LiveCta` (mono-cap label, gold fill, 14 pt corners)
///   • optional countdown chip on the right edge for time-sensitive
///     plays ("BOARDING IN 18M")
///
/// Designed to be dropped on Home, the Travel hub, or the top of any
/// world's `Pulse` strip. Pure layout — no business logic. The
/// caller wires the [onCta] callback and any deep link.
///
/// Brand DNA: gold `#D4AF37 → #E9C75D`, OLED black, hairline frames,
/// mono-cap chrome on every label. No Material flat fills.
class CopilotSuggestionStrip extends StatelessWidget {
  const CopilotSuggestionStrip({
    super.key,
    required this.headline,
    required this.subhead,
    required this.ctaLabel,
    this.eyebrow = 'COPILOT · NOW',
    this.glyph,
    this.tone,
    this.urgency = CopilotUrgency.normal,
    this.impactBadge,
    this.countdown,
    this.onCta,
    this.onLongPress,
    this.padding = const EdgeInsets.all(Os2.space5),
    this.semanticHint = 'opens the recommended action',
  });

  /// Hero instruction — terse, one short sentence ("Convert €500 to
  /// USD now"). Rendered with [Os2Text.title].
  final String headline;

  /// Body — one short sentence explaining the recommendation
  /// ("EUR/USD spiked 0.7% in the last 30 minutes"). Rendered with
  /// [Os2Text.body].
  final String subhead;

  /// Label for the single CTA button (`CONVERT NOW`, `RENEW`, etc.).
  /// Rendered in mono-cap. Keep ≤ 14 chars for the layout to hold.
  final String ctaLabel;

  /// Eyebrow line painted above [headline] in mono-cap champagne.
  /// Defaults to `COPILOT · NOW` so every callsite reads as the same
  /// system speaking.
  final String eyebrow;

  /// Leading glyph rendered in a circular gold-tinted badge to the
  /// left of the headline. Defaults to [Icons.auto_awesome_rounded]
  /// when null.
  final IconData? glyph;

  /// Override the champagne tone for one-off surfaces. Falls back to
  /// [Os2.pulseTone] (the Copilot's canonical voice colour).
  final Color? tone;

  /// Urgency of the suggestion — drives breathing cadence on the halo
  /// rim and (when [CopilotUrgency.critical]) shifts the eyebrow tone
  /// to [Os2.signalCritical].
  final CopilotUrgency urgency;

  /// Optional impact chip rendered between [subhead] and the CTA
  /// (e.g. `SAVES $14`). Rendered in mono-cap inside a pill with the
  /// surface's [tone] at 18 % alpha.
  final String? impactBadge;

  /// Optional countdown rendered on the right edge above the CTA
  /// (e.g. `18M`). Use this when the recommendation has a hard
  /// expiry. Rendered in mono-cap caps.
  final String? countdown;

  /// Called when the CTA is tapped. The tap fires a
  /// [HapticFeedback.lightImpact] before the callback runs.
  final VoidCallback? onCta;

  /// Optional long-press handler for "tell me more" affordances.
  final VoidCallback? onLongPress;

  /// Outer padding around the inner content. Defaults to a 20 pt
  /// inset so the card breathes inside any parent.
  final EdgeInsets padding;

  /// Accessibility hint announced after the headline / subhead label
  /// when a screen reader focuses the CTA.
  final String semanticHint;

  @override
  Widget build(BuildContext context) {
    final accent = tone ?? Os2.pulseTone;
    final eyebrowTone = urgency == CopilotUrgency.critical
        ? Os2.signalCritical
        : accent;

    final Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(
          color: Os2.goldHairline.withValues(
            alpha: urgency == CopilotUrgency.critical ? 0.62 : 0.42,
          ),
          width: Os2.strokeFine,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Glyph(icon: glyph ?? Icons.auto_awesome_rounded, tone: accent),
          const SizedBox(width: Os2.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Os2Text.monoCap(
                  eyebrow,
                  color: eyebrowTone,
                  size: Os2.textXs,
                ),
                const SizedBox(height: Os2.space2),
                Os2Text.title(
                  headline,
                  color: Os2.inkBright,
                  size: Os2.textXl,
                  maxLines: 2,
                ),
                const SizedBox(height: Os2.space1 + 2),
                Os2Text.body(
                  subhead,
                  color: Os2.inkMid,
                  size: Os2.textSm,
                  maxLines: 2,
                ),
                if (impactBadge != null) ...[
                  const SizedBox(height: Os2.space3),
                  _ImpactPill(label: impactBadge!, tone: accent),
                ],
              ],
            ),
          ),
          const SizedBox(width: Os2.space3),
          _CtaColumn(
            ctaLabel: ctaLabel,
            countdown: countdown,
            tone: accent,
            urgent: urgency != CopilotUrgency.normal,
            onTap: onCta,
            onLongPress: onLongPress,
            semanticHint: semanticHint,
          ),
        ],
      ),
    );

    if (urgency == CopilotUrgency.normal) return content;
    return BreathingHalo(
      tone: accent,
      state: urgency.breathing,
      maxAlpha: urgency == CopilotUrgency.critical ? 0.34 : 0.22,
      child: content,
    );
  }
}

/// Urgency ladder for [CopilotSuggestionStrip].
///
///   • [normal]   — no halo, no breathing
///   • [armed]    — slow champagne breathing rim
///   • [active]   — faster amber-leaning breathing rim
///   • [critical] — fast red breathing rim + red eyebrow tone
enum CopilotUrgency {
  normal,
  armed,
  active,
  critical;

  LiveSurfaceState get breathing => switch (this) {
        CopilotUrgency.normal => LiveSurfaceState.idle,
        CopilotUrgency.armed => LiveSurfaceState.armed,
        CopilotUrgency.active => LiveSurfaceState.active,
        CopilotUrgency.critical => LiveSurfaceState.committed,
      };
}

class _Glyph extends StatelessWidget {
  const _Glyph({required this.icon, required this.tone});

  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tone.withValues(alpha: 0.10),
        border: Border.all(
          color: tone.withValues(alpha: 0.40),
          width: Os2.strokeFine,
        ),
      ),
      child: Icon(icon, color: tone, size: 18),
    );
  }
}

class _ImpactPill extends StatelessWidget {
  const _ImpactPill({required this.label, required this.tone});

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Os2.space2 + 2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Os2.rChip),
        border: Border.all(
          color: tone.withValues(alpha: 0.34),
          width: Os2.strokeFine,
        ),
      ),
      child: Os2Text.monoCap(
        label,
        color: tone,
        size: Os2.textTiny,
      ),
    );
  }
}

class _CtaColumn extends StatelessWidget {
  const _CtaColumn({
    required this.ctaLabel,
    required this.tone,
    required this.onTap,
    required this.semanticHint,
    this.countdown,
    this.urgent = false,
    this.onLongPress,
  });

  final String ctaLabel;
  final String? countdown;
  final Color tone;
  final bool urgent;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String semanticHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (countdown != null) ...[
          Os2Text.monoCap(
            countdown!,
            color: urgent ? Os2.signalCritical : tone,
            size: Os2.textXs,
          ),
          const SizedBox(height: Os2.space1 + 2),
        ],
        Pressable(
          scale: 0.96,
          semanticLabel: ctaLabel,
          semanticHint: semanticHint,
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onTap!();
                },
          onLongPress: onLongPress,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Os2.space4,
              vertical: Os2.space2 + 2,
            ),
            decoration: BoxDecoration(
              gradient: Os2.foilGoldHero,
              borderRadius: BorderRadius.circular(Os2.rChip),
              boxShadow: [
                BoxShadow(
                  color: Os2.goldDeep.withValues(alpha: 0.34),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Os2Text.monoCap(
              ctaLabel,
              color: Os2.canvas,
              size: Os2.textXs,
            ),
          ),
        ),
      ],
    );
  }
}
