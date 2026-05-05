import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/empty_state.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/section_header.dart';
import '../insights/insights_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletInsightsProvider);
    final theme = Theme.of(context);
    return PageScaffold(
      title: 'Analytics',
      subtitle: 'Spend, mileage, carbon',
      body: wallet.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          title: 'Analytics unavailable',
          message: e.toString(),
          icon: Icons.cloud_off_rounded,
        ),
        data: (data) {
          final spend = (data['spendByCategory'] as List?) ?? const [];
          if (spend.isEmpty) {
            return const EmptyState(
              title: 'No spend yet',
              message: 'Record a transaction to populate charts.',
              icon: Icons.bar_chart_rounded,
            );
          }
          return ListView(
            children: [
              const SectionHeader(title: 'Spend by category', dense: true),
              GlassSurface(
                child: SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        for (var i = 0; i < spend.length; i++)
                          PieChartSectionData(
                            value: ((spend[i] as Map<String, dynamic>)['amount']
                                    as num)
                                .toDouble(),
                            title:
                                (spend[i] as Map<String, dynamic>)['category']
                                    .toString(),
                            color: HSLColor.fromAHSL(
                                    1.0, (i * 47) % 360.0, 0.55, 0.55)
                                .toColor(),
                            radius: 70,
                            titleStyle: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
