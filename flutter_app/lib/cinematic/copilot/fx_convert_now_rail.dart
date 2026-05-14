import 'package:flutter/material.dart';

import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import 'fx_advisor.dart';
import 'fx_convert_now_card.dart';

/// `FxConvertNowRail` — a horizontal Copilot rail rendered above
/// the Multi-Currency balance list. Surfaces the top 3–5 FX moves
/// the bearer should make today, in mono-cap chrome.
///
/// Composes [FxConvertNowCard]s — does not introduce new visuals.
/// The rail is silent when [recommendations] is empty (no chrome,
/// no eyebrow, no whitespace).
class FxConvertNowRail extends StatelessWidget {
  const FxConvertNowRail({
    super.key,
    required this.recommendations,
    this.onCardTap,
  });

  final List<FxRecommendation> recommendations;
  final void Function(FxRecommendation r)? onCardTap;

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Os2.space5,
            Os2.space4,
            Os2.space5,
            Os2.space2,
          ),
          child: Row(
            children: [
              const Os2Text.monoCap(
                'COPILOT · FX TODAY',
                color: Os2.goldDeep,
                size: Os2.textXs,
              ),
              const SizedBox(width: Os2.space2),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Os2.goldDeep,
                ),
              ),
              const Spacer(),
              Os2Text.monoCap(
                '${recommendations.length} MOVE'
                '${recommendations.length == 1 ? '' : 'S'}',
                color: Os2.inkMid,
                size: Os2.textTiny,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 188,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: Os2.space5),
            itemCount: recommendations.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: Os2.space3),
            itemBuilder: (context, i) {
              final r = recommendations[i];
              return FxConvertNowCard(
                recommendation: r,
                onTap: onCardTap == null ? null : () => onCardTap!(r),
              );
            },
          ),
        ),
        const SizedBox(height: Os2.space3),
      ],
    );
  }
}
