import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/page_scaffold.dart';
import '../wallet/wallet_provider.dart';

class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final theme = Theme.of(context);
    final last =
        wallet.transactions.isNotEmpty ? wallet.transactions.first : null;
    return PageScaffold(
      title: 'Receipt',
      subtitle: 'Latest scanned transaction',
      body: last == null
          ? const EmptyState(
              title: 'No receipts yet',
              message: 'Scan a paper receipt to capture line items.',
              icon: Icons.receipt_long_rounded,
            )
          : GlassSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(last.description, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: AppTokens.space2),
                  Text(last.merchant ?? '', style: theme.textTheme.bodyMedium),
                  const Divider(height: AppTokens.space5),
                  Row(
                    children: [
                      Expanded(child: Text('Amount')),
                      Text('${last.amount.toStringAsFixed(2)} ${last.currency}',
                          style: theme.textTheme.titleMedium),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: Text('Category')),
                      Text(last.category, style: theme.textTheme.titleMedium),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: Text('Date')),
                      Text(last.date, style: theme.textTheme.titleMedium),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
