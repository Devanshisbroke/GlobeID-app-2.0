import 'package:flutter/material.dart';

import '../../app/theme/airport_typography.dart';
import '../../app/theme/app_tokens.dart';
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
    final theme = Theme.of(context);
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
          final tone = up ? const Color(0xFF10B981) : const Color(0xFFEF4444);
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
                          style: AirportFontStack.iata(context, size: 14)),
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
                  // Solari numerals scaled to fit the 168-pt cell.
                  // Without `FittedBox` the default 26-pt char width
                  // overflows on 6+ digit pairs (e.g. "1.0892",
                  // "156.42"); the previous build clipped the last
                  // glyph against the cell stroke.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: DepartureBoardText(
                      text: t.rate.toStringAsFixed(t.rate >= 100 ? 2 : 4),
                      charWidth: 18,
                      style: AirportFontStack.board(context, size: 20),
                      tone: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${up ? '+' : ''}${t.changePercent.toStringAsFixed(2)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tone,
                      fontWeight: FontWeight.w800,
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
