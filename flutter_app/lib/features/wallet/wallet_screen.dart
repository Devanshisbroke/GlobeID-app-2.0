import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../app/theme/app_tokens.dart';
import '../../cinematic/sheets/apple_sheet.dart';
import '../../cinematic/states/cinematic_states.dart';
import '../../data/models/travel_document.dart';
import '../../data/models/wallet_models.dart';
import '../../domain/airline_brand.dart';
import '../../widgets/animated_number.dart';
import '../../widgets/app_chrome.dart';
import '../../widgets/bible/bible.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/premium/premium.dart';
import '../../widgets/pressable.dart';
import '../../app/theme/emotional_palette.dart';
import '../../motion/haptic_refresh.dart';
import '../../widgets/section_header.dart';
import '../../widgets/sparkline.dart';
import '../user/user_provider.dart';
import 'wallet_fx_ticker.dart';
import 'wallet_hero_card.dart';
import 'spending_chart.dart';
import 'wallet_provider.dart';

/// Wallet screen — Apple/Google-Wallet-style PassStack of boarding passes,
/// followed by multi-currency balances and recent transactions. Pulls
/// from `userProvider` (for boarding passes / travel docs) and
/// `walletProvider` (for balances / transactions).
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = ref.watch(userProvider);
    final wallet = ref.watch(walletProvider);
    final passes =
        user.documents.where((d) => d.type == 'boarding_pass').toList();

    return HapticRefresh(
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
          BibleTopBar(
            title: 'Wallet',
            subtitle:
                '${wallet.balances.length} currencies · ${wallet.transactions.length} recent',
            tone: BibleTone.treasuryGreen,
            actions: [
              BibleTopBarAction(
                icon: Icons.currency_exchange_rounded,
                tooltip: 'Multi-currency',
                onTap: () => context.push('/multi-currency'),
              ),
              const InboxBellAction(),
              const ThemeCyclerAction(),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space5,
              AppTokens.space2,
              AppTokens.space5,
              AppTokens.space4,
            ),
            sliver: SliverToBoxAdapter(
              child: WalletHeroCard(
                balance: wallet.balances.fold<double>(
                  0,
                  (sum, b) =>
                      sum +
                      (b.currency == wallet.defaultCurrency ? b.amount : 0),
                ),
                currency: wallet.defaultCurrency,
                emotion: EmotionalPalette.detect(),
                subtitle:
                    '${wallet.balances.length} currencies • ${wallet.transactions.length} recent transactions',
                progress: wallet.balances.isEmpty
                    ? 0
                    : (wallet.balances
                                .firstWhere(
                                  (b) => b.currency == wallet.defaultCurrency,
                                  orElse: () => wallet.balances.first,
                                )
                                .amount /
                            5000)
                        .clamp(0.05, 1.0),
                onSend: () => context.push('/wallet/send'),
                onReceive: () => context.push('/wallet/receive'),
                onConvert: () => context.push('/wallet/exchange'),
                onScanPay: () => context.push('/wallet/scan'),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'FX board',
              dense: true,
              action: 'Open vault',
              onAction: () => context.push('/forex-live'),
            ),
          ),
          SliverToBoxAdapter(
            child: GestureDetector(
              onTap: () => context.push('/forex-live'),
              behavior: HitTestBehavior.opaque,
              child: const FxTickerPremium(
              ticks: [
                FxTick(pair: 'USD/JPY', rate: 156.42, changePercent: 0.34),
                FxTick(pair: 'EUR/USD', rate: 1.0892, changePercent: -0.12),
                FxTick(pair: 'GBP/USD', rate: 1.2624, changePercent: 0.08),
                FxTick(pair: 'USD/SGD', rate: 1.3411, changePercent: -0.05),
                FxTick(pair: 'USD/AED', rate: 3.6725, changePercent: 0.01),
                FxTick(pair: 'USD/INR', rate: 83.21, changePercent: 0.21),
              ],
            ),
            ),
          ),
          // ── Live alive surfaces ─────────────────────────────
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Live wallet',
              dense: true,
              action: 'Open hub',
              onAction: () => context.push('/live'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space5),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                height: 76,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final items = const [
                      (label: 'Live forex', icon: Icons.currency_exchange_rounded, tone: Color(0xFF10B981), route: '/forex-live'),
                      (label: 'Transit', icon: Icons.nfc_rounded, tone: Color(0xFF8B5CF6), route: '/transit-passes-live'),
                      (label: 'Live trip', icon: Icons.timeline_rounded, tone: Color(0xFF6366F1), route: '/trip-timeline-live'),
                      (label: 'All alive', icon: Icons.auto_awesome_rounded, tone: Color(0xFFC9A961), route: '/live'),
                    ];
                    final it = items[i];
                    return GestureDetector(
                      onTap: () => context.push(it.route),
                      child: Container(
                        width: 132,
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              it.tone.withValues(alpha: 0.20),
                              it.tone.withValues(alpha: 0.04),
                            ],
                          ),
                          border: Border.all(
                            color: it.tone.withValues(alpha: 0.32),
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(it.icon, color: it.tone, size: 20),
                            const Spacer(),
                            Text(
                              it.label.toUpperCase(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: const SectionHeader(title: 'Passes', dense: true),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space5,
              vertical: AppTokens.space2,
            ),
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
              child: _BalancesGrid(balances: wallet.balances),
            ),
          ),
          // ── FX ticker ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: const SectionHeader(title: 'Exchange rates', dense: true),
          ),
          SliverToBoxAdapter(
            child: WalletFxTicker(
              pairs: FxPair.demo(),
              onTap: (_) => context.push('/forex-live'),
            ),
          ),
          // ── Spending analytics ─────────────────────────────
          SliverToBoxAdapter(
            child: const SectionHeader(title: 'Spending', dense: true),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space5),
            sliver: SliverToBoxAdapter(
              child: ContextualSurface(
                child: PremiumSparkline(
                  values: _spendingTrend(),
                  label: 'Last 30 days',
                  delta: -3.4,
                  height: 64,
                ),
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.only(top: AppTokens.space2),
            sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space5),
            sliver: SliverToBoxAdapter(
              child: SpendingChart(categories: SpendCategory.demo()),
            ),
          ),
          SliverToBoxAdapter(
            child: const SectionHeader(title: 'Recent transactions'),
          ),
          if (wallet.transactions.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Os2EmptyState(
                eyebrow: 'WALLET · LEDGER',
                title: 'No transactions yet',
                message:
                    'Scan a receipt or record a payment and it will appear here, signed, timestamped, and tied back to your trip.',
                icon: Icons.receipt_long_rounded,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.space5,
                0,
                AppTokens.space5,
                AppTokens.space9 + 16,
              ),
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

  /// Deterministic 30-day spending series. Uses identity-stable
  /// arithmetic so the chart always renders the same shape across
  /// session restarts.
  List<double> _spendingTrend() {
    const base = 84.0;
    return [
      for (var i = 0; i < 30; i++)
        base +
            math.sin(i * 0.42).abs() * 12 +
            ((i * 7) % 9) * 1.4 -
            ((i * 3) % 5) * 1.1,
    ];
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
          Icon(
            Icons.confirmation_number_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
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

class _PassStackState extends State<_PassStack>
    with SingleTickerProviderStateMixin {
  late final PageController _ctrl = PageController(viewportFraction: 0.90);
  double _page = 0;
  bool _fanOpen = false;
  late final AnimationController _fan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 540),
  );
  StreamSubscription<AccelerometerEvent>? _accelSub;
  double _tiltX = 0;
  double _tiltY = 0;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      if (!mounted) return;
      setState(() => _page = _ctrl.page ?? _page);
    });
    _accelSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen((e) {
      if (!mounted) return;
      final tx = (e.y.clamp(-3, 3) / 3) * (math.pi / 36);
      final ty = (e.x.clamp(-3, 3) / 3) * (math.pi / 36);
      setState(() {
        _tiltX = _tiltX * 0.78 + tx * 0.22;
        _tiltY = _tiltY * 0.78 + ty * 0.22;
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _fan.dispose();
    _accelSub?.cancel();
    super.dispose();
  }

  void _toggleFan() {
    HapticFeedback.mediumImpact();
    if (_fanOpen) {
      _fan.reverse();
    } else {
      _fan.forward();
    }
    setState(() => _fanOpen = !_fanOpen);
  }

  @override
  Widget build(BuildContext context) {
    final current = _page.round().clamp(0, widget.passes.length - 1);
    final accent = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        GestureDetector(
          onLongPress: _toggleFan,
          child: SizedBox(
            height: 292,
            child: LayoutBuilder(
              builder: (context, c) {
                return AnimatedBuilder(
                  animation: _fan,
                  builder: (_, __) {
                    final f = Curves.easeOutCubic.transform(_fan.value);
                    return Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        if (f > 0.001)
                          for (var i = 0; i < widget.passes.length; i++)
                            _FanLayer(
                              pass: widget.passes[i],
                              indexFromActive: i - current,
                              fan: f,
                              width: c.maxWidth,
                              tiltX: _tiltX,
                              tiltY: _tiltY,
                            ),
                        Opacity(
                          opacity: 1 - f,
                          child: IgnorePointer(
                            ignoring: _fanOpen,
                            child: Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                for (var depth = 2; depth >= 1; depth--)
                                  if (current + depth < widget.passes.length)
                                    _PeekPassLayer(
                                      pass: widget.passes[current + depth],
                                      depth: depth,
                                      width: c.maxWidth,
                                    ),
                                Positioned.fill(
                                  top: 0,
                                  child: PageView.builder(
                                    controller: _ctrl,
                                    clipBehavior: Clip.none,
                                    itemCount: widget.passes.length,
                                    itemBuilder: (context, i) {
                                      final delta = (_page - i).abs();
                                      final scale = (1 - (delta * 0.065))
                                          .clamp(0.86, 1.0);
                                      final opacity =
                                          (1 - (delta * 0.34)).clamp(0.42, 1.0);
                                      final y = (delta * 12).clamp(0.0, 22.0);
                                      final isActive = delta < 0.5;
                                      return Transform.translate(
                                        offset: Offset(0, y),
                                        child: Transform.scale(
                                          scale: scale,
                                          alignment: Alignment.topCenter,
                                          child: Opacity(
                                            opacity: opacity,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: AppTokens.space2,
                                              ),
                                              child: Pressable(
                                                scale: 0.985,
                                                onTap: () {
                                                  HapticFeedback.lightImpact();
                                                  GoRouter.of(context).push(
                                                    '/pass/${widget.passes[i].id}',
                                                  );
                                                },
                                                child: Transform(
                                                  alignment: Alignment.center,
                                                  transform: Matrix4.identity()
                                                    ..setEntry(3, 2, 0.0014)
                                                    ..rotateX(
                                                      isActive ? _tiltX : 0,
                                                    )
                                                    ..rotateY(
                                                      isActive ? _tiltY : 0,
                                                    ),
                                                  child: Hero(
                                                    tag:
                                                        'pass-${widget.passes[i].id}',
                                                    child: Material(
                                                      type: MaterialType
                                                          .transparency,
                                                      child: PassCard(
                                                        pass: widget.passes[i],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_fanOpen)
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: _toggleFan,
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
        if (widget.passes.length > 1) ...[
          const SizedBox(height: AppTokens.space1),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PageDots(count: widget.passes.length, page: _page),
              const SizedBox(width: AppTokens.space3),
              GestureDetector(
                onTap: _toggleFan,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: accent.withValues(alpha: 0.32),
                    ),
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _fanOpen
                            ? Icons.layers_clear_rounded
                            : Icons.style_rounded,
                        size: 14,
                        color: accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _fanOpen ? 'Stack' : 'Fan',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Single layer in fan-out mode. Position + rotation interpolated by
/// the parent's `fan` controller (0 = stacked center, 1 = fully fanned).
class _FanLayer extends StatelessWidget {
  const _FanLayer({
    required this.pass,
    required this.indexFromActive,
    required this.fan,
    required this.width,
    required this.tiltX,
    required this.tiltY,
  });
  final TravelDocument pass;
  final int indexFromActive;
  final double fan;
  final double width;
  final double tiltX;
  final double tiltY;

  @override
  Widget build(BuildContext context) {
    final angle = (indexFromActive * 12 * math.pi / 180) * fan;
    final dx = indexFromActive * (width * 0.22) * fan;
    final dy = (indexFromActive.abs() * 14.0) * fan;
    final cardWidth = width * 0.86;
    return Positioned(
      top: 0,
      width: cardWidth,
      child: IgnorePointer(
        ignoring: fan < 0.5,
        child: Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.rotate(
            angle: angle,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0014)
                ..rotateX(tiltX)
                ..rotateY(tiltY),
              child: Pressable(
                scale: 0.97,
                onTap: () {
                  HapticFeedback.lightImpact();
                  GoRouter.of(context).push('/pass/${pass.id}');
                },
                child: Material(
                  type: MaterialType.transparency,
                  child: PassCard(pass: pass),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PeekPassLayer extends StatelessWidget {
  const _PeekPassLayer({
    required this.pass,
    required this.depth,
    required this.width,
  });

  final TravelDocument pass;
  final int depth;
  final double width;

  @override
  Widget build(BuildContext context) {
    final scale = 1 - depth * 0.045;
    final top = 24.0 + depth * 22.0;
    return Positioned(
      top: top,
      width: width * 0.86,
      child: IgnorePointer(
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          child: Opacity(
            opacity: 0.30 - depth * 0.07,
            child: PassCard(pass: pass),
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.page});
  final int count;
  final double page;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final dist = (page - i).abs().clamp(0.0, 1.0);
        final size = 6.0 + (1 - dist) * 4.0;
        final opacity = 0.30 + (1 - dist) * 0.70;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: size,
          height: 6,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          ),
        );
      }),
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
  // Wrapped in `handleError` so platforms without an accelerometer
  // (desktop, web, some emulators) silently fall back to flat instead
  // of spamming uncaught errors.
  late final Stream<AccelerometerEvent> _stream = accelerometerEventStream(
    samplingPeriod: const Duration(milliseconds: 50),
  ).handleError((_) {});

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
                      Text(
                        pass.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
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
                      Icon(
                        Icons.flight,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      const Spacer(),
                      Text(
                        pass.countryFlag,
                        style: const TextStyle(fontSize: 32),
                      ),
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
                        child: _PassMeta(label: 'Status', value: pass.status),
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
    return Text(
      code,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
      ),
    );
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
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
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
                'No balances yet — convert from your default currency to begin.',
              ),
            ),
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

  /// Deterministic mini-trend derived from the currency code so each
  /// balance gets a stable, distinct sparkline shape without needing a
  /// real history series from the backend.
  List<num> _trend() {
    final seed = b.currency.codeUnits.fold<int>(0, (a, c) => a + c) +
        (b.rate * 10).round();
    final out = <double>[];
    var v = 1.0;
    for (var i = 0; i < 14; i++) {
      final n = ((seed + i * 17) % 23) / 23 - 0.5;
      v = (v + n * 0.18).clamp(0.4, 1.6);
      out.add(v);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return GlassSurface(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space4,
        vertical: AppTokens.space3,
      ),
      child: Row(
        children: [
          Text(b.flag, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.currency,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Rate ${b.rate.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Sparkline(values: _trend(), color: accent, height: 28),
          ),
          const SizedBox(width: AppTokens.space2),
          AnimatedNumber(
            value: b.amount,
            prefix: b.symbol,
            decimals: 2,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
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
          horizontal: AppTokens.space4,
          vertical: AppTokens.space3,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              ),
              child: Icon(
                _iconForCategory(tx.category),
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.description, style: theme.textTheme.titleSmall),
                  Text(
                    '${tx.merchant ?? tx.category} · ${tx.date}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              '${isCredit ? '+' : '−'}${tx.amount.abs().toStringAsFixed(2)} ${tx.currency}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showAppleSheet<void>(
      context: context,
      eyebrow: 'WALLET · ${tx.category.toUpperCase()}',
      title: tx.description,
      detents: const [0.48, 0.62, 0.92],
      builder: (controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space5,
          AppTokens.space2,
          AppTokens.space5,
          AppTokens.space5,
        ),
        children: [
          _TxDetailSheet(tx: tx, iconFor: _iconForCategory),
        ],
      ),
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
    // AppleSheet already paints the drag handle, gold hairline,
    // eyebrow, title, and OLED substrate — this widget only
    // renders the wallet transaction body.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                child: Icon(
                  iconFor(tx.category),
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.description,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      tx.merchant ?? tx.category,
                      style: theme.textTheme.bodySmall,
                    ),
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
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.06,
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
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
                      boxShadow: AppTokens.shadowMd(
                        tint: theme.colorScheme.primary,
                      ),
                    ),
                    child: const Text(
                      'Re-tag',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
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
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
