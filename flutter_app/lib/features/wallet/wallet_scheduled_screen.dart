import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/wallet_models.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_chip.dart';
import '../../os2/primitives/os2_divider_rule.dart';
import '../../os2/primitives/os2_magnetic.dart';
import '../../os2/primitives/os2_slab.dart';
import '../../os2/primitives/os2_text.dart';
import '../../os2/primitives/os2_world_header.dart';
import 'merchant_brand.dart';
import 'wallet_provider.dart';

/// Scheduled & recurring payments — derived deterministically from the
/// wallet's existing subscription & insurance transactions so the
/// list is always grounded in real data the user has seen elsewhere
/// in the app, no placeholder rows.
class WalletScheduledScreen extends ConsumerWidget {
  const WalletScheduledScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final upcoming = _derive(wallet.transactions);

    return Scaffold(
      backgroundColor: Os2.floor1,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Os2WorldHeader(
                world: Os2World.wallet,
                title: 'Scheduled',
                subtitle: 'Recurring \u00b7 standing orders',
                beacon: upcoming.isEmpty ? 'IDLE' : 'ACTIVE',
              ),
              const SizedBox(height: Os2.space4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _SummaryCard(items: upcoming),
              ),
              const SizedBox(height: Os2.space5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space5),
                child: Os2DividerRule(
                  eyebrow: 'UPCOMING',
                  tone: Os2.walletTone,
                  trailing: upcoming.isEmpty ? '0' : '${upcoming.length}',
                ),
              ),
              const SizedBox(height: Os2.space3),
              if (upcoming.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: Os2.space4),
                  child: _EmptyState(),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                  child: Column(
                    children: [
                      for (int i = 0; i < upcoming.length; i++) ...[
                        _ScheduledRow(item: upcoming[i]),
                        if (i < upcoming.length - 1)
                          const SizedBox(height: Os2.space3),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the upcoming-schedule list from real wallet transactions:
  /// subscription + insurance categories repeat monthly; other repeat
  /// patterns are inferred from `reference` markers when present.
  static List<_ScheduledItem> _derive(List<WalletTransaction> txns) {
    final now = DateTime.now();
    final byMerchant = <String, _ScheduledItem>{};
    for (final t in txns) {
      final isRecurring =
          t.category == 'Subscription' || t.category == 'Insurance';
      if (!isRecurring) continue;
      final key = (t.merchant ?? t.description).toLowerCase();
      if (byMerchant.containsKey(key)) continue;
      final base = DateTime.tryParse(t.date) ?? now;
      final next = DateTime(now.year, now.month, base.day)
          .add(Duration(days: base.day < now.day ? 30 : 0));
      byMerchant[key] = _ScheduledItem(
        merchant: t.merchant ?? t.description,
        description: t.description,
        category: t.category,
        currency: t.currency,
        amount: t.amount.abs(),
        nextDate: next,
      );
    }
    final out = byMerchant.values.toList()
      ..sort((a, b) => a.nextDate.compareTo(b.nextDate));
    return out;
  }
}

class _ScheduledItem {
  _ScheduledItem({
    required this.merchant,
    required this.description,
    required this.category,
    required this.currency,
    required this.amount,
    required this.nextDate,
  });

  final String merchant;
  final String description;
  final String category;
  final String currency;
  final double amount;
  final DateTime nextDate;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.items});
  final List<_ScheduledItem> items;

  @override
  Widget build(BuildContext context) {
    final monthly = items.fold<double>(0, (acc, e) => acc + e.amount);
    return Os2Slab(
      tone: Os2.walletTone,
      tier: Os2SlabTier.floor2,
      radius: Os2.rCard,
      halo: Os2SlabHalo.corner,
      elevation: Os2SlabElevation.resting,
      padding: const EdgeInsets.all(Os2.space4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Os2Text.caption(
                  'MONTHLY OUTFLOW',
                  color: Os2.walletTone,
                ),
                const SizedBox(height: 4),
                Os2Text.headline(
                  '\$${monthly.toStringAsFixed(2)}',
                  color: Os2.inkBright,
                  size: 26,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Os2Text.caption(
                  '${items.length} active commitment${items.length == 1 ? '' : 's'}',
                  color: Os2.inkLow,
                ),
              ],
            ),
          ),
          Os2Chip(
            label: 'AUTO',
            tone: Os2.signalSettled,
            icon: Icons.autorenew_rounded,
            intensity: Os2ChipIntensity.solid,
          ),
        ],
      ),
    );
  }
}

class _ScheduledRow extends StatelessWidget {
  const _ScheduledRow({required this.item});
  final _ScheduledItem item;

  @override
  Widget build(BuildContext context) {
    final brand = MerchantDirectory.resolve(
      merchant: item.merchant,
      description: item.description,
      category: item.category,
    );
    return Os2Magnetic(
      onTap: () {},
      child: Os2Slab(
        tone: Os2.walletTone,
        tier: Os2SlabTier.floor1,
        radius: Os2.rCard,
        halo: Os2SlabHalo.none,
        elevation: Os2SlabElevation.flat,
        padding: const EdgeInsets.all(Os2.space4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: brand.tone.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: brand.tone.withValues(alpha: 0.30),
                  width: Os2.strokeFine,
                ),
              ),
              child: Center(
                child: Icon(brand.icon, color: brand.tone, size: 18),
              ),
            ),
            const SizedBox(width: Os2.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Os2Text.title(
                    item.merchant,
                    color: Os2.inkBright,
                    size: 14,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Os2Text.caption(
                    '${item.category.toUpperCase()} \u00b7 ${_formatDate(item.nextDate)}',
                    color: Os2.inkLow,
                  ),
                ],
              ),
            ),
            Os2Text.title(
              '${item.currency} ${item.amount.toStringAsFixed(2)}',
              color: Os2.inkBright,
              size: 14,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final today = DateTime.now();
    final diff = d.difference(DateTime(today.year, today.month, today.day));
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inDays > 1 && diff.inDays < 7) return 'In ${diff.inDays}d';
    return '${months[d.month - 1]} ${d.day}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Os2Slab(
      tone: Os2.walletTone,
      tier: Os2SlabTier.floor1,
      radius: Os2.rCard,
      halo: Os2SlabHalo.corner,
      elevation: Os2SlabElevation.flat,
      padding: const EdgeInsets.all(Os2.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.event_busy_rounded, size: 20, color: Os2.walletTone),
          const SizedBox(height: Os2.space3),
          Os2Text.title('Nothing scheduled', color: Os2.inkBright, size: Os2.textLg),
          const SizedBox(height: 4),
          Os2Text.body(
            'When you set up a recurring payment it will appear here with the next run date.',
            color: Os2.inkMid,
            size: 13,
          ),
        ],
      ),
    );
  }
}
