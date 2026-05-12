import 'package:flutter/material.dart';

import '../../app/theme/airport_typography.dart';
import '../../app/theme/app_tokens.dart';
import '../../nexus/nexus_tokens.dart';
import 'contextual_surface.dart';
import 'departure_board_flap.dart';

/// A single FX rate row used by [FxTickerPremium].
class FxTick {
  const FxTick({
    required this.pair,
    required this.rate,
    required this.changePercent,
  });
  final String pair;
  final double rate;

  /// Signed percent change (e.g. +0.4 means up 0.4%).
  final double changePercent;
}

/// FxTickerPremium — a Solari-board style horizontal scroller that
/// renders a list of currency pairs with rate + colour-coded
/// percent change. Used in wallet / multi-currency surfaces.
class FxTickerPremium extends StatelessWidget {
  const FxTickerPremium({
    super.key,
    required this.ticks,
    this.height = 96,
  });

  final List<FxTick> ticks;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space5),
        itemCount: ticks.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTokens.space3),
        itemBuilder: (_, i) {
          final t = ticks[i];
          final up = t.changePercent >= 0;
          final tone = up ? N.success : N.critical;
          return SizedBox(
            width: 168,
            child: ContextualSurface(
              padding: const EdgeInsets.all(AppTokens.space3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(t.pair.toUpperCase(),
                          style: AirportFontStack.iata(context, size: 14)
                              .copyWith(color: N.inkHi)),
                      const Spacer(),
                      Icon(
                        up
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 14,
                        color: tone,
                      ),
                    ],
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: DepartureBoardText(
                      text: t.rate.toStringAsFixed(t.rate >= 100 ? 2 : 4),
                      charWidth: 18,
                      style: AirportFontStack.board(context, size: 20),
                      tone: N.inkHi,
                    ),
                  ),
                  Text(
                    '${up ? '+' : ''}${t.changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: tone,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
