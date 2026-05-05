import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/models/travel_document.dart';
import '../../data/models/wallet_models.dart';
import '../../domain/airline_brand.dart';
import '../../widgets/animated_number.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/pressable.dart';
import '../../widgets/section_header.dart';
import '../user/user_provider.dart';
import 'wallet_provider.dart';

/// Wallet screen — Apple/Google-Wallet-style PassStack of boarding passes,
/// followed by multi-currency balances and recent transactions. Pulls
/// from `userProvider` (for boarding passes / travel docs) and
/// `walletProvider` (for balances / transactions).
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final wallet = ref.watch(walletProvider);
    final theme = Theme.of(context);
    final passes =
        user.documents.where((d) => d.type == 'boarding_pass').toList();

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(walletProvider.notifier).hydrate(),
          ref.read(userProvider.notifier).hydrate(),
        ]);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + AppTokens.space5,
              left: AppTokens.space5,
              right: AppTokens.space5,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text('Wallet', style: theme.textTheme.headlineLarge),
                  const Spacer(),
                  IconButton(
                    onPressed: () => context.push('/multi-currency'),
                    icon: const Icon(Icons.currency_exchange_rounded),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: const SectionHeader(title: 'Passes', dense: true),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space5, vertical: AppTokens.space2),
            sliver: SliverToBoxAdapter(
              child: passes.isEmpty
                  ? const _PassEmpty()
                  : _PassStack(passes: passes),
            ),
          ),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Balances',
              subtitle: '${wallet.balances.length} currencies',
              action: 'Convert',
              onAction: () => context.push('/multi-currency'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space5),
            sliver: SliverToBoxAdapter(
                child: _BalancesGrid(balances: wallet.balances)),
          ),
          SliverToBoxAdapter(
            child: const SectionHeader(title: 'Recent transactions'),
          ),
          if (wallet.transactions.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: const EmptyState(
                title: 'No transactions yet',
                message: 'Scan a receipt or record a payment to see history.',
                icon: Icons.receipt_long_rounded,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppTokens.space5, 0, AppTokens.space5, AppTokens.space9 + 16),
              sliver: SliverList.separated(
                itemCount: wallet.transactions.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppTokens.space2),
                itemBuilder: (_, i) => _TxRow(tx: wallet.transactions[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _PassEmpty extends StatelessWidget {
  const _PassEmpty();
  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppTokens.space6),
      child: Row(
        children: [
          Icon(Icons.confirmation_number_outlined,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Text(
              'No boarding passes yet — add a trip with a confirmed flight to generate one.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _PassStack extends StatefulWidget {
  const _PassStack({required this.passes});
  final List<TravelDocument> passes;
  @override
  State<_PassStack> createState() => _PassStackState();
}

class _PassStackState extends State<_PassStack> {
  late final PageController _ctrl = PageController(viewportFraction: 0.88);
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      setState(() => _page = _ctrl.page ?? 0);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: PageView.builder(
        controller: _ctrl,
        itemCount: widget.passes.length,
        itemBuilder: (context, i) {
          final delta = (_page - i).abs();
          final scale = (1 - (delta * 0.08)).clamp(0.84, 1.0);
          final opacity = (1 - (delta * 0.4)).clamp(0.4, 1.0);
          return Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppTokens.space2),
                child: Pressable(
                  scale: 0.98,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    GoRouter.of(context).push('/pass/${widget.passes[i].id}');
                  },
                  child: Hero(
                    tag: 'pass-${widget.passes[i].id}',
                    child: Material(
                      type: MaterialType.transparency,
                      child: PassCard(pass: widget.passes[i]),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Apple Wallet-style boarding pass card with parallax tilt + QR flip.
class PassCard extends StatefulWidget {
  const PassCard({super.key, required this.pass});
  final TravelDocument pass;

  @override
  State<PassCard> createState() => _PassCardState();
}

class _PassCardState extends State<PassCard> {
  double _tiltX = 0, _tiltY = 0;
  bool _flipped = false;
  late final Stream<AccelerometerEvent> _stream = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50));

  @override
  Widget build(BuildContext context) {
    final brand = resolveAirlineBrand(widget.pass.label);

    return StreamBuilder<AccelerometerEvent>(
      stream: _stream,
      builder: (_, snap) {
        if (snap.hasData) {
          final e = snap.data!;
          // Clamp tilt to ±10°.
          _tiltX = (e.y.clamp(-3, 3) / 3) * (math.pi / 18);
          _tiltY = (e.x.clamp(-3, 3) / 3) * (math.pi / 18);
        }
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _flipped = !_flipped);
          },
          child: AnimatedSwitcher(
            duration: AppTokens.durationMd,
            transitionBuilder: (c, a) {
              final rotate = Tween(begin: math.pi, end: 0.0).animate(a);
              return AnimatedBuilder(
                animation: rotate,
                builder: (_, child) {
                  final isUnder = (ValueKey(_flipped) != c.key);
                  var tilt = isUnder
                      ? math.min(rotate.value, math.pi / 2)
                      : rotate.value;
                  return Transform(
                    transform: Matrix4.rotationY(tilt),
                    alignment: Alignment.center,
                    child: child,
                  );
                },
                child: c,
              );
            },
            child: _flipped
                ? _PassQr(pass: widget.pass, brand: brand)
                : _PassFront(
                    pass: widget.pass,
                    brand: brand,
                    tiltX: _tiltX,
                    tiltY: _tiltY,
                  ),
          ),
        );
      },
    );
  }
}

class _PassFront extends StatelessWidget {
  const _PassFront({
    required this.pass,
    required this.brand,
    required this.tiltX,
    required this.tiltY,
  });
  final TravelDocument pass;
  final AirlineBrand brand;
  final double tiltX;
  final double tiltY;

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(tiltX)
        ..rotateY(tiltY),
      alignment: Alignment.center,
      child: ClipRRect(
        key: const ValueKey('front'),
        borderRadius: BorderRadius.circular(AppTokens.radius2xl),
        child: Container(
          padding: const EdgeInsets.all(AppTokens.space5),
          decoration: BoxDecoration(
            gradient: brand.gradient(),
            boxShadow: [
              BoxShadow(
                color: brand.primary.withValues(alpha: 0.45),
                blurRadius: 32,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Subtle radial highlight that tracks tilt.
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(tiltY * 6, tiltX * 6),
                        radius: 1,
                        colors: [
                          Colors.white.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(pass.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          )),
                      const Spacer(),
                      const Icon(Icons.flight, color: Colors.white70),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _PassIata(
                        code: pass.label.length >= 3
                            ? pass.label.substring(0, 3).toUpperCase()
                            : 'GID',
                      ),
                      const Spacer(),
                      Icon(Icons.flight,
                          color: Colors.white.withValues(alpha: 0.85)),
                      const Spacer(),
                      Text(pass.countryFlag,
                          style: const TextStyle(fontSize: 32)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _PassMeta(
                          label: 'Passenger',
                          value: pass.number,
                        ),
                      ),
                      Expanded(
                        child: _PassMeta(
                          label: 'Departs',
                          value: pass.issueDate,
                        ),
                      ),
                      Expanded(
                        child: _PassMeta(
                          label: 'Status',
                          value: pass.status,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PassQr extends StatelessWidget {
  const _PassQr({required this.pass, required this.brand});
  final TravelDocument pass;
  final AirlineBrand brand;
  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.rotationY(math.pi),
      alignment: Alignment.center,
      child: ClipRRect(
        key: const ValueKey('back'),
        borderRadius: BorderRadius.circular(AppTokens.radius2xl),
        child: Container(
          padding: const EdgeInsets.all(AppTokens.space5),
          color: Colors.white,
          child: Center(
            child: QrImageView(
              data: pass.number,
              size: 180,
              backgroundColor: Colors.white,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: brand.primary,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: brand.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PassIata extends StatelessWidget {
  const _PassIata({required this.code});
  final String code;
  @override
  Widget build(BuildContext context) {
    return Text(code,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.6,
        ));
  }
}

class _PassMeta extends StatelessWidget {
  const _PassMeta({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: Colors.white.withValues(alpha: 0.6),
            )),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1),
      ],
    );
  }
}

class _BalancesGrid extends StatelessWidget {
  const _BalancesGrid({required this.balances});
  final List<WalletBalance> balances;
  @override
  Widget build(BuildContext context) {
    if (balances.isEmpty) {
      return GlassSurface(
        child: Row(
          children: const [
            Icon(Icons.account_balance_wallet_rounded),
            SizedBox(width: AppTokens.space3),
            Expanded(
                child: Text(
                    'No balances yet — convert from your default currency to begin.')),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final b in balances)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.space2),
            child: _BalanceRow(b: b),
          ),
      ],
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.b});
  final WalletBalance b;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassSurface(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space4, vertical: AppTokens.space3),
      child: Row(
        children: [
          Text(b.flag, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.currency,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    )),
                Text('Rate ${b.rate.toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          AnimatedNumber(
            value: b.amount,
            prefix: b.symbol,
            decimals: 2,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({required this.tx});
  final WalletTransaction tx;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit = tx.amount > 0;
    final color = isCredit ? Colors.green : theme.colorScheme.onSurface;
    return Pressable(
      scale: 0.98,
      onTap: () => _showSheet(context),
      child: GlassSurface(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space4, vertical: AppTokens.space3),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              ),
              child: Icon(_iconForCategory(tx.category),
                  color: theme.colorScheme.primary),
            ),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.description, style: theme.textTheme.titleSmall),
                  Text('${tx.merchant ?? tx.category} · ${tx.date}',
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Text(
                '${isCredit ? '+' : '−'}${tx.amount.abs().toStringAsFixed(2)} ${tx.currency}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                )),
          ],
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TxDetailSheet(tx: tx, iconFor: _iconForCategory),
    );
  }

  IconData _iconForCategory(String c) {
    switch (c) {
      case 'flight':
        return Icons.flight_rounded;
      case 'hotel':
        return Icons.hotel_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'entertainment':
        return Icons.local_activity_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'transfer':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.attach_money_rounded;
    }
  }
}

class _TxDetailSheet extends StatelessWidget {
  const _TxDetailSheet({required this.tx, required this.iconFor});
  final WalletTransaction tx;
  final IconData Function(String) iconFor;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit = tx.amount > 0;
    return Container(
      margin: const EdgeInsets.all(AppTokens.space4),
      padding: const EdgeInsets.all(AppTokens.space5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius2xl),
        border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.10)),
        boxShadow: AppTokens.shadowLg(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.32),
                      theme.colorScheme.primary.withValues(alpha: 0.12),
                    ],
                  ),
                ),
                child: Icon(iconFor(tx.category),
                    color: theme.colorScheme.primary, size: 28),
              ),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.description,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
                    Text(tx.merchant ?? tx.category,
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space5),
          Center(
            child: Text(
              '${isCredit ? '+' : '−'}${tx.amount.abs().toStringAsFixed(2)} ${tx.currency}',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: isCredit
                    ? const Color(0xFF10B981)
                    : theme.colorScheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space5),
          _DetailRow(label: 'Category', value: tx.category),
          _DetailRow(label: 'Date', value: tx.date),
          _DetailRow(label: 'Currency', value: tx.currency),
          if (tx.merchant != null)
            _DetailRow(label: 'Merchant', value: tx.merchant!),
          const SizedBox(height: AppTokens.space5),
          Row(
            children: [
              Expanded(
                child: Pressable(
                  scale: 0.97,
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.06),
                    ),
                    child: const Text('Close',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.space2),
              Expanded(
                child: Pressable(
                  scale: 0.97,
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withValues(alpha: 0.6),
                        ],
                      ),
                      boxShadow:
                          AppTokens.shadowMd(tint: theme.colorScheme.primary),
                    ),
                    child: const Text('Re-tag',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        )),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              )),
          const Spacer(),
          Text(value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }
}
