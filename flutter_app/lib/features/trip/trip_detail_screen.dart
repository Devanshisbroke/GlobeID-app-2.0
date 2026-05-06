import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/models/lifecycle.dart';
import '../../domain/airline_brand.dart';
import '../../domain/airports.dart';
import '../../domain/connection_detector.dart';
import '../../domain/packing_list.dart';
import '../../domain/predictive_departure.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/section_header.dart';
import '../lifecycle/lifecycle_provider.dart';

/// Immersive trip detail. Hero brand-tinted backdrop, animated leg
/// timeline (IATA → IATA with airplane), per-leg pass card, location +
/// timezone strip, predictive departure card, packing list.
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

    final brand = trip.legs.isNotEmpty
        ? resolveAirlineBrand(trip.legs.first.flightNumber)
        : resolveAirlineBrand('GID');

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            leading: BackButton(onPressed: () => context.pop()),
            stretch: true,
            expandedHeight: 240,
            backgroundColor: theme.colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                trip.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: Hero(
                tag: 'trip-${trip.id}',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(gradient: brand.gradient()),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.45),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppTokens.space5,
                AppTokens.space3, AppTokens.space5, AppTokens.space9),
            sliver: SliverList.list(
              children: [
                AnimatedAppearance(
                  child: Row(
                    children: [
                      PillChip(
                          label: trip.stage.toUpperCase(),
                          icon: Icons.flight_rounded),
                      const SizedBox(width: AppTokens.space2),
                      if (from != null && to != null)
                        PillChip(
                            label: '$from → $to', icon: Icons.route_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.space5),
                if (from != null && to != null)
                  AnimatedAppearance(
                    delay: const Duration(milliseconds: 80),
                    child: _RouteHero(from: from, to: to),
                  ),
                const SizedBox(height: AppTokens.space5),
                AnimatedAppearance(
                  delay: const Duration(milliseconds: 160),
                  child: const SectionHeader(title: 'Itinerary', dense: true),
                ),
                _LegList(legs: trip.legs, tightLegIds: tightLegIds),
                if (trip.legs.isNotEmpty) ...[
                  const SectionHeader(
                      title: 'Predictive departure', dense: true),
                  AnimatedAppearance(
                    delay: const Duration(milliseconds: 240),
                    child: _DepartureCard(leg: trip.legs.first),
                  ),
                ],
                const SectionHeader(title: 'Packing list', dense: true),
                AnimatedAppearance(
                  delay: const Duration(milliseconds: 320),
                  child: _PackingCard(trip: trip),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Big horizontal IATA → IATA strip with an airplane traversing.
class _RouteHero extends StatefulWidget {
  const _RouteHero({required this.from, required this.to});
  final String from;
  final String to;

  @override
  State<_RouteHero> createState() => _RouteHeroState();
}

class _RouteHeroState extends State<_RouteHero>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final fromAirport = getAirport(widget.from);
    final toAirport = getAirport(widget.to);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 3,
                child: _IataBlock(
                  code: widget.from,
                  city: fromAirport?.city ?? 'Origin',
                ),
              ),
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 56,
                  child: AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, __) => CustomPaint(
                      painter: _RouteArc(
                        progress: _ctrl.value,
                        color: accent,
                      ),
                    ),
                  ),
                ),
              ),
              Flexible(
                flex: 3,
                child: _IataBlock(
                  code: widget.to,
                  city: toAirport?.city ?? 'Destination',
                  end: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IataBlock extends StatelessWidget {
  const _IataBlock({required this.code, required this.city, this.end = false});
  final String code;
  final String city;
  final bool end;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment:
          end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          code.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          city,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: end ? TextAlign.end : TextAlign.start,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _RouteArc extends CustomPainter {
  _RouteArc({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = Offset(size.width / 2, size.height / 2);
    final left = Offset(0, mid.dy);
    final right = Offset(size.width, mid.dy);
    // Dashed line with accent.
    final line = Paint()
      ..color = color.withValues(alpha: 0.32)
      ..strokeWidth = 1.4;
    const dash = 5.0, gap = 4.0;
    var x = left.dx;
    while (x < right.dx) {
      canvas.drawLine(Offset(x, mid.dy), Offset(x + dash, mid.dy), line);
      x += dash + gap;
    }
    // Solid accent endpoints.
    final dot = Paint()..color = color;
    canvas.drawCircle(left.translate(2, 0), 3.5, dot);
    canvas.drawCircle(right.translate(-2, 0), 3.5, dot);
    // Plane glyph.
    final px = left.dx + (right.dx - left.dx) * progress;
    final plane = Paint()..color = color;
    final p = Path()
      ..moveTo(px - 8, mid.dy - 5)
      ..lineTo(px + 6, mid.dy)
      ..lineTo(px - 8, mid.dy + 5)
      ..close();
    canvas.drawPath(p, plane);
    // Glow trail.
    final trail = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..strokeWidth = 2.4;
    canvas.drawLine(Offset(left.dx, mid.dy), Offset(px - 10, mid.dy), trail);
  }

  @override
  bool shouldRepaint(covariant _RouteArc old) =>
      old.progress != progress || old.color != color;
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
        for (var i = 0; i < legs.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.space3),
            child: AnimatedAppearance(
              delay: Duration(milliseconds: 200 + i * 60),
              child: GlassSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('${legs[i].from} → ${legs[i].to}',
                            style: theme.textTheme.titleLarge),
                        const Spacer(),
                        Text(legs[i].flightNumber,
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
                              size: 14,
                              color: theme.textTheme.bodySmall?.color),
                          const SizedBox(width: 4),
                          Text(legs[i].scheduled,
                              style: theme.textTheme.bodySmall),
                        ]),
                        if (legs[i].gate != null)
                          PillChip(label: 'Gate ${legs[i].gate}'),
                        if (legs[i].seat != null)
                          PillChip(label: 'Seat ${legs[i].seat}'),
                        if (tightLegIds.contains(legs[i].id))
                          const PillChip(
                            label: 'Tight conn',
                            icon: Icons.warning_amber_rounded,
                            tone: Color(0xFFD97706),
                          ),
                      ],
                    ),
                    if (getAirport(legs[i].from) != null) ...[
                      const SizedBox(height: AppTokens.space2),
                      Text(
                        '${getAirport(legs[i].from)!.city} → ${getAirport(legs[i].to)?.city ?? legs[i].to}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
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
