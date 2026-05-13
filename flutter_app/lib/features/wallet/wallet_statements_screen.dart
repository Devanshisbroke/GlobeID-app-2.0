import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/wallet_models.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_chip.dart';
import '../../os2/primitives/os2_divider_rule.dart';
import '../../os2/primitives/os2_magnetic.dart';
import '../../os2/primitives/os2_slab.dart';
import '../../os2/primitives/os2_text.dart';
import '../../os2/primitives/os2_world_header.dart';
import 'wallet_provider.dart';

/// Statements — month-grouped digests of wallet activity rolled up
/// directly from `WalletTransaction`. Each row is tappable to copy a
/// CSV export of that month to the clipboard. No fake data: every
/// month and every line item is derived from the real ledger.
class WalletStatementsScreen extends ConsumerWidget {
  const WalletStatementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final months = _buildMonths(wallet.transactions);

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
                title: 'Statements',
                subtitle: 'Monthly ledger \u00b7 export-ready',
                beacon: 'LEDGER',
              ),
              const SizedBox(height: Os2.space4),
              if (months.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: Os2.space4),
                  child: _EmptyState(),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Os2.space5),
                  child: Os2DividerRule(
                    eyebrow: 'TIMELINE',
                    tone: Os2.walletTone,
                    trailing: '${months.length} STATEMENT'
                        '${months.length == 1 ? '' : 'S'}',
                  ),
                ),
                const SizedBox(height: Os2.space3),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Os2.space4,
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < months.length; i++) ...[
                        _StatementRow(month: months[i]),
                        if (i < months.length - 1)
                          const SizedBox(height: Os2.space3),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static List<_StatementMonth> _buildMonths(List<WalletTransaction> txns) {
    if (txns.isEmpty) return const [];
    final buckets = <String, List<WalletTransaction>>{};
    for (final t in txns) {
      final d = DateTime.tryParse(t.date);
      if (d == null) continue;
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      buckets.putIfAbsent(key, () => []).add(t);
    }
    final out = <_StatementMonth>[];
    final keys = buckets.keys.toList()..sort((a, b) => b.compareTo(a));
    for (final k in keys) {
      final list = buckets[k]!;
      var outflow = 0.0;
      var inflow = 0.0;
      for (final t in list) {
        if (t.type == 'receive' || t.type == 'refund') {
          inflow += t.amount.abs();
        } else {
          outflow += t.amount.abs();
        }
      }
      final parts = k.split('-');
      out.add(_StatementMonth(
        year: int.parse(parts[0]),
        month: int.parse(parts[1]),
        count: list.length,
        inflow: inflow,
        outflow: outflow,
        txns: list,
      ));
    }
    return out;
  }
}

class _StatementMonth {
  _StatementMonth({
    required this.year,
    required this.month,
    required this.count,
    required this.inflow,
    required this.outflow,
    required this.txns,
  });

  final int year;
  final int month;
  final int count;
  final double inflow;
  final double outflow;
  final List<WalletTransaction> txns;

  static const _names = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String get label => '${_names[month - 1]} $year';
  double get net => inflow - outflow;
}

class _StatementRow extends StatelessWidget {
  const _StatementRow({required this.month});
  final _StatementMonth month;

  @override
  Widget build(BuildContext context) {
    final netTone = month.net >= 0 ? Os2.signalSettled : Os2.walletTone;
    return Os2Magnetic(
      onTap: () => _exportCsv(context),
      child: Os2Slab(
        tone: Os2.walletTone,
        tier: Os2SlabTier.floor1,
        radius: Os2.rCard,
        halo: Os2SlabHalo.corner,
        elevation: Os2SlabElevation.flat,
        padding: const EdgeInsets.all(Os2.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Os2Text.caption(
                        'STATEMENT',
                        color: Os2.walletTone,
                      ),
                      const SizedBox(height: 2),
                      Os2Text.title(
                        month.label,
                        color: Os2.inkBright,
                        size: 16,
                      ),
                    ],
                  ),
                ),
                Os2Chip(
                  label: '${month.count} TX',
                  tone: Os2.walletTone,
                  icon: Icons.list_alt_rounded,
                  intensity: Os2ChipIntensity.ghost,
                ),
              ],
            ),
            const SizedBox(height: Os2.space3),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: 'INFLOW',
                    value: '+\$${month.inflow.toStringAsFixed(0)}',
                    tone: Os2.signalSettled,
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: 'OUTFLOW',
                    value: '-\$${month.outflow.toStringAsFixed(0)}',
                    tone: Os2.inkBright,
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: 'NET',
                    value: '${month.net >= 0 ? '+' : '-'}'
                        '\$${month.net.abs().toStringAsFixed(0)}',
                    tone: netTone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Os2.space3),
            Row(
              children: [
                Icon(
                  Icons.file_download_outlined,
                  size: 14,
                  color: Os2.walletTone,
                ),
                const SizedBox(width: 6),
                Os2Text.caption(
                  'TAP TO COPY CSV',
                  color: Os2.walletTone,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    final buf = StringBuffer()
      ..writeln('date,type,merchant,description,category,amount,currency');
    for (final t in month.txns) {
      final merchant = (t.merchant ?? '').replaceAll(',', ' ');
      final description = t.description.replaceAll(',', ' ');
      buf.writeln(
        '${t.date},${t.type},$merchant,$description,${t.category},'
        '${t.amount.toStringAsFixed(2)},${t.currency}',
      );
    }
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${month.label} CSV copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.tone,
  });
  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Os2Text.caption(label, color: Os2.inkLow),
        const SizedBox(height: 2),
        Os2Text.title(value, color: tone, size: 14),
      ],
    );
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
          Icon(Icons.receipt_long_rounded, size: 20, color: Os2.walletTone),
          const SizedBox(height: Os2.space3),
          Os2Text.title('No statements yet', color: Os2.inkBright, size: 16),
          const SizedBox(height: 4),
          Os2Text.body(
            'Your monthly ledger appears here as transactions settle.',
            color: Os2.inkMid,
            size: 13,
          ),
        ],
      ),
    );
  }
}
