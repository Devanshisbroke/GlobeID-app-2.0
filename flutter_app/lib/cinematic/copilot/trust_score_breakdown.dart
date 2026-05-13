import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/travel_score.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/pressable.dart';
import '../live/live_primitives.dart';
import '../sheets/apple_sheet.dart';

/// `TrustScoreBreakdown` — Copilot-grade explainer surface that
/// reveals **how** the bearer's trust score is composed.
///
/// Apple Wallet shows you a credit score number. GlobeID shows you
/// every factor that built it, in mono-cap, with horizontal weight
/// bars, and a single "improve your score" CTA at the bottom — the
/// surface that turns a number into an explanation.
///
/// Composes existing primitives:
///   • `Os2Text.credential` in `Os2.foilGoldHero` for the hero number
///   • `BreathingHalo` around the tier ring for the "alive" thread
///   • mono-cap chrome on every label and factor row
///   • OLED `Os2.floor1` substrate, gold hairline divider rule
///   • `Pressable` semantic-labeled CTA at the bottom
///
/// Embed inline with [TrustScoreBreakdown] or open as a sheet with
/// [showTrustScoreBreakdownSheet].
class TrustScoreBreakdown extends StatelessWidget {
  const TrustScoreBreakdown({
    super.key,
    required this.score,
    this.padding = const EdgeInsets.fromLTRB(
      Os2.space5,
      Os2.space4,
      Os2.space5,
      Os2.space6,
    ),
    this.onImproveTap,
    this.improveLabel = 'IMPROVE SCORE',
  });

  /// Snapshot of the bearer's trust score to render. Both the hero
  /// number, the tier ring, and the factor rows derive from this
  /// single source.
  final TravelScore score;

  /// Outer padding around the breakdown content. Defaults to a
  /// 20 / 16 / 20 / 24 inset so it sits comfortably inside any sheet
  /// substrate.
  final EdgeInsets padding;

  /// Callback for the bottom CTA. When null the CTA is hidden so
  /// the breakdown can live as a read-only inline explainer.
  final VoidCallback? onImproveTap;

  /// Override the default CTA label ("IMPROVE SCORE").
  final String improveLabel;

  @override
  Widget build(BuildContext context) {
    final tierLabel = _tierLabel(score.tier);
    final tierTone = _tierTone(score.tier);

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─────────────── Hero number + tier ring ───────────────
          _HeroNumber(score: score.score, tierTone: tierTone),
          const SizedBox(height: Os2.space2),
          Center(
            child: Os2Text.monoCap(
              tierLabel,
              color: tierTone,
              size: Os2.textSm,
            ),
          ),
          const SizedBox(height: Os2.space5),
          const _GoldHairlineDivider(),
          const SizedBox(height: Os2.space5),
          // ─────────────── Factor rows ───────────────
          for (final f in score.factors) ...[
            _FactorRow(factor: f, tierTone: tierTone),
            const SizedBox(height: Os2.space4),
          ],
          if (onImproveTap != null) ...[
            const SizedBox(height: Os2.space2),
            _ImproveCta(
              label: improveLabel,
              onTap: onImproveTap!,
            ),
          ],
        ],
      ),
    );
  }

  static String _tierLabel(int tier) {
    switch (tier) {
      case 3:
        return 'TIER · ELITE';
      case 2:
        return 'TIER · GOLD';
      case 1:
        return 'TIER · SILVER';
      default:
        return 'TIER · BRONZE';
    }
  }

  static Color _tierTone(int tier) {
    switch (tier) {
      case 3:
        return Os2.goldDeep;
      case 2:
        return Os2.identityTone;
      case 1:
        return Os2.pulseTone;
      default:
        return Os2.inkMid;
    }
  }
}

/// Open the trust-score breakdown as an Apple-grade sheet. Returns
/// once dismissed. Callsites that prefer an inline embed can use the
/// [TrustScoreBreakdown] widget directly.
Future<void> showTrustScoreBreakdownSheet(
  BuildContext context, {
  required TravelScore score,
  VoidCallback? onImproveTap,
}) {
  return showAppleSheet<void>(
    context: context,
    eyebrow: 'COPILOT · TRUST',
    title: 'Why this score',
    tone: Os2.goldDeep,
    detents: const [0.55, 0.92],
    builder: (controller) {
      return ListView(
        controller: controller,
        padding: EdgeInsets.zero,
        children: [
          TrustScoreBreakdown(
            score: score,
            onImproveTap: onImproveTap == null
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onImproveTap();
                  },
          ),
        ],
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────
// Internals
// ─────────────────────────────────────────────────────────────────

class _HeroNumber extends StatelessWidget {
  const _HeroNumber({required this.score, required this.tierTone});

  final int score;
  final Color tierTone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: BreathingHalo(
        tone: tierTone,
        // Trust score is a settled stat — slow champagne breathing
        // rim, not the urgent armed/active cadence.
        state: LiveSurfaceState.settled,
        maxAlpha: 0.22,
        expand: 24,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Os2.space7,
            vertical: Os2.space5,
          ),
          decoration: BoxDecoration(
            color: Os2.floor1,
            shape: BoxShape.circle,
            border: Border.all(
              color: tierTone.withValues(alpha: 0.34),
              width: Os2.strokeRegular,
            ),
          ),
          child: Os2Text.credential(
            '$score',
            color: Os2.inkBright,
            size: 56,
            gradient: Os2.foilGoldHero,
          ),
        ),
      ),
    );
  }
}

class _GoldHairlineDivider extends StatelessWidget {
  const _GoldHairlineDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Os2.strokeFine,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0x00D4AF37),
            Os2.goldHairline,
            Color(0x00D4AF37),
          ],
        ),
      ),
    );
  }
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({required this.factor, required this.tierTone});

  final TravelScoreFactor factor;
  final Color tierTone;

  @override
  Widget build(BuildContext context) {
    final pct = factor.value.clamp(0.0, 1.0);
    final delta = (factor.weight * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Os2Text.monoCap(
                factor.label.toUpperCase(),
                color: Os2.inkHigh,
                size: Os2.textXs,
              ),
            ),
            const SizedBox(width: Os2.space2),
            Os2Text.monoCap(
              '${delta > 0 ? '+' : ''}$delta',
              color: tierTone,
              size: Os2.textXs,
            ),
          ],
        ),
        const SizedBox(height: Os2.space2),
        _WeightBar(value: pct, tone: tierTone),
        const SizedBox(height: Os2.space1 + 2),
        Os2Text.body(
          _factorHint(factor),
          color: Os2.inkMid,
          size: Os2.textSm,
          maxLines: 2,
        ),
      ],
    );
  }

  static String _factorHint(TravelScoreFactor f) {
    // Mock-but-credible explanations. A real implementation would
    // hand back a localized string keyed off the factor id; for
    // the demo layer we keep the voice on-brand and concise.
    switch (f.id) {
      case 'identity':
        return 'Biometric + document verification.';
      case 'history':
        return 'On-time travel + clean entries / exits.';
      case 'payments':
        return 'Settled balances, no chargebacks.';
      case 'social':
        return 'Vouches from your verified network.';
      case 'compliance':
        return 'Sanctions + watchlist clearance.';
      default:
        return 'Composite signal.';
    }
  }
}

class _WeightBar extends StatelessWidget {
  const _WeightBar({required this.value, required this.tone});

  final double value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 6,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: value),
        duration: Os2.mCruise,
        curve: Os2.cTaxi,
        builder: (context, t, _) => Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Os2.floor2,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            FractionallySizedBox(
              widthFactor: t,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: LinearGradient(
                    colors: [
                      tone.withValues(alpha: 0.6),
                      tone,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImproveCta extends StatelessWidget {
  const _ImproveCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.97,
      semanticLabel: label,
      semanticHint: 'opens Copilot recommendations to improve your score',
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: Os2.touchMin,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: Os2.foilGoldHero,
          borderRadius: BorderRadius.circular(Os2.rChip),
          boxShadow: [
            BoxShadow(
              color: Os2.goldDeep.withValues(alpha: 0.34),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Os2Text.monoCap(
          label,
          color: Os2.canvas,
          size: Os2.textSm,
        ),
      ),
    );
  }
}
