
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/pressable.dart';
import '../../widgets/sparkline.dart';

/// Horizontally scrolling live FX ticker with sparkline trends.
///
/// Each pair shows: flag + code + rate + mini sparkline.
/// Tap → navigate to /multi-currency with pair pre-selected.
class WalletFxTicker extends StatelessWidget {
  const WalletFxTicker({super.key, required this.pairs, this.onTap});

  final List<FxPair> pairs;
  final ValueChanged<FxPair>? onTap;

  @override
  Widget build(BuildContext context) {
    if (pairs.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space5),
        itemCount: pairs.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTokens.space2),
        itemBuilder: (_, i) => _FxPairTile(
          pair: pairs[i],
          onTap: () {
            HapticFeedback.selectionClick();
            onTap?.call(pairs[i]);
          },
        ),
      ),
    );
  }
}

class _FxPairTile extends StatelessWidget {
  const _FxPairTile({required this.pair, required this.onTap});
  final FxPair pair;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final trendUp = pair.trend.isNotEmpty &&
        pair.trend.last > pair.trend.first;
    final trendColor = trendUp
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);

    return Pressable(
      scale: 0.97,
      onTap: onTap,
      child: Container(
        width: 152,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space3,
          vertical: AppTokens.space2,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusXl),
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.72),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${pair.from}/${pair.to}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pair.rate.toStringAsFixed(pair.rate < 10 ? 4 : 2),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendUp
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 12,
                        color: trendColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${trendUp ? '+' : ''}${pair.changePercent.toStringAsFixed(2)}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: trendColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Mini sparkline
            if (pair.trend.isNotEmpty)
              SizedBox(
                width: 40,
                height: 28,
                child: Sparkline(
                  values: pair.trend.map((e) => e.round()).toList(),
                  color: trendColor,
                  height: 28,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FxPair {
  const FxPair({
    required this.from,
    required this.to,
    required this.rate,
    required this.changePercent,
    this.trend = const [],
  });

  final String from;
  final String to;
  final double rate;
  final double changePercent;
  final List<double> trend;

  /// Demo FX pairs.
  static List<FxPair> demo() => const [
        FxPair(
          from: 'USD',
          to: 'EUR',
          rate: 0.9245,
          changePercent: -0.12,
          trend: [0.926, 0.925, 0.924, 0.926, 0.923, 0.924, 0.9245],
        ),
        FxPair(
          from: 'USD',
          to: 'GBP',
          rate: 0.7891,
          changePercent: 0.08,
          trend: [0.787, 0.788, 0.789, 0.788, 0.790, 0.789, 0.7891],
        ),
        FxPair(
          from: 'USD',
          to: 'JPY',
          rate: 156.42,
          changePercent: 0.34,
          trend: [155.8, 155.9, 156.1, 156.0, 156.3, 156.2, 156.42],
        ),
        FxPair(
          from: 'EUR',
          to: 'GBP',
          rate: 0.8537,
          changePercent: -0.05,
          trend: [0.854, 0.854, 0.853, 0.854, 0.853, 0.854, 0.8537],
        ),
        FxPair(
          from: 'USD',
          to: 'AED',
          rate: 3.6725,
          changePercent: 0.01,
          trend: [3.672, 3.672, 3.673, 3.672, 3.673, 3.672, 3.6725],
        ),
      ];
}
