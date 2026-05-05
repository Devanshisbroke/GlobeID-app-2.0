import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/api/api_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/page_scaffold.dart';

final plannerListProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.read(globeIdApiProvider).plannerList();
});

class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTrips = ref.watch(plannerListProvider);
    final theme = Theme.of(context);
    return PageScaffold(
      title: 'Planner',
      subtitle: 'Sketch and reorder upcoming trips',
      body: asyncTrips.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          title: 'Planner unavailable',
          message: e.toString(),
          icon: Icons.cloud_off_rounded,
        ),
        data: (trips) {
          if (trips.isEmpty) {
            return const EmptyState(
              title: 'No planned trips',
              message: 'Tap + to start planning your next adventure.',
              icon: Icons.event_note_rounded,
            );
          }
          return ReorderableListView(
            onReorder: (_, __) {},
            children: [
              for (final t in trips)
                Padding(
                  key: ValueKey(t['id']),
                  padding: const EdgeInsets.only(bottom: AppTokens.space3),
                  child: GlassSurface(
                    child: Row(
                      children: [
                        Icon(Icons.flight_takeoff_rounded,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: AppTokens.space3),
                        Expanded(
                            child: Text(t['name']?.toString() ?? 'Trip',
                                style: theme.textTheme.titleMedium)),
                        const Icon(Icons.drag_handle_rounded),
                      ],
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
