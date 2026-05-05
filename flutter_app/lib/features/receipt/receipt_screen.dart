import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/animated_number.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../../widgets/toast.dart';
import '../wallet/wallet_provider.dart';

/// Receipt — premium scanned-transaction view. Hero amount with
/// animated number, category chip, action chips, copy/share/dispute.
class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    final theme = Theme.of(context);
    final last =
        wallet.transactions.isNotEmpty ? wallet.transactions.first : null;
    if (last == null) {
      return const PageScaffold(
        title: 'Receipt',
        subtitle: 'Latest scanned transaction',
        body: EmptyState(
          title: 'No receipts yet',
          message: 'Scan a paper receipt to capture line items.',
          icon: Icons.receipt_long_rounded,
        ),
      );
    }
    final accent = _categoryColor(last.category);
    return PageScaffold(
      title: 'Receipt',
      subtitle: 'Latest scanned transaction',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          AnimatedAppearance(
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space7),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.32),
                  accent.withValues(alpha: 0.08),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.32),
                      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                    ),
                    child: Text(
                      last.category.toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.space4),
                  Text(last.merchant ?? last.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      )),
                  const SizedBox(height: AppTokens.space2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AnimatedNumber(
                        value: last.amount,
                        prefix: '${_currencySymbol(last.currency)} ',
                        decimals: 2,
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(last.currency,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space2),
                  Text(last.date,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      )),
                ],
              ),
            ),
          ),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 120),
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space5),
              child: Column(
                children: [
                  _Detail('Description', last.description),
                  _Detail('Merchant', last.merchant ?? '—'),
                  _Detail('Category', last.category),
                  _Detail('Date', last.date),
                  _Detail('Currency', last.currency),
                ],
              ),
            ),
          ),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 200),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.space3),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ActionChip(
                    icon: Icons.copy_rounded,
                    label: 'Copy',
                    onTap: () {
                      Clipboard.setData(ClipboardData(
                          text:
                              '${last.merchant ?? last.description} ${last.amount} ${last.currency}'));
                      HapticFeedback.lightImpact();
                      AppToast.show(
                        context,
                        title: 'Copied to clipboard',
                        message:
                            '${last.merchant ?? last.description} • ${last.amount} ${last.currency}',
                        tone: AppToastTone.success,
                      );
                    },
                  ),
                  const _ActionChip(icon: Icons.share_rounded, label: 'Share'),
                  const _ActionChip(
                      icon: Icons.flag_outlined, label: 'Dispute'),
                  const _ActionChip(
                      icon: Icons.label_outline_rounded, label: 'Re-tag'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String c) {
    switch (c.toLowerCase()) {
      case 'travel':
        return const Color(0xFF06B6D4);
      case 'food':
      case 'dining':
        return const Color(0xFFF59E0B);
      case 'transport':
        return const Color(0xFF10B981);
      case 'shopping':
        return const Color(0xFFEC4899);
      case 'lodging':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF6366F1);
    }
  }

  String _currencySymbol(String code) {
    switch (code) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      default:
        return '';
    }
  }
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ))),
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      scale: 0.96,
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
          border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }
}
