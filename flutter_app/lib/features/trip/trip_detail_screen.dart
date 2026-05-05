import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/models/lifecycle.dart';
import '../../domain/airports.dart';
import '../../domain/connection_detector.dart';
import '../../domain/packing_list.dart';
import '../../domain/predictive_departure.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/section_header.dart';
import '../lifecycle/lifecycle_provider.dart';

class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({super.key, required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lifecycle = ref.watch(lifecycleProvider);
    final trip = lifecycle.trips.cast<TripLifecycle?>().firstWhere(
          (t) => t?.id == tripId,
          orElse: () => null,
        );
    final theme = Theme.of(context);

    if (trip == null) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: const EmptyState(
          title: 'Trip not found',
          message: 'This trip may have been removed.',
          icon: Icons.search_off_rounded,
        ),
      );
    }

    final tightLegIds = detectConnections(trip.legs)
        .where((c) => c.severity == 'tight')
        .map((c) => c.toLegId)
        .toSet();

    final from = trip.legs.isNotEmpty ? trip.legs.first.from : null;
    final to = trip.legs.isNotEmpty ? trip.legs.last.to : null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            leading: BackButton(onPressed: () => context.pop()),
            stretch: true,
            expandedHeight: 220,
            backgroundColor: theme.colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(trip.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
              background: Hero(
                tag: 'trip-${trip.id}',
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.45),
                        theme.colorScheme.primary.withValues(alpha: 0.18),
                        Colors.black.withValues(alpha: 0.25),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppTokens.space5),
            sliver: SliverList.list(
              children: [
                Row(children: [
                  PillChip(
                      label: trip.stage.toUpperCase(),
                      icon: Icons.flight_rounded),
                  const SizedBox(width: AppTokens.space2),
                  if (from != null && to != null)
                    PillChip(label: '$from → $to', icon: Icons.route_rounded),
                ]),
                const SizedBox(height: AppTokens.space5),
                _LegList(legs: trip.legs, tightLegIds: tightLegIds),
                if (trip.legs.isNotEmpty) ...[
                  const SectionHeader(
                      title: 'Predictive departure', dense: true),
                  _DepartureCard(leg: trip.legs.first),
                ],
                const SectionHeader(title: 'Packing list', dense: true),
                _PackingCard(trip: trip),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegList extends StatelessWidget {
  const _LegList({required this.legs, required this.tightLegIds});
  final List<FlightLeg> legs;
  final Set<String> tightLegIds;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final l in legs)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.space3),
            child: GlassSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${l.from} → ${l.to}',
                          style: theme.textTheme.titleLarge),
                      const Spacer(),
                      Text(l.flightNumber,
                          style: theme.textTheme.titleSmall?.copyWith(
                            letterSpacing: 1.4,
                          )),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space2),
                  Wrap(
                    spacing: AppTokens.space2,
                    runSpacing: AppTokens.space2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.access_time_rounded,
                            size: 14, color: theme.textTheme.bodySmall?.color),
                        const SizedBox(width: 4),
                        Text(l.scheduled, style: theme.textTheme.bodySmall),
                      ]),
                      if (l.gate != null) PillChip(label: 'Gate ${l.gate}'),
                      if (l.seat != null) PillChip(label: 'Seat ${l.seat}'),
                      if (tightLegIds.contains(l.id))
                        const PillChip(
                          label: 'Tight conn',
                          icon: Icons.warning_amber_rounded,
                          tone: Color(0xFFD97706),
                        ),
                    ],
                  ),
                  if (getAirport(l.from) != null) ...[
                    const SizedBox(height: AppTokens.space2),
                    Text(
                      '${getAirport(l.from)!.city} → ${getAirport(l.to)?.city ?? l.to}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _DepartureCard extends StatelessWidget {
  const _DepartureCard({required this.leg});
  final FlightLeg leg;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final boarding = DateTime.tryParse(leg.boarding ?? leg.scheduled) ??
        DateTime.now().add(const Duration(hours: 2));
    final est = predictLeaveBy(departureLocal: boarding);
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: AppTokens.space2),
              Text('Leave by', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppTokens.space2),
          Text(
            '${est.leaveBy.hour.toString().padLeft(2, '0')}:${est.leaveBy.minute.toString().padLeft(2, '0')}',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
              '${est.travelTimeMinutes} min travel + ${est.bufferMinutes} min airport buffer',
              style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _PackingCard extends StatelessWidget {
  const _PackingCard({required this.trip});
  final TripLifecycle trip;
  @override
  Widget build(BuildContext context) {
    final dest = trip.legs.isNotEmpty ? trip.legs.last.to : 'XXX';
    final destInfo = getAirport(dest);
    final dep = DateTime.tryParse(
            trip.legs.isNotEmpty ? trip.legs.first.scheduled : '') ??
        DateTime.now();
    final items = PackingList.generate(
      destinationCountry: destInfo?.country ?? 'Unknown',
      days: 5,
      departure: dep,
    );
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final i in items.take(8))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                      i.essential
                          ? Icons.check_circle_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 18,
                      color: i.essential ? Colors.green : Colors.grey),
                  const SizedBox(width: AppTokens.space2),
                  Expanded(child: Text(i.label)),
                  PillChip(label: i.category),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
