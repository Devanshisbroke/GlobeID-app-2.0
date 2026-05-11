import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../bible_tokens.dart';
import '../bible_typography.dart';
import '../chrome/bible_pressable.dart';
import '../chrome/bible_premium_card.dart';
import '../chrome/bible_scaffold.dart';
import '../chrome/bible_widgets.dart';
import '../materials/bible_glass.dart';

/// GlobeID — **Wallet** (§11.5 _The Multi-Currency Pour_).
///
/// Registers: Stillness → Activation when a pour is in progress.
/// Spine: Wallet.
///
/// Five glass cylinders, one per currency. Each holds a column of
/// "liquid" tinted in its currency tone. Dragging from one cylinder
/// onto another initiates a Pour: the source level drops, the target
/// rises, a soft sloshing animation plays, a Solari display ticks the
/// FX rate.
///
/// Below the cylinders: a 30-day spend sparkline + a recent-flows list.
class BibleWalletScreen extends StatefulWidget {
  const BibleWalletScreen({super.key});

  @override
  State<BibleWalletScreen> createState() => _BibleWalletScreenState();
}

class _BibleWalletScreenState extends State<BibleWalletScreen>
    with SingleTickerProviderStateMixin {
  // Cylinder state: balances 0..1 (visual fill).
  final List<_Cylinder> _cylinders = [
    _Cylinder('EUR', '€ 12,418', 0.74, B.treasuryGreen),
    _Cylinder('JPY', '¥ 1,841,002', 0.66, B.foilGold),
    _Cylinder('USD', '\$ 8,210', 0.42, B.waxCrimson),
    _Cylinder('GBP', '£ 4,915', 0.58, B.polarBlue),
    _Cylinder('AED', 'د.إ 24,510', 0.30, B.honeyAmber),
  ];

  int? _pouringFrom;
  int? _pouringTo;
  late final AnimationController _pourCtrl;

  @override
  void initState() {
    super.initState();
    _pourCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void dispose() {
    _pourCtrl.dispose();
    super.dispose();
  }

  Future<void> _startPour(int from, int to) async {
    if (from == to) return;
    setState(() {
      _pouringFrom = from;
      _pouringTo = to;
    });
    HapticFeedback.mediumImpact();
    _pourCtrl.forward(from: 0);
    await _pourCtrl.animateTo(1.0, curve: B.bank);
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() {
      _cylinders[from].level = (_cylinders[from].level - 0.12).clamp(0.0, 1.0);
      _cylinders[to].level = (_cylinders[to].level + 0.12).clamp(0.0, 1.0);
      _pouringFrom = null;
      _pouringTo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BiblePageScaffold(
      emotion: _pouringFrom != null ? BEmotion.activation : BEmotion.stillness,
      tone: B.treasuryGreen.withValues(alpha: 0.06),
      density: BDensity.concourse,
      eyebrow: '— wallet · multi-currency vault —',
      title: 'Treasury',
      trailing: const BibleStatusPill(
        label: 'sealed',
        tone: B.foilGold,
        dense: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NetWorthHeader(),
          const SizedBox(height: B.space5),
          SizedBox(
            height: 280,
            child: _PourBoard(
              cylinders: _cylinders,
              pouringFrom: _pouringFrom,
              pouringTo: _pouringTo,
              pourProgress: _pourCtrl,
              onPour: _startPour,
            ),
          ),
          const SizedBox(height: B.space5),
          const BibleSectionHeader(
            eyebrow: 'fx board',
            title: 'Live rates',
          ),
          _FxBoard(),
          const SizedBox(height: B.space5),
          const BibleSectionHeader(
            eyebrow: 'last 30 days',
            title: 'Spend rhythm',
          ),
          _SpendRhythm(),
          const SizedBox(height: B.space5),
          const BibleSectionHeader(
            eyebrow: 'recent flows',
            title: 'Ledger',
          ),
          ..._dummyFlows,
          const SizedBox(height: B.space6),
        ],
      ),
    );
  }
}

class _Cylinder {
  _Cylinder(this.symbol, this.balance, this.level, this.tone);
  final String symbol;
  final String balance;
  double level;
  final Color tone;
}

class _NetWorthHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BiblePremiumCard(
      tone: B.treasuryGreen,
      padding: const EdgeInsets.all(B.space4),
      child: Row(
        children: [
          BibleGlyphHalo(
            icon: Icons.account_balance_wallet_rounded,
            tone: B.treasuryGreen,
            size: 48,
          ),
          const SizedBox(width: B.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BText.eyebrow('net worth · GBP equivalent',
                    color: B.treasuryGreen),
                const SizedBox(height: B.space1),
                BText.solari(
                  '£ 42,140.18',
                  size: 28,
                  color: B.inkOnDarkHigh,
                ),
                const SizedBox(height: B.space1),
                BText.caption('+ £ 318.40 today · +0.76 %',
                    color: B.inkOnDarkMid),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PourBoard extends StatelessWidget {
  const _PourBoard({
    required this.cylinders,
    required this.pouringFrom,
    required this.pouringTo,
    required this.pourProgress,
    required this.onPour,
  });
  final List<_Cylinder> cylinders;
  final int? pouringFrom;
  final int? pouringTo;
  final AnimationController pourProgress;
  final void Function(int from, int to) onPour;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < cylinders.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: B.space1),
              child: LongPressDraggable<int>(
                data: i,
                feedback: const SizedBox.shrink(),
                child: DragTarget<int>(
                  onAcceptWithDetails: (details) =>
                      onPour(details.data, i),
                  builder: (_, __, ___) => _GlassCylinder(
                    cylinder: cylinders[i],
                    pouring: pouringFrom == i || pouringTo == i,
                    progress: pourProgress,
                    isSource: pouringFrom == i,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GlassCylinder extends StatelessWidget {
  const _GlassCylinder({
    required this.cylinder,
    required this.pouring,
    required this.progress,
    required this.isSource,
  });
  final _Cylinder cylinder;
  final bool pouring;
  final AnimationController progress;
  final bool isSource;

  @override
  Widget build(BuildContext context) {
    return BibleGlass(
      radius: 18,
      padding: EdgeInsets.zero,
      tint: Colors.white.withValues(alpha: 0.05),
      blurSigma: 10,
      child: AnimatedBuilder(
        animation: progress,
        builder: (_, __) {
          final p = progress.value;
          var level = cylinder.level;
          if (pouring && isSource) level -= 0.12 * p;
          if (pouring && !isSource) level += 0.12 * p;
          level = level.clamp(0.0, 1.0);
          return LayoutBuilder(
            builder: (_, c) {
              return Stack(
                children: [
                  // Liquid fill
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: c.maxHeight * level,
                    child: _LiquidFill(tone: cylinder.tone),
                  ),
                  // Specular hairlines (vertical glass reflection)
                  Positioned(
                    left: 6,
                    top: 8,
                    bottom: 8,
                    width: 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Colors.white.withValues(alpha: 0.20),
                      ),
                    ),
                  ),
                  // Labels
                  Positioned(
                    top: B.space2,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        BText.eyebrow(cylinder.symbol, color: cylinder.tone),
                        const SizedBox(height: B.space1),
                        BText.mono(
                          cylinder.balance,
                          color: B.inkOnDarkHigh,
                          size: 11,
                        ),
                      ],
                    ),
                  ),
                  // Pouring spout indicator
                  if (pouring && isSource)
                    Positioned(
                      top: 60,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: cylinder.tone.withValues(alpha: 0.7),
                            boxShadow: [
                              BoxShadow(
                                color: cylinder.tone.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _LiquidFill extends StatelessWidget {
  const _LiquidFill({required this.tone});
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1100),
      curve: B.bank,
      builder: (_, t, __) {
        return CustomPaint(
          size: Size.infinite,
          painter: _LiquidPainter(tone: tone, phase: t),
        );
      },
    );
  }
}

class _LiquidPainter extends CustomPainter {
  _LiquidPainter({required this.tone, required this.phase});
  final Color tone;
  final double phase;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          tone.withValues(alpha: 0.60),
          tone.withValues(alpha: 0.85),
        ],
      ).createShader(Offset.zero & size);
    final path = Path();
    final wave = 4 + 1.5 * math.sin(phase * 2 * math.pi);
    path.moveTo(0, wave);
    for (var x = 0.0; x <= size.width; x += 4) {
      final y = wave + math.sin((x / size.width * 4 + phase) * 2 * math.pi) * 1.6;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter old) =>
      old.tone != tone || old.phase != phase;
}

class _FxBoard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const rows = <_FxRow>[
      _FxRow(pair: 'EUR / GBP', mid: '0.8482', delta: '+0.21%', tone: B.treasuryGreen),
      _FxRow(pair: 'USD / GBP', mid: '0.7891', delta: '−0.09%', tone: B.waxCrimson),
      _FxRow(pair: 'JPY / GBP', mid: '0.0052', delta: '+0.04%', tone: B.foilGold),
      _FxRow(pair: 'AED / GBP', mid: '0.2148', delta: '+0.11%', tone: B.honeyAmber),
    ];
    return BiblePremiumCard(
      tone: B.foilGold,
      padding: const EdgeInsets.all(B.space3),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1) const BibleDivider(),
          ],
        ],
      ),
    );
  }
}

class _FxRow extends StatelessWidget {
  const _FxRow({
    required this.pair,
    required this.mid,
    required this.delta,
    required this.tone,
  });
  final String pair;
  final String mid;
  final String delta;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: B.space2),
      child: Row(
        children: [
          BText.monoCap(pair, color: tone),
          const Spacer(),
          BText.mono(mid, color: B.inkOnDarkHigh, size: 14),
          const SizedBox(width: B.space3),
          BText.mono(delta, color: tone, size: 12),
        ],
      ),
    );
  }
}

class _SpendRhythm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BiblePremiumCard(
      tone: B.treasuryGreen,
      padding: const EdgeInsets.all(B.space4),
      child: Column(
        children: [
          BibleSparkline(
            values: const [
              3, 5, 4, 6, 8, 5, 7, 9, 6, 8, 12, 9, 11, 13, 10, 9, 8, 11,
              10, 12, 11, 13, 10, 12, 14, 11, 9, 12, 14, 10,
            ].map((e) => e.toDouble()).toList(),
            tone: B.treasuryGreen,
            height: 96,
            strokeWidth: 2.4,
          ),
          const SizedBox(height: B.space3),
          BibleInfoRail(
            entries: const [
              BibleInfoEntry(
                icon: Icons.savings_rounded,
                label: 'spent',
                value: '£ 1,820',
                tone: B.treasuryGreen,
              ),
              BibleInfoEntry(
                icon: Icons.compare_arrows_rounded,
                label: 'converted',
                value: '£ 642',
                tone: B.foilGold,
              ),
              BibleInfoEntry(
                icon: Icons.flight_rounded,
                label: 'travel',
                value: '£ 1,142',
                tone: B.jetCyan,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const _dummyFlows = <_FlowRow>[
  _FlowRow(
    where: 'TANIYA HARUMI · TOKYO',
    when: 'Just now',
    amount: '−¥ 11,200',
    tone: B.foilGold,
    icon: Icons.restaurant_rounded,
  ),
  _FlowRow(
    where: 'ANA · BOARDING DEPOSIT',
    when: '2h ago',
    amount: '−£ 280',
    tone: B.jetCyan,
    icon: Icons.flight_rounded,
  ),
  _FlowRow(
    where: 'SCHWAB INTL TRANSFER',
    when: 'Yesterday',
    amount: '+\$ 4,210',
    tone: B.treasuryGreen,
    icon: Icons.savings_rounded,
  ),
  _FlowRow(
    where: 'HOTEL LE ROYAL · LISBOA',
    when: 'Mar 02',
    amount: '−€ 612',
    tone: B.honeyAmber,
    icon: Icons.hotel_rounded,
  ),
];

class _FlowRow extends StatelessWidget {
  const _FlowRow({
    required this.where,
    required this.when,
    required this.amount,
    required this.tone,
    required this.icon,
  });
  final String where;
  final String when;
  final String amount;
  final Color tone;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return BiblePressable(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: B.space1),
        padding: const EdgeInsets.symmetric(
          horizontal: B.space3,
          vertical: B.space3,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(B.rTile),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: B.hairlineLightSoft, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: tone),
            const SizedBox(width: B.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BText.mono(where, color: B.inkOnDarkHigh, size: 12),
                  BText.caption(when, color: B.inkOnDarkLow),
                ],
              ),
            ),
            BText.mono(amount, color: tone, size: 14),
          ],
        ),
      ),
    );
  }
}
