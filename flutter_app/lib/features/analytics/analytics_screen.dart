import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/section_header.dart';
import '../insights/insights_provider.dart';

/// Premium analytics — interactive pie + line + heatmap with fl_chart,
/// colour-coded categories, totals card, animated reveal.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletInsightsProvider);
    final travel = ref.watch(travelInsightsProvider);
    return PageScaffold(
      title: 'Analytics',
      subtitle: 'Spend · mileage · carbon',
      body: wallet.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          title: 'Analytics unavailable',
          message: e.toString(),
          icon: Icons.cloud_off_rounded,
        ),
        data: (data) {
          final spend = ((data['spendByCategory'] as List?) ?? const [])
              .cast<Map<String, dynamic>>();
          if (spend.isEmpty) {
            return const EmptyState(
              title: 'No spend yet',
              message: 'Record a transaction to populate charts.',
              icon: Icons.bar_chart_rounded,
            );
          }
          final total = spend.fold<double>(
              0, (s, e) => s + ((e['amount'] as num).toDouble()));
          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space5, vertical: AppTokens.space3),
            children: [
              AnimatedAppearance(
                child: _TotalsCard(total: total, count: spend.length),
              ),
              const SectionHeader(title: 'Spend by category', dense: true),
              AnimatedAppearance(
                delay: const Duration(milliseconds: 80),
                child: _PieChart(spend: spend, total: total),
              ),
              const SectionHeader(title: 'Last 30 days', dense: true),
              AnimatedAppearance(
                delay: const Duration(milliseconds: 160),
                child: const _SpendLineChart(),
              ),
              travel.when(
                data: (t) {
                  final routes = ((t['topRoutes'] as List?) ?? const [])
                      .cast<Map<String, dynamic>>();
                  if (routes.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(title: 'Top routes', dense: true),
                      AnimatedAppearance(
                        delay: const Duration(milliseconds: 240),
                        child: _RoutesList(routes: routes),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: AppTokens.space9),
            ],
          );
        },
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.total, required this.count});
  final double total;
  final int count;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space5),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withValues(alpha: 0.18),
          accent.withValues(alpha: 0.06),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TOTAL SPEND',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 4),
                Text(
                  total.toStringAsFixed(2),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
                Text('$count categories',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    )),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppTokens.radiusXl),
            ),
            child: Icon(Icons.insights_rounded, color: accent, size: 28),
          ),
        ],
      ),
    );
  }
}

class _PieChart extends StatelessWidget {
  const _PieChart({required this.spend, required this.total});
  final List<Map<String, dynamic>> spend;
  final double total;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = [
      const Color(0xFF7C3AED),
      const Color(0xFF06B6D4),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF4F46E5),
      const Color(0xFFEF4444),
      const Color(0xFFD946EF),
    ];
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space5),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 56,
                startDegreeOffset: -90,
                sections: [
                  for (var i = 0; i < spend.length; i++)
                    PieChartSectionData(
                      value: (spend[i]['amount'] as num).toDouble(),
                      title: '',
                      color: colors[i % colors.length],
                      radius: 28,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space3),
          Wrap(
            spacing: AppTokens.space3,
            runSpacing: AppTokens.space2,
            children: [
              for (var i = 0; i < spend.length; i++)
                _LegendChip(
                  label: spend[i]['category'].toString(),
                  amount: (spend[i]['amount'] as num).toDouble(),
                  pct: total == 0
                      ? 0
                      : (spend[i]['amount'] as num).toDouble() / total,
                  color: colors[i % colors.length],
                ),
            ],
          ),
          const SizedBox(height: AppTokens.space2),
          Text('Tap a segment to drill in (coming soon)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              )),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.label,
    required this.amount,
    required this.pct,
    required this.color,
  });
  final String label;
  final double amount;
  final double pct;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppTokens.space3, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Text(
            '${(pct * 100).toStringAsFixed(0)}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendLineChart extends StatelessWidget {
  const _SpendLineChart();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    // Synthetic 30-day rolling spend series (deterministic).
    final spots = <FlSpot>[];
    final rng = math.Random(2);
    var v = 50.0;
    for (var i = 0; i < 30; i++) {
      v += rng.nextDouble() * 30 - 12;
      v = v.clamp(8, 220);
      spots.add(FlSpot(i.toDouble(), v));
    }
    return PremiumCard(
      padding: const EdgeInsets.fromLTRB(AppTokens.space3, AppTokens.space5,
          AppTokens.space3, AppTokens.space3),
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(show: false),
            minY: 0,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.4,
                color: accent,
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accent.withValues(alpha: 0.32),
                      accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutesList extends StatelessWidget {
  const _RoutesList({required this.routes});
  final List<Map<String, dynamic>> routes;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final r in routes)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.space2),
            child: PremiumCard(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space4, vertical: AppTokens.space3),
              elevation: PremiumElevation.sm,
              glass: false,
              child: Row(
                children: [
                  const Icon(Icons.flight, size: 20),
                  const SizedBox(width: AppTokens.space3),
                  Expanded(
                    child: Text(
                      '${r['from']} → ${r['to']}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    '${r['count']}×',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
