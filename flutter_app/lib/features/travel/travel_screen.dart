import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/models/lifecycle.dart';
import '../../domain/airline_brand.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../lifecycle/lifecycle_provider.dart';

/// Travel v2 — segmented stage tabs (Active/Upcoming/Past), premium
/// trip cards with brand gradient, animated reveal.
class TravelScreen extends ConsumerStatefulWidget {
  const TravelScreen({super.key});
  @override
  ConsumerState<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends ConsumerState<TravelScreen> {
  int _stage = 0; // 0 active+upcoming, 1 past

  @override
  Widget build(BuildContext context) {
    final lifecycle = ref.watch(lifecycleProvider);
    final theme = Theme.of(context);
    final upcoming =
        lifecycle.trips.where((t) => t.stage == 'upcoming').toList();
    final active = lifecycle.trips.where((t) => t.stage == 'active').toList();
    final past = lifecycle.trips.where((t) => t.stage == 'past').toList();
    final visible = _stage == 0 ? [...active, ...upcoming] : past;

    return RefreshIndicator(
      onRefresh: () => ref.read(lifecycleProvider.notifier).hydrate(),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppTokens.space5,
          MediaQuery.of(context).padding.top + AppTokens.space5,
          AppTokens.space5,
          AppTokens.space9 + 16,
        ),
        physics: const BouncingScrollPhysics(),
        children: [
          Row(
            children: [
              Text('Travel',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  )),
              const Spacer(),
              Pressable(
                scale: 0.96,
                onTap: () => context.push('/planner'),
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
          const SizedBox(height: AppTokens.space5),
          AnimatedAppearance(
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
          const SizedBox(height: AppTokens.space5),
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
