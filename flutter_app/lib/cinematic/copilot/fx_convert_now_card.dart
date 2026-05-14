import 'package:flutter/material.dart';

import '../../cinematic/live/live_primitives.dart';
import '../../motion/motion.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/pressable.dart';
import 'fx_advisor.dart';

/// `FxConvertNowCard` — single Copilot FX recommendation surface.
///
/// Composes existing GlobeID primitives only:
///   • [BreathingHalo] for the alive thread; cadence keyed to the
///     [FxStrength] tier so high-conviction moves breathe harder.
///   • [Os2Text] variants for chrome (monoCap eyebrow, headline,
///     credential estimated-receive).
///   • [Pressable] with semantic label/hint for tap → exchange.
///
/// The card is intentionally narrow (≈ 280 px) so an
/// [FxConvertNowRail] of them scrolls horizontally with a credible
/// "this is one of several alive moves" rhythm.
class FxConvertNowCard extends StatelessWidget {
  const FxConvertNowCard({
    super.key,
    required this.recommendation,
    this.onTap,
    this.width = 280,
  });

  final FxRecommendation recommendation;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final r = recommendation;
    final tone = _toneFor(r.strength);
    final liveState = _liveStateFor(r.strength);

    return Pressable(
      scale: 0.97,
      semanticLabel: 'Convert ${r.suggestedAmount.toStringAsFixed(0)} '
          '${r.fromCurrency} to ${r.toCurrency}',
      semanticHint: 'opens the exchange sheet prefilled with this pair',
      onTap: () {
        Haptics.tap();
        onTap?.call();
      },
      child: SizedBox(
        width: width,
        child: BreathingHalo(
          tone: tone,
          state: liveState,
          maxAlpha: r.strength == FxStrength.high ? 0.36 : 0.24,
          expand: r.strength == FxStrength.high ? 22 : 14,
          child: Container(
            padding: const EdgeInsets.all(Os2.space4),
            decoration: BoxDecoration(
              color: Os2.floor1,
              borderRadius: BorderRadius.circular(Os2.rCard),
              border: Border.all(
                color: tone.withValues(
                  alpha: r.strength == FxStrength.high ? 0.42 : 0.22,
                ),
                width: Os2.strokeFine,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _Eyebrow(rationale: r.rationale, tone: tone),
                const SizedBox(height: Os2.space3),
                _PairLine(r: r),
                const SizedBox(height: Os2.space3),
                _ReceiveLine(r: r),
                const SizedBox(height: Os2.space2),
                _DeltaChip(r: r, tone: tone),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _toneFor(FxStrength s) {
    switch (s) {
      case FxStrength.high:
        return Os2.goldDeep;
      case FxStrength.notable:
        return Os2.pulseTone;
      case FxStrength.passive:
        return Os2.signalLive;
    }
  }

  LiveSurfaceState _liveStateFor(FxStrength s) {
    switch (s) {
      case FxStrength.high:
        return LiveSurfaceState.active;
      case FxStrength.notable:
        return LiveSurfaceState.armed;
      case FxStrength.passive:
        return LiveSurfaceState.idle;
    }
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.rationale, required this.tone});
  final String rationale;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tone,
          ),
        ),
        const SizedBox(width: Os2.space2),
        Expanded(
          child: Os2Text.monoCap(
            'COPILOT · FX · $rationale',
            color: tone,
            size: Os2.textTiny,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

class _PairLine extends StatelessWidget {
  const _PairLine({required this.r});
  final FxRecommendation r;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(r.fromFlag, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: Os2.space2),
        Os2Text.title(
          r.fromCurrency,
          color: Os2.inkBright,
          size: Os2.textRg,
        ),
        const SizedBox(width: Os2.space2),
        const Icon(
          Icons.east_rounded,
          size: 18,
          color: Os2.inkLow,
        ),
        const SizedBox(width: Os2.space2),
        Text(r.toFlag, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: Os2.space2),
        Os2Text.title(
          r.toCurrency,
          color: Os2.inkBright,
          size: Os2.textRg,
        ),
      ],
    );
  }
}

class _ReceiveLine extends StatelessWidget {
  const _ReceiveLine({required this.r});
  final FxRecommendation r;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Os2Text.monoCap(
          'CONVERT  ${r.suggestedAmount.toStringAsFixed(0)} ${r.fromCurrency}',
          color: Os2.inkMid,
          size: Os2.textTiny,
        ),
        const SizedBox(height: 2),
        Os2Text.credential(
          '≈ ${r.estimatedReceive.toStringAsFixed(2)} ${r.toCurrency}',
          color: Os2.inkBright,
          size: 22,
          gradient: r.strength == FxStrength.high
              ? Os2.foilGoldHero
              : null,
        ),
      ],
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.r, required this.tone});
  final FxRecommendation r;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    final sign = r.deltaPercent >= 0 ? '+' : '−';
    final pct = r.deltaPercent.abs().toStringAsFixed(2);
    final savingsAbs = r.estimatedSavings.abs();
    final savingsText = '≈ $sign${savingsAbs.toStringAsFixed(2)} '
        '${r.toCurrency} vs. yesterday';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Os2.space3,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Os2.rChip),
        border: Border.all(color: tone.withValues(alpha: 0.34)),
      ),
      child: Os2Text.monoCap(
        '$sign$pct%  ·  $savingsText',
        color: tone,
        size: Os2.textTiny,
        maxLines: 1,
      ),
    );
  }
}
