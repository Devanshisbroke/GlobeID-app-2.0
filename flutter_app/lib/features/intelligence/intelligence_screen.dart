import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/empty_state.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/section_header.dart';
import '../insights/insights_provider.dart';

class IntelligenceScreen extends ConsumerWidget {
  const IntelligenceScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = ref.watch(contextProvider);
    final travel = ref.watch(travelInsightsProvider);
    return PageScaffold(
      title: 'Intelligence',
      subtitle: 'Deterministic travel briefings',
      body: ListView(
        children: [
          const SectionHeader(title: 'Now', dense: true),
          ctx.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(
              title: 'Context unavailable',
              message: e.toString(),
              icon: Icons.cloud_off_rounded,
            ),
            data: (m) => GlassSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in m.entries.take(8))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        Expanded(child: Text(entry.key)),
                        Text(entry.value.toString()),
                      ]),
                    ),
                ],
              ),
            ),
          ),
          const SectionHeader(title: 'Travel insights', dense: true),
          travel.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(
              title: 'Insights unavailable',
              message: e.toString(),
              icon: Icons.cloud_off_rounded,
            ),
            data: (m) => GlassSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in m.entries.take(8))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        Expanded(child: Text(entry.key)),
                        Text(entry.value.toString()),
                      ]),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
