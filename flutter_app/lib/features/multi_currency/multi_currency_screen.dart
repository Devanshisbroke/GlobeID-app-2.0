import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/models/wallet_models.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/animated_number.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../wallet/wallet_provider.dart';

/// Multi-currency v2 — animated balances, sparkline of FX rate,
/// pressable rows, set-default action.
class MultiCurrencyScreen extends ConsumerWidget {
  const MultiCurrencyScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    return PageScaffold(
      title: 'Multi-currency',
      subtitle: 'Default ${wallet.defaultCurrency}',
      body: wallet.balances.isEmpty
          ? const EmptyState(
              title: 'No balances yet',
              message: 'Convert from your default currency to begin.',
              icon: Icons.currency_exchange_rounded,
            )
          : ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                for (var i = 0; i < wallet.balances.length; i++)
                  AnimatedAppearance(
                    delay: Duration(milliseconds: 50 * i),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppTokens.space3),
                      child: _CurrencyRow(
                        balance: wallet.balances[i],
                        isDefault: wallet.balances[i].currency ==
                            wallet.defaultCurrency,
                        onSetDefault: () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(walletProvider.notifier)
                              .setDefaultCurrency(wallet.balances[i].currency);
                        },
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _CurrencyRow extends StatelessWidget {
  const _CurrencyRow({
    required this.balance,
    required this.isDefault,
    required this.onSetDefault,
  });
  final WalletBalance balance;
  final bool isDefault;
  final VoidCallback onSetDefault;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = isDefault
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.4);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      gradient: isDefault
          ? LinearGradient(
              colors: [
                accent.withValues(alpha: 0.18),
                accent.withValues(alpha: 0.04),
              ],
            )
          : null,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
            ),
            child: Text(balance.flag, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(balance.currency,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(width: 6),
                    Text('· ${balance.rate.toStringAsFixed(4)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        )),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 18,
                  width: 80,
                  child: CustomPaint(
                    painter: _Sparkline(
                      seed: balance.currency.hashCode,
                      color: isDefault
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedNumber(
                value: balance.amount,
                prefix: balance.symbol,
                decimals: 2,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Pressable(
                scale: 0.96,
                onTap: isDefault ? () {} : onSetDefault,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                    color: isDefault
                        ? theme.colorScheme.primary.withValues(alpha: 0.18)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDefault
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 14,
                        color: isDefault
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isDefault ? 'Default' : 'Set default',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDefault
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Sparkline extends CustomPainter {
  _Sparkline({required this.seed, required this.color});
  final int seed;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    const points = 24;
    final path = Path();
    final fill = Path();
    for (var i = 0; i < points; i++) {
      final x = i * size.width / (points - 1);
      final y = (0.5 +
              0.4 * math.sin(i * 0.5 + seed % 7) +
              rng.nextDouble() * 0.2 -
              0.1) *
          size.height;
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.32),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fill, fillPaint);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _Sparkline old) =>
      old.seed != seed || old.color != color;
}
