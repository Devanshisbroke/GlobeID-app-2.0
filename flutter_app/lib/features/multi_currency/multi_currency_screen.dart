import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/page_scaffold.dart';
import '../wallet/wallet_provider.dart';

class MultiCurrencyScreen extends ConsumerWidget {
  const MultiCurrencyScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final theme = Theme.of(context);
    return PageScaffold(
      title: 'Multi-currency',
      subtitle: 'Default ${wallet.defaultCurrency}',
      body: wallet.balances.isEmpty
          ? const EmptyState(
              title: 'No balances yet',
              message: 'Convert from your default currency to begin.',
              icon: Icons.currency_exchange_rounded,
            )
          : ListView.separated(
              itemCount: wallet.balances.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppTokens.space2),
              itemBuilder: (_, i) {
                final b = wallet.balances[i];
                final isDefault = b.currency == wallet.defaultCurrency;
                return GlassSurface(
                  child: Row(
                    children: [
                      Text(b.flag, style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: AppTokens.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.currency,
                                style: theme.textTheme.titleMedium),
                            Text('Rate ${b.rate.toStringAsFixed(2)}',
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Text('${b.symbol}${b.amount.toStringAsFixed(2)}',
                          style: theme.textTheme.titleLarge),
                      const SizedBox(width: AppTokens.space2),
                      if (isDefault)
                        Icon(Icons.star_rounded,
                            color: theme.colorScheme.primary)
                      else
                        IconButton(
                          icon: const Icon(Icons.star_outline_rounded),
                          onPressed: () => ref
                              .read(walletProvider.notifier)
                              .setDefaultCurrency(b.currency),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
