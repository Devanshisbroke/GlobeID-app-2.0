import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/models/lifecycle.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/section_header.dart';
import '../lifecycle/lifecycle_provider.dart';

class TravelScreen extends ConsumerWidget {
  const TravelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lifecycle = ref.watch(lifecycleProvider);
    final theme = Theme.of(context);

    final upcoming =
        lifecycle.trips.where((t) => t.stage == 'upcoming').toList();
    final active = lifecycle.trips.where((t) => t.stage == 'active').toList();
    final past = lifecycle.trips.where((t) => t.stage == 'past').toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(lifecycleProvider.notifier).hydrate(),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppTokens.space5,
          MediaQuery.of(context).padding.top + AppTokens.space5,
          AppTokens.space5,
          AppTokens.space9 + 16,
        ),
        children: [
          Row(
            children: [
              Text('Travel', style: theme.textTheme.headlineLarge),
              const Spacer(),
              IconButton.filledTonal(
                onPressed: () => context.push('/planner'),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          if (active.isNotEmpty) ...[
            const SectionHeader(title: 'Active', dense: true),
            for (var i = 0; i < active.length; i++)
              _TripCard(trip: active[i])
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: i * 60))
                  .slideY(begin: 0.06, end: 0),
          ],
          if (upcoming.isNotEmpty) ...[
            const SectionHeader(title: 'Upcoming'),
            for (var i = 0; i < upcoming.length; i++)
              _TripCard(trip: upcoming[i])
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: i * 60))
                  .slideY(begin: 0.06, end: 0),
          ],
          if (past.isNotEmpty) ...[
            const SectionHeader(title: 'Past'),
            for (var i = 0; i < past.length; i++)
              _TripCard(trip: past[i], muted: true)
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: i * 50)),
          ],
          if (lifecycle.trips.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: AppTokens.space7),
              child: EmptyState(
                title: 'No trips yet',
                message:
                    'Plan your first trip and we\'ll set up boarding passes, packing, and reminders.',
                icon: Icons.flight_takeoff_rounded,
              ),
            ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, this.muted = false});
  final TripLifecycle trip;
  final bool muted;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstLeg = trip.legs.isNotEmpty ? trip.legs.first : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space3),
      child: Hero(
        tag: 'trip-${trip.id}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => GoRouter.of(context).push('/trip/${trip.id}'),
            borderRadius: BorderRadius.circular(AppTokens.radius2xl),
            child: Builder(
              builder: (_) => GlassSurface(
                radius: AppTokens.radius2xl,
                tint: muted
                    ? theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.4)
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        PillChip(
                          label: trip.stage.toUpperCase(),
                          icon: Icons.flight_rounded,
                          tone: muted
                              ? theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5)
                              : null,
                        ),
                        const Spacer(),
                        if (trip.startDate != null)
                          Text(
                            trip.startDate!,
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.space2),
                    Text(trip.name, style: theme.textTheme.headlineSmall),
                    if (firstLeg != null) ...[
                      const SizedBox(height: AppTokens.space2),
                      Row(
                        children: [
                          Text('${firstLeg.from} → ${firstLeg.to}',
                              style: theme.textTheme.titleSmall),
                          const Spacer(),
                          if (firstLeg.flightNumber.isNotEmpty)
                            Text(firstLeg.flightNumber,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  letterSpacing: 1.2,
                                )),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppTokens.space3),
                    Row(
                      children: [
                        Icon(Icons.airline_stops_rounded,
                            size: 16, color: theme.textTheme.bodySmall?.color),
                        const SizedBox(width: 6),
                        Text('${trip.legs.length} leg(s)',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
