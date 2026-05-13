import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cinematic/live/live_primitives.dart';
import '../../cinematic/live/live_substrates.dart';
import '../../data/api/demo_data.dart';
import '../../nexus/nexus_tokens.dart';
import '../wallet/wallet_provider.dart';

/// ForexLive — a cinematic, alive multi-currency forex surface.
///
/// Anatomy:
///
///   • Atmosphere backdrop in jade green (the forex "vault" tone)
///   • Stack of polymer banknotes, one per currency in your wallet:
///       each is rendered through `BanknoteSubstrate` with intaglio
///       engraving, OVI medallion, vertical security thread and
///       serial number.
///   • Banknotes fan out, the active one floats forward (3D), and
///       you can swipe horizontally to cycle through them — each
///       swipe lifts the back card, animates spring-curve motion,
///       and recomputes USD equivalence + spot-rate trend.
///   • Live ticker at the top with FX spot rates (USD/EUR, USD/JPY,
///       USD/INR, USD/GBP, USD/AED) scrolling continuously.
///   • OVI vault seal that rotates colour with the active currency.
///   • Bottom CTAs — "Convert" (opens converter sheet) + "Withdraw".
///
/// Lives at `/forex-live` — falls back to demo balances when the
/// wallet provider has no entries.
class ForexLiveScreen extends ConsumerStatefulWidget {
  const ForexLiveScreen({super.key});

  @override
  ConsumerState<ForexLiveScreen> createState() => _ForexLiveScreenState();
}

class _ForexLiveScreenState extends ConsumerState<ForexLiveScreen>
    with TickerProviderStateMixin {
  late final AnimationController _foil;
  late final AnimationController _flip;
  late final PageController _pages;
  int _index = 0;
  Offset _tilt = Offset.zero;

  @override
  void initState() {
    super.initState();
    _foil = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 540),
    );
    _pages = PageController(viewportFraction: 0.78);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _foil.dispose();
    _flip.dispose();
    _pages.dispose();
    super.dispose();
  }

  List<_Banknote> _seed() {
    final wallet = ref.watch(walletProvider);
    final balances = wallet.balances;
    final fallback = (DemoData.seedWallet()['balances'] as List<dynamic>);
    final list = balances.isNotEmpty
        ? balances
            .map((b) => _Banknote(
                  code: b.currency,
                  symbol: b.symbol,
                  amount: b.amount,
                  flag: b.flag,
                  rate: b.rate,
                  tone: _currencyTone(b.currency),
                ))
            .toList()
        : fallback
            .cast<Map<String, dynamic>>()
            .map((b) => _Banknote(
                  code: b['currency'] as String,
                  symbol: b['symbol'] as String,
                  amount: (b['amount'] as num).toDouble(),
                  flag: b['flag'] as String,
                  rate: (b['rate'] as num).toDouble(),
                  tone: _currencyTone(b['currency'] as String),
                ))
            .toList();
    return list;
  }

  Color _currencyTone(String code) {
    switch (code) {
      case 'USD':
        return const Color(0xFF10B981);
      case 'EUR':
        return const Color(0xFF6366F1);
      case 'GBP':
        return const Color(0xFF7C3AED);
      case 'JPY':
        return const Color(0xFFE11D48);
      case 'INR':
        return const Color(0xFFF59E0B);
      case 'AED':
        return const Color(0xFF14B8A6);
      default:
        return N.tierGold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = _seed();
    final active = notes.isEmpty ? null : notes[_index.clamp(0, notes.length - 1)];
    final activeTone = active?.tone ?? N.tierGold;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: LiveCanvas(
        tone: activeTone,
        statusBar: _ForexHeader(tone: activeTone, notes: notes),
        bottomBar: Row(
          children: [
            Expanded(
              child: LiveCta(
                label: 'Convert',
                icon: Icons.swap_horiz_rounded,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/multi-currency');
                },
              ),
            ),
            const SizedBox(width: N.s3),
            Expanded(
              child: LiveCta(
                label: 'Withdraw',
                icon: Icons.account_balance_rounded,
                secondary: true,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/wallet');
                },
              ),
            ),
          ],
        ),
        child: notes.isEmpty
            ? const Text(
                'No currencies in wallet',
                style: TextStyle(color: Colors.white),
              )
            : Column(
                children: [
                  _TotalsBlock(notes: notes, tone: activeTone),
                  const SizedBox(height: N.s4),
                  Expanded(
                    child: GestureDetector(
                      onPanUpdate: (d) {
                        setState(() {
                          _tilt = Offset(
                            (_tilt.dx + d.delta.dx * 0.02).clamp(-0.5, 0.5),
                            (_tilt.dy + d.delta.dy * 0.02).clamp(-0.5, 0.5),
                          );
                        });
                      },
                      onPanEnd: (_) {
                        setState(() => _tilt = Offset.zero);
                      },
                      child: PageView.builder(
                        controller: _pages,
                        physics: const BouncingScrollPhysics(),
                        itemCount: notes.length,
                        onPageChanged: (i) {
                          setState(() => _index = i);
                          HapticFeedback.selectionClick();
                        },
                        itemBuilder: (_, i) {
                          final note = notes[i];
                          // RepaintBoundary isolates each note card's
                          // page-scroll-driven scale/rotation so the
                          // sibling cards don't repaint at the swipe
                          // cadence.
                          return RepaintBoundary(
                            child: AnimatedBuilder(
                            animation: _pages,
                            builder: (_, child) {
                              double pageValue = i.toDouble();
                              if (_pages.position.haveDimensions) {
                                pageValue = _pages.page ?? i.toDouble();
                              }
                              final delta = (i - pageValue).abs();
                              final scale = (1.0 - delta * 0.12)
                                  .clamp(0.78, 1.0);
                              final rot = (i - pageValue) * 0.18;
                              return Center(
                                child: Transform.scale(
                                  scale: scale,
                                  child: Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()
                                      ..setEntry(3, 2, 0.0014)
                                      ..rotateY(rot),
                                    child: TiltParallax(
                                      tilt: _tilt,
                                      depth: 6,
                                      child: child ?? const SizedBox.shrink(),
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: _BanknoteCard(
                              note: note,
                              foilAnim: _foil,
                            ),
                          ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: N.s4),
                  _Dots(count: notes.length, active: _index, tone: activeTone),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// HEADER + LIVE TICKER
// ─────────────────────────────────────────────────────────────────────

class _ForexHeader extends StatelessWidget {
  const _ForexHeader({required this.tone, required this.notes});
  final Color tone;
  final List<_Banknote> notes;

  @override
  Widget build(BuildContext context) {
    final ticker = notes
        .where((n) => n.code != 'USD')
        .map((n) => 'USD/${n.code} ${n.rate.toStringAsFixed(n.rate < 10 ? 4 : 2)}')
        .toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: N.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 0.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: N.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LIVE FOREX · VAULT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'SPOT RATES · STREAMING',
                      style: TextStyle(
                        color: tone.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                icon: Icons.bolt_rounded,
                label: 'LIVE',
                tone: tone,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
                width: 0.5,
              ),
            ),
            child: LiveTicker(items: ticker, tone: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// TOTALS — USD equivalence + drift
// ─────────────────────────────────────────────────────────────────────

class _TotalsBlock extends StatelessWidget {
  const _TotalsBlock({required this.notes, required this.tone});
  final List<_Banknote> notes;
  final Color tone;

  double get _usdEquivalent {
    var total = 0.0;
    for (final n in notes) {
      total += n.code == 'USD' ? n.amount : n.amount / n.rate;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL · USD EQUIVALENT',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '\$${_usdEquivalent.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 30,
                  letterSpacing: -0.5,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${notes.length} CURRENCIES',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  for (final n in notes.take(6))
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Text(
                        n.flag,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// BANKNOTE CARD
// ─────────────────────────────────────────────────────────────────────

class _Banknote {
  const _Banknote({
    required this.code,
    required this.symbol,
    required this.amount,
    required this.flag,
    required this.rate,
    required this.tone,
  });
  final String code;
  final String symbol;
  final double amount;
  final String flag;
  final double rate;
  final Color tone;
}

class _BanknoteCard extends StatelessWidget {
  const _BanknoteCard({required this.note, required this.foilAnim});
  final _Banknote note;
  final AnimationController foilAnim;

  String get _formatted {
    if (note.code == 'JPY' || note.code == 'INR') {
      return note.amount.toStringAsFixed(0);
    }
    return note.amount.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: AspectRatio(
        aspectRatio: 0.62,
        child: LiveLift(
          tone: note.tone,
          depth: 18,
          child: BanknoteSubstrate(
          tone: note.tone,
          serial: 'GBL · ${note.code} · A${note.amount.toInt().toString().padLeft(6, '0')}',
          child: Stack(
            children: [
              // Foil sweep — only on the active currency. Banknotes
              // get the iridescent preset (ice + amber security ink)
              // so the active note reads as authentic currency.
              Positioned.fill(
                child: HolographicFoil(
                  duration: const Duration(seconds: 5),
                  style: HolographicFoilStyle.iridescent,
                  child: Container(color: Colors.transparent),
                ),
              ),
              // Top-row identity.
              Positioned(
                top: 14,
                left: 18,
                right: 18,
                child: Row(
                  children: [
                    Text(note.flag, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(
                      note.code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      note.symbol,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                      ),
                    ),
                  ],
                ),
              ),
              // Centre denomination — huge tabular figure.
              Positioned(
                top: 0,
                bottom: 0,
                left: 18,
                right: 18,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${note.symbol} $_formatted',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 36,
                          letterSpacing: 0.5,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '@ 1 USD = ${note.rate.toStringAsFixed(note.rate < 10 ? 4 : 2)} ${note.code}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom denomination — corner. Rolls up from 0 on
              // activation so the banknote "comes alive" when the
              // user pins it (Apple-Wallet card-number reveal feel).
              Positioned(
                bottom: 30,
                right: 18,
                child: RollingDigits(
                  key: ValueKey('forex-corner-${note.code}'),
                  target: (note.amount > 1000
                          ? note.amount / 1000
                          : note.amount)
                      .toInt(),
                  digits: 1,
                  suffix: note.amount > 1000 ? 'K' : '',
                  duration: const Duration(milliseconds: 620),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w900,
                    fontSize: 30,
                    letterSpacing: -1.5,
                  ),
                ),
              ),
              // Live state pill — banknote stays in ACTIVE while
              // pinned. Mono-cap glow against the linen substrate.
              const Positioned(
                top: 14,
                left: 90,
                child: LiveStatusPill(state: LiveSurfaceState.active),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active, required this.tone});
  final int count;
  final int active;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == active ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: i == active
                  ? tone.withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.16),
            ),
          ),
      ],
    );
  }
}


