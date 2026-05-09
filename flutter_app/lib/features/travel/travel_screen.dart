import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/models/lifecycle.dart';
import '../../domain/airline_brand.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/premium/premium.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../../widgets/section_header.dart';
import '../lifecycle/lifecycle_provider.dart';
import 'travel_stats_header.dart';

/// Travel OS — densely-layered hub for the entire travel ecosystem.
///
/// Surfaces the lifecycle pipeline (planning → ticketing → boarding →
/// in-flight → arrived), a quick services row, segmented Upcoming/Past
/// stages, and rich trip cards that route into either the per-trip
/// detail or the live boarding pass.
class TravelScreen extends ConsumerStatefulWidget {
  const TravelScreen({super.key});
  @override
  ConsumerState<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends ConsumerState<TravelScreen>
    with AutomaticKeepAliveClientMixin {
  int _stage = 0; // 0 active+upcoming, 1 past

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final lifecycle = ref.watch(lifecycleProvider);
    final theme = Theme.of(context);
    final upcoming =
        lifecycle.trips.where((t) => t.stage == 'upcoming').toList();
    final active = lifecycle.trips.where((t) => t.stage == 'active').toList();
    final past = lifecycle.trips.where((t) => t.stage == 'past').toList();
    final visible = _stage == 0 ? [...active, ...upcoming] : past;

    // First active leg (if any) — hero fast-path into boarding pass.
    final activeHero = active.isNotEmpty && active.first.legs.isNotEmpty
        ? active.first
        : null;
    final upcomingHero = activeHero == null &&
            upcoming.isNotEmpty &&
            upcoming.first.legs.isNotEmpty
        ? upcoming.first
        : null;

    return RefreshIndicator(
      onRefresh: () => ref.read(lifecycleProvider.notifier).hydrate(),
      child: ListView(
        // Right padding leaves room for the floating top-right theme
        // chrome rendered by AppShell.
        padding: EdgeInsets.fromLTRB(
          AppTokens.space5,
          MediaQuery.of(context).padding.top + AppTokens.space5,
          AppTokens.space5 + 48,
          AppTokens.space9 + 16,
        ),
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Title row + plan trip CTA ────────────────────────────
          Row(
            children: [
              Text('Travel',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  )),
              const Spacer(),
              Pressable(
                scale: 0.96,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/planner');
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.6),
                      ],
                    ),
                    boxShadow: AppTokens.shadowMd(
                      tint: theme.colorScheme.primary,
                    ),
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 60),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Your travel operating system — every trip, lifecycle stage, and ground service in one place.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space5),

          // ── Animated travel stats ──────────────────────────────
          AnimatedAppearance(
            delay: const Duration(milliseconds: 80),
            child: const TravelStatsHeader(
              countries: 14,
              flights: 38,
              distanceKm: 142800,
              hoursInAir: 196,
            ),
          ),
          const SizedBox(height: AppTokens.space4),

          // ── Boarding-ready hero (when an active leg exists) ─────
          if (activeHero != null || upcomingHero != null) ...[
            AnimatedAppearance(
              delay: const Duration(milliseconds: 100),
              child: _BoardingReadyHero(
                trip: (activeHero ?? upcomingHero)!,
                isActive: activeHero != null,
              ),
            ),
            // Departure-board callsign block, mirrors the kiosk header.
            const SizedBox(height: AppTokens.space3),
            Builder(builder: (context) {
              final t = (activeHero ?? upcomingHero)!;
              final brand = resolveAirlineBrand(t.legs.first.flightNumber);
              return AnimatedAppearance(
                delay: const Duration(milliseconds: 140),
                child: FlightCallsignBoard(
                  callsign: t.legs.first.flightNumber,
                  fromIata: t.legs.first.from,
                  toIata: t.legs.last.to,
                  depart: t.legs.first.scheduled,
                  gate: t.legs.first.gate,
                  tone: brand.primary,
                ),
              );
            }),
          ],

          // ── Lifecycle pipeline strip ────────────────────────────
          const SectionHeader(title: 'Trip lifecycle', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 140),
            child: _LifecyclePipeline(
              activeStage: activeHero != null
                  ? 'in-flight'
                  : upcoming.isNotEmpty
                      ? 'ticketing'
                      : 'planning',
            ),
          ),

          // ── Travel systems quick row ────────────────────────────
          const SectionHeader(title: 'Travel systems'),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 180),
            child: const _TravelSystemsRow(),
          ),

          // ── Stage segmented + trip list ─────────────────────────
          const SectionHeader(title: 'My trips'),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 220),
            child: _StageSegmented(
              value: _stage,
              activeCount: active.length + upcoming.length,
              pastCount: past.length,
              onChanged: (i) {
                HapticFeedback.selectionClick();
                setState(() => _stage = i);
              },
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: AppTokens.space7),
              child: EmptyState(
                title: 'No trips here',
                message:
                    'Plan a trip and we will set up boarding passes, packing, and reminders.',
                icon: Icons.flight_takeoff_rounded,
              ),
            )
          else
            for (var i = 0; i < visible.length; i++)
              AnimatedAppearance(
                delay: Duration(milliseconds: 60 * i),
                child: _TripCard(
                  trip: visible[i],
                  muted: visible[i].stage == 'past',
                ),
              ),
        ],
      ),
    );
  }
}

// ── Boarding-ready hero ──────────────────────────────────────────
class _BoardingReadyHero extends StatelessWidget {
  const _BoardingReadyHero({required this.trip, required this.isActive});
  final TripLifecycle trip;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final leg = trip.legs.first;
    final brand = resolveAirlineBrand(leg.flightNumber.split(' ').first);
    final accent = brand.colors.first;
    return Pressable(
      scale: 0.99,
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push('/boarding/${trip.id}/${leg.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTokens.space5),
        padding: const EdgeInsets.all(AppTokens.space5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radius2xl),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.34),
              accent.withValues(alpha: 0.10),
              const Color(0xFF050912),
            ],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.46)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.22),
              blurRadius: 28,
              spreadRadius: -8,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flight_takeoff_rounded,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        isActive ? 'BOARDING NOW' : 'BOARDING SOON',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(leg.flightNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    )),
              ],
            ),
            const SizedBox(height: AppTokens.space3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _IataMega(text: leg.from),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        Icon(Icons.flight_rounded,
                            color: Colors.white.withValues(alpha: 0.85),
                            size: 18),
                        const SizedBox(height: 2),
                        SizedBox(
                          height: 2,
                          child: CustomPaint(
                            painter: _DashPainter(
                                color:
                                    Colors.white.withValues(alpha: 0.55)),
                            size: const Size(double.infinity, 2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _IataMega(text: leg.to),
              ],
            ),
            const SizedBox(height: AppTokens.space3),
            Row(
              children: [
                Expanded(
                  child: _BoardingMeta(
                    label: 'GATE',
                    value: leg.gate ?? '—',
                  ),
                ),
                Expanded(
                  child: _BoardingMeta(
                    label: 'TERM',
                    value: leg.terminal ?? '—',
                  ),
                ),
                Expanded(
                  child: _BoardingMeta(
                    label: 'SEAT',
                    value: leg.seat ?? '—',
                  ),
                ),
                Expanded(
                  child: _BoardingMeta(
                    label: 'BOARD',
                    value: _shortTime(leg.boarding ?? leg.scheduled),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space3),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              ),
              child: Row(
                children: [
                  Icon(Icons.touch_app_rounded,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.78)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tap to open boarding pass — barcode + brightness ramp',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.84),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded,
                      size: 14, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortTime(String iso) {
    if (iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso);
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '—';
    }
  }
}

class _IataMega extends StatelessWidget {
  const _IataMega({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 36,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        height: 1,
      ),
    );
  }
}

class _BoardingMeta extends StatelessWidget {
  const _BoardingMeta({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.62),
            fontSize: 9.5,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ── Lifecycle pipeline strip ─────────────────────────────────────
class _LifecyclePipeline extends StatelessWidget {
  const _LifecyclePipeline({required this.activeStage});
  final String activeStage;

  static const _stages = <(String, IconData)>[
    ('Planning', Icons.edit_calendar_rounded),
    ('Ticketing', Icons.confirmation_number_outlined),
    ('Packing', Icons.luggage_outlined),
    ('Boarding', Icons.airplane_ticket_rounded),
    ('In-flight', Icons.flight_rounded),
    ('Arrived', Icons.location_on_rounded),
  ];

  int get _activeIndex {
    switch (activeStage) {
      case 'planning':
        return 0;
      case 'ticketing':
        return 1;
      case 'packing':
        return 2;
      case 'boarding':
        return 3;
      case 'in-flight':
        return 4;
      case 'arrived':
        return 5;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _stages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final isActive = i == _activeIndex;
          final isPast = i < _activeIndex;
          return Container(
            width: 92,
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: AppTokens.space2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusXl),
              color: isActive
                  ? accent.withValues(alpha: 0.20)
                  : (isPast
                      ? accent.withValues(alpha: 0.08)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.04)),
              border: Border.all(
                color: isActive
                    ? accent.withValues(alpha: 0.55)
                    : (isPast
                        ? accent.withValues(alpha: 0.20)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.06)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  _stages[i].$2,
                  color: isActive
                      ? accent
                      : (isPast
                          ? accent.withValues(alpha: 0.65)
                          : theme.colorScheme.onSurface
                              .withValues(alpha: 0.45)),
                  size: 18,
                ),
                Text(
                  _stages[i].$1,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight:
                        isActive ? FontWeight.w800 : FontWeight.w700,
                    color: isActive
                        ? accent
                        : (isPast
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.55)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Travel systems quick row ─────────────────────────────────────
class _TravelSystemsRow extends StatelessWidget {
  const _TravelSystemsRow();

  @override
  Widget build(BuildContext context) {
    final tiles = <(_TravelTileData, _TravelTileData)>[
      (
        const _TravelTileData(
          label: 'Timeline',
          icon: Icons.timeline_rounded,
          accent: Color(0xFF06B6D4),
          route: '/timeline',
        ),
        const _TravelTileData(
          label: 'Planner',
          icon: Icons.edit_calendar_rounded,
          accent: Color(0xFF7C3AED),
          route: '/planner',
        ),
      ),
      (
        const _TravelTileData(
          label: 'Copilot',
          icon: Icons.auto_awesome_rounded,
          accent: Color(0xFFEC4899),
          route: '/copilot',
        ),
        const _TravelTileData(
          label: 'Intelligence',
          icon: Icons.insights_rounded,
          accent: Color(0xFF3B82F6),
          route: '/intelligence',
        ),
      ),
      (
        const _TravelTileData(
          label: 'Globe',
          icon: Icons.public_rounded,
          accent: Color(0xFF22C55E),
          route: '/map',
        ),
        const _TravelTileData(
          label: 'Kiosk',
          icon: Icons.point_of_sale_rounded,
          accent: Color(0xFFF59E0B),
          route: '/kiosk-sim',
        ),
      ),
    ];
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: tiles.length * 2,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final pair = tiles[i ~/ 2];
          final t = i.isEven ? pair.$1 : pair.$2;
          return _TravelSystemTile(data: t);
        },
      ),
    );
  }
}

class _TravelTileData {
  const _TravelTileData({
    required this.label,
    required this.icon,
    required this.accent,
    required this.route,
  });
  final String label;
  final IconData icon;
  final Color accent;
  final String route;
}

class _TravelSystemTile extends StatelessWidget {
  const _TravelSystemTile({required this.data});
  final _TravelTileData data;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      scale: 0.96,
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(data.route);
      },
      child: Container(
        width: 132,
        padding: const EdgeInsets.all(AppTokens.space3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusXl),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              data.accent.withValues(alpha: 0.20),
              data.accent.withValues(alpha: 0.06),
            ],
          ),
          border: Border.all(color: data.accent.withValues(alpha: 0.32)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: data.accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              ),
              child: Icon(data.icon, color: data.accent, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                data.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageSegmented extends StatelessWidget {
  const _StageSegmented({
    required this.value,
    required this.activeCount,
    required this.pastCount,
    required this.onChanged,
  });
  final int value;
  final int activeCount;
  final int pastCount;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
      ),
      child: Row(
        children: [
          for (final (i, label, count) in [
            (0, 'Upcoming', activeCount),
            (1, 'Past', pastCount),
          ])
            Expanded(
              child: Pressable(
                scale: 0.97,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: AppTokens.durationMd,
                  curve: AppTokens.easeOutSoft,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                    gradient: i == value
                        ? LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.8),
                              theme.colorScheme.primary.withValues(alpha: 0.6),
                            ],
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(label,
                          style: TextStyle(
                            color: i == value
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          )),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: (i == value
                                  ? Colors.white
                                  : theme.colorScheme.onSurface)
                              .withValues(alpha: 0.18),
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusFull),
                        ),
                        child: Text('$count',
                            style: TextStyle(
                              color: i == value
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                    ],
                  ),
                ),
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
    final brand = resolveAirlineBrand(firstLeg?.flightNumber.split(' ').first);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space3),
      child: Hero(
        tag: 'trip-${trip.id}',
        child: Material(
          color: Colors.transparent,
          child: Pressable(
            scale: 0.99,
            onTap: () {
              HapticFeedback.lightImpact();
              GoRouter.of(context).push('/trip/${trip.id}');
            },
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space5),
              gradient: muted
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        brand.colors.first.withValues(alpha: 0.32),
                        brand.colors.last.withValues(alpha: 0.12),
                      ],
                    ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: muted
                              ? theme.colorScheme.onSurface
                                  .withValues(alpha: 0.08)
                              : Colors.white.withValues(alpha: 0.18),
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flight_rounded,
                                size: 12,
                                color: muted
                                    ? theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6)
                                    : Colors.white),
                            const SizedBox(width: 4),
                            Text(trip.stage.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: muted
                                      ? theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6)
                                      : Colors.white,
                                )),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (trip.startDate != null)
                        Text(
                          trip.startDate!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted
                                ? null
                                : Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space3),
                  Text(trip.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: muted ? null : Colors.white,
                        fontWeight: FontWeight.w800,
                      )),
                  if (firstLeg != null) ...[
                    const SizedBox(height: AppTokens.space3),
                    Row(
                      children: [
                        _IataPill(text: firstLeg.from, onLight: muted),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: CustomPaint(
                              size: const Size.fromHeight(2),
                              painter: _DashPainter(
                                color: muted
                                    ? theme.colorScheme.onSurface
                                        .withValues(alpha: 0.32)
                                    : Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                        _IataPill(text: firstLeg.to, onLight: muted),
                        if (firstLeg.flightNumber.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(firstLeg.flightNumber,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: muted
                                    ? null
                                    : Colors.white.withValues(alpha: 0.85),
                                letterSpacing: 1.2,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              )),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: AppTokens.space3),
                  Row(
                    children: [
                      Icon(Icons.airline_stops_rounded,
                          size: 14,
                          color: muted
                              ? theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.7)),
                      const SizedBox(width: 6),
                      Text('${trip.legs.length} leg(s)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted
                                ? null
                                : Colors.white.withValues(alpha: 0.7),
                          )),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IataPill extends StatelessWidget {
  const _IataPill({required this.text, required this.onLight});
  final String text;
  final bool onLight;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
          color: onLight ? theme.colorScheme.onSurface : Colors.white,
        ));
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter({required this.color});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    const dashWidth = 4.0;
    const gap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, size.height / 2),
          Offset(x + dashWidth, size.height / 2), paint);
      x += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter old) => old.color != color;
}
