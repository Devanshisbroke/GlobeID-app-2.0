import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';

// ═══════════════════════════════════════════════════════════════════
// TRIP WALLET SCREEN — per-trip spending envelope
//
// Auto-spawned per trip. Spend grouped by category. Post-trip freeze.
// Pre-trip tagged "preparation". Concentric budget ring + category cards.
// ═══════════════════════════════════════════════════════════════════

class TripWalletScreen extends ConsumerStatefulWidget {
  const TripWalletScreen({super.key, this.tripName});
  final String? tripName;
  @override
  ConsumerState<TripWalletScreen> createState() => _TripWalletScreenState();
}

class _TripWalletScreenState extends ConsumerState<TripWalletScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ring;
  final _categories = _demoCategories();
  double _totalBudget = 2000;
  bool _taxMode = false;

  @override
  void initState() {
    super.initState();
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  double get _totalSpent =>
      _categories.fold(0.0, (sum, c) => sum + c.spent);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spent = _totalSpent;
    final pct = (_totalBudget > 0) ? (spent / _totalBudget).clamp(0.0, 1.0) : 0.0;

    return PageScaffold(
      title: widget.tripName ?? 'Trip Wallet',
      subtitle: 'Spending envelope',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppTokens.space5, 0, AppTokens.space5, AppTokens.space9),
        children: [
          // ── Budget ring hero ─────────────────────────────────
          AnimatedAppearance(
            child: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: AnimatedBuilder(
                  animation: _ring,
                  builder: (_, __) {
                    final animPct = pct * _ring.value;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(200, 200),
                          painter: _BudgetRingPainter(
                            progress: animPct,
                            categories: _categories,
                            animProgress: _ring.value,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '€${spent.toStringAsFixed(0)}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                            Text(
                              'of €${_totalBudget.toStringAsFixed(0)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(AppTokens.radiusFull),
                                color: _budgetColor(pct).withValues(alpha: 0.15),
                              ),
                              child: Text(
                                '${(pct * 100).toStringAsFixed(0)}% used',
                                style: TextStyle(
                                  color: _budgetColor(pct),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: AppTokens.space4),

          // ── Tax mode + budget adjust strip ───────────────────
          AnimatedAppearance(
            delay: const Duration(milliseconds: 80),
            child: Row(
              children: [
                Expanded(
                  child: GlassSurface(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.space3, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.receipt_long_rounded,
                            color: _taxMode
                                ? const Color(0xFF22C55E)
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                            size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tax Mode',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Switch.adaptive(
                          value: _taxMode,
                          onChanged: (v) {
                            HapticFeedback.selectionClick();
                            setState(() => _taxMode = v);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Pressable(
                  scale: 0.95,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showBudgetPicker(context);
                  },
                  child: GlassSurface(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.space3, vertical: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune_rounded,
                            size: 16,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text('Budget',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTokens.space5),

          // ── Category breakdown ───────────────────────────────
          AnimatedAppearance(
            delay: const Duration(milliseconds: 120),
            child: Text(
              'SPENDING BY CATEGORY',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space3),
          for (var i = 0; i < _categories.length; i++)
            AnimatedAppearance(
              delay: Duration(milliseconds: 160 + i * 50),
              child: _CategoryRow(
                cat: _categories[i],
                total: spent,
                taxMode: _taxMode,
              ),
            ),

          const SizedBox(height: AppTokens.space5),

          // ── Recent transactions ──────────────────────────────
          AnimatedAppearance(
            delay: const Duration(milliseconds: 400),
            child: Text(
              'RECENT TRANSACTIONS',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space3),
          for (var i = 0; i < _demoTransactions.length; i++)
            AnimatedAppearance(
              delay: Duration(milliseconds: 440 + i * 40),
              child: _TransactionRow(tx: _demoTransactions[i]),
            ),

          const SizedBox(height: AppTokens.space5),

          // ── Insights strip ───────────────────────────────────
          AnimatedAppearance(
            delay: const Duration(milliseconds: 600),
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          color: Color(0xFF8B5CF6), size: 18),
                      const SizedBox(width: 6),
                      Text('Trip Insights',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space3),
                  _InsightTile(
                    icon: Icons.restaurant_rounded,
                    color: const Color(0xFFEF4444),
                    text: 'Food spending is 2.3× your daily average',
                  ),
                  _InsightTile(
                    icon: Icons.trending_down_rounded,
                    color: const Color(0xFF22C55E),
                    text: 'Transport costs are 40% below budget',
                  ),
                  _InsightTile(
                    icon: Icons.eco_rounded,
                    color: const Color(0xFF14B8A6),
                    text: 'Carbon footprint: ~142 kg CO₂ (flights + rides)',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBudgetPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTokens.radiusXl)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppTokens.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set Trip Budget',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppTokens.space4),
            StatefulBuilder(builder: (ctx, setLocal) {
              return Column(
                children: [
                  Text('€${_totalBudget.toStringAsFixed(0)}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  Slider.adaptive(
                    value: _totalBudget,
                    min: 200,
                    max: 10000,
                    divisions: 98,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setLocal(() {});
                      setState(() => _totalBudget = v);
                    },
                  ),
                ],
              );
            }),
            const SizedBox(height: AppTokens.space4),
          ],
        ),
      ),
    );
  }

  Color _budgetColor(double pct) {
    if (pct > 0.9) return const Color(0xFFEF4444);
    if (pct > 0.7) return const Color(0xFFF59E0B);
    return const Color(0xFF22C55E);
  }
}

// ── Budget ring painter ───────────────────────────────────────────
class _BudgetRingPainter extends CustomPainter {
  _BudgetRingPainter({
    required this.progress,
    required this.categories,
    required this.animProgress,
  });
  final double progress;
  final List<_SpendCategory> categories;
  final double animProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 16;
    const strokeWidth = 14.0;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0x0DFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Category arcs
    final total = categories.fold(0.0, (s, c) => s + c.spent);
    if (total <= 0) return;

    var startAngle = -math.pi / 2;
    for (final cat in categories) {
      final sweep = (cat.spent / total) * progress * math.pi * 2 * animProgress;
      if (sweep <= 0) continue;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        Paint()
          ..color = cat.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      startAngle += sweep + 0.04; // tiny gap
    }
  }

  @override
  bool shouldRepaint(covariant _BudgetRingPainter old) =>
      old.progress != progress || old.animProgress != animProgress;
}

// ── Category row ──────────────────────────────────────────────────
class _CategoryRow extends StatelessWidget {
  const _CategoryRow(
      {required this.cat, required this.total, required this.taxMode});
  final _SpendCategory cat;
  final double total;
  final bool taxMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = total > 0 ? cat.spent / total : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space3),
      child: GlassSurface(
        padding: const EdgeInsets.all(AppTokens.space3),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                color: cat.color.withValues(alpha: 0.15),
              ),
              child: Icon(cat.icon, color: cat.color, size: 18),
            ),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(cat.name,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '€${cat.spent.toStringAsFixed(0)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                          if (taxMode) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: const Color(0xFF22C55E)
                                    .withValues(alpha: 0.12),
                              ),
                              child: const Text('TAX',
                                  style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF22C55E))),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: pct),
                      duration: const Duration(milliseconds: 1200),
                      curve: AppTokens.easeOutSoft,
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        backgroundColor: theme.colorScheme.onSurface
                            .withValues(alpha: 0.06),
                        valueColor: AlwaysStoppedAnimation(cat.color),
                        minHeight: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Transaction row ───────────────────────────────────────────────
class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.tx});
  final _Transaction tx;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Pressable(
        scale: 0.98,
        onTap: () => HapticFeedback.selectionClick(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: AppTokens.space2, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                  color: tx.color.withValues(alpha: 0.12),
                ),
                child: Icon(tx.icon, color: tx.color, size: 16),
              ),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.merchant,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(tx.time,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4))),
                  ],
                ),
              ),
              Text(
                '-€${tx.amount.toStringAsFixed(2)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFEF4444),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Insight tile ──────────────────────────────────────────────────
class _InsightTile extends StatelessWidget {
  const _InsightTile(
      {required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7))),
          ),
        ],
      ),
    );
  }
}

// ── Demo data ─────────────────────────────────────────────────────
class _SpendCategory {
  const _SpendCategory(this.name, this.icon, this.color, this.spent);
  final String name;
  final IconData icon;
  final Color color;
  final double spent;
}

class _Transaction {
  const _Transaction(this.merchant, this.time, this.amount, this.icon, this.color);
  final String merchant, time;
  final double amount;
  final IconData icon;
  final Color color;
}

List<_SpendCategory> _demoCategories() => const [
      _SpendCategory(
          'Flights', Icons.flight_rounded, Color(0xFF0EA5E9), 680),
      _SpendCategory('Hotels', Icons.hotel_rounded, Color(0xFF8B5CF6), 420),
      _SpendCategory(
          'Food & Dining', Icons.restaurant_rounded, Color(0xFFEF4444), 310),
      _SpendCategory(
          'Transport', Icons.directions_car_rounded, Color(0xFFF59E0B), 145),
      _SpendCategory(
          'Shopping', Icons.shopping_bag_rounded, Color(0xFFEC4899), 88),
      _SpendCategory(
          'Activities', Icons.confirmation_number_rounded, Color(0xFF14B8A6), 64),
    ];

const _demoTransactions = [
  _Transaction('Sushi Zanmai', 'Today 13:42', 34.50, Icons.restaurant_rounded,
      Color(0xFFEF4444)),
  _Transaction('Metro Day Pass', 'Today 09:15', 8.20,
      Icons.directions_subway_rounded, Color(0xFFF59E0B)),
  _Transaction(
      'Lawson Konbini', 'Today 08:30', 5.80, Icons.store_rounded, Color(0xFF22C55E)),
  _Transaction('Uber to Shibuya', 'Yesterday 22:10', 12.40,
      Icons.local_taxi_rounded, Color(0xFF0EA5E9)),
  _Transaction('TeamLab Planets', 'Yesterday 14:00', 25.00,
      Icons.confirmation_number_rounded, Color(0xFF14B8A6)),
  _Transaction('Uniqlo Ginza', 'Yesterday 11:20', 42.80,
      Icons.shopping_bag_rounded, Color(0xFFEC4899)),
  _Transaction('Hotel Gracery', '2 days ago', 180.00, Icons.hotel_rounded,
      Color(0xFF8B5CF6)),
];
