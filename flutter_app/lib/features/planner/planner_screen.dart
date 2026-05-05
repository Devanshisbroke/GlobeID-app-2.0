import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/api/api_provider.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';

final plannerListProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.read(globeIdApiProvider).plannerList();
});

/// Planner v2 — premium reorderable list with pinned status, gradient
/// drag handle, hero numbering, animated reveal.
class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTrips = ref.watch(plannerListProvider);
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
          return ReorderableListView.builder(
            physics: const BouncingScrollPhysics(),
            onReorder: (_, __) {
              HapticFeedback.lightImpact();
            },
            itemCount: trips.length,
            itemBuilder: (_, i) {
              final t = trips[i] as Map<String, dynamic>;
              return Padding(
                key: ValueKey(t['id']),
                padding: const EdgeInsets.only(bottom: AppTokens.space3),
                child: AnimatedAppearance(
                  delay: Duration(milliseconds: 50 * i),
                  child: _PlanRow(index: i + 1, trip: t),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.index, required this.trip});
  final int index;
  final Map<String, dynamic> trip;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.6),
                ],
              ),
              boxShadow: AppTokens.shadowSm(tint: theme.colorScheme.primary),
            ),
            child: Text('$index',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                )),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trip['name']?.toString() ?? 'Trip',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
                if (trip['date'] != null)
                  Text(trip['date'].toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      )),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusFull),
              color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
            ),
            child: Icon(Icons.drag_handle_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}
