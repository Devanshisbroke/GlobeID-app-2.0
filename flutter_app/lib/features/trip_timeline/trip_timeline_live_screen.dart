import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cinematic/live/live_primitives.dart';
import '../../data/models/lifecycle.dart';
import '../../motion/motion.dart';
import '../../nexus/nexus_tokens.dart';
import '../lifecycle/lifecycle_provider.dart';

/// TripTimelineLive — a cinematic, alive journey timeline.
///
/// Anatomy:
///
///   • Atmosphere backdrop in indigo (the journey tone)
///   • Vertical phase ribbon — PLAN · PACK · CHECK-IN · LOUNGE ·
///     BOARD · CRUISE · LAND · CUSTOMS · ARRIVAL — each stage:
///       — Tonal disc with phase glyph
///       — Live ETA / status under the label
///       — Hairline 1px vertical connector to the next stage
///       — Active stage breathes (BreathingRing) and shimmers
///   • Selected stage promotes into a detail card with:
///       — Live countdown to the next event (boarding, gate close,
///         takeoff, landing, customs lane open)
///       — Sub-events: ground transport, gate change, baggage
///         carousel ETA, immigration queue
///   • Bottom CTA — "Open boarding pass" / "Open visa" / "Open
///     navigation" based on the active stage.
///
/// Routes:
///   • `/trip-timeline-live` — auto-resolves the active or first
///     upcoming trip.
///   • `/trip-timeline-live/:tripId` — pinned to a specific trip.
class TripTimelineLiveScreen extends ConsumerStatefulWidget {
  const TripTimelineLiveScreen({super.key, this.tripId});
  final String? tripId;

  @override
  ConsumerState<TripTimelineLiveScreen> createState() =>
      _TripTimelineLiveScreenState();
}

class _TripTimelineLiveScreenState
    extends ConsumerState<TripTimelineLiveScreen> {
  int _activeIndex = 4; // default to BOARD
  // Phase-commit broadcast controller. Pulses the stage detail card
  // every time the user crosses a real travel boundary.
  final _phasePulse = LiveDataPulseController();

  @override
  void dispose() {
    _phasePulse.dispose();
    super.dispose();
  }

  static const _stages = [
    _Stage('PLAN', Icons.flag_rounded, 'Visa, hotels, transit ready'),
    _Stage('PACK', Icons.luggage_rounded, 'Checklist · 12/14 complete'),
    _Stage('CHECK-IN', Icons.how_to_reg_rounded, 'Online check-in open'),
    _Stage('LOUNGE', Icons.weekend_rounded, 'Polaris · Concourse C'),
    _Stage('BOARD', Icons.airplanemode_active_rounded, 'Boards in 02:14:35'),
    _Stage('CRUISE', Icons.flight_rounded, 'SFO → NRT · 11 h 25 m'),
    _Stage('LAND', Icons.flight_land_rounded, 'Arrives 19:45 JST'),
    _Stage('CUSTOMS', Icons.shield_rounded, 'eGate ready · 4 min queue'),
    _Stage('ARRIVAL', Icons.location_on_rounded, 'Aman Tokyo · 22:10'),
  ];

  /// Cinematic phase-commit detection. The stages array maps to:
  ///   0 PLAN · 1 PACK · 2 CHECK-IN · 3 LOUNGE · 4 BOARD
  ///   5 CRUISE · 6 LAND · 7 CUSTOMS · 8 ARRIVAL
  ///
  /// The transitions that represent a real travel commit (you've
  /// physically crossed a boundary) are:
  ///   BOARD   → CRUISE   (4 → 5, plane has taken off)
  ///   CRUISE  → LAND     (5 → 6, plane has landed)
  ///   CUSTOMS → ARRIVAL  (7 → 8, cleared and out of the airport)
  bool _isPhaseCommit(int from, int to) {
    if (to <= from) return false; // moving backward is never a commit
    if (from == 4 && to == 5) return true;
    if (from == 5 && to == 6) return true;
    if (from == 7 && to == 8) return true;
    return false;
  }

  /// Map a stage index to its cinematic surface state. Earlier stages
  /// breathe in "active" (mid cadence); the active stage itself
  /// breathes "armed" (faster, anticipating). The arrival stage
  /// settles into the calm "settled" cadence.
  LiveSurfaceState _stateForStage(int index, int active) {
    if (index < active) return LiveSurfaceState.committed;
    if (index == active) return LiveSurfaceState.active;
    if (index == _stages.length - 1 && active == _stages.length - 1) {
      return LiveSurfaceState.settled;
    }
    return LiveSurfaceState.armed;
  }

  TripLifecycle? _resolveTrip() {
    final lifecycle = ref.watch(lifecycleProvider);
    if (lifecycle.trips.isEmpty) return null;
    if (widget.tripId != null) {
      return lifecycle.trips
          .cast<TripLifecycle?>()
          .firstWhere((t) => t?.id == widget.tripId, orElse: () => null);
    }
    final active = lifecycle.trips.where((t) => t.stage == 'active').toList();
    if (active.isNotEmpty) return active.first;
    final upcoming =
        lifecycle.trips.where((t) => t.stage == 'upcoming').toList();
    if (upcoming.isNotEmpty) return upcoming.first;
    return lifecycle.trips.first;
  }

  @override
  Widget build(BuildContext context) {
    final trip = _resolveTrip();
    const tone = Color(0xFF6366F1);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: LiveCanvas(
        tone: tone,
        statusBar: _Header(trip: trip, tone: tone),
        bottomBar: _ActiveCta(stage: _stages[_activeIndex], tone: tone),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              // Wrap the active-stage detail in a LiveDataPulse so
              // the card visually broadcasts every phase commit
              // (BOARD → CRUISE → LAND → ARRIVAL). The pulse is
              // fired in `onTap` below.
              LiveDataPulse(
                controller: _phasePulse,
                tone: tone,
                child: _StageDetailCard(
                  stage: _stages[_activeIndex],
                  index: _activeIndex,
                  count: _stages.length,
                  tone: tone,
                  trip: trip,
                  liveState: _stateForStage(_activeIndex, _activeIndex),
                ),
              ),
              const SizedBox(height: N.s4),
              for (var i = 0; i < _stages.length; i++)
                _TimelineRow(
                  stage: _stages[i],
                  index: i,
                  last: i == _stages.length - 1,
                  active: i == _activeIndex,
                  done: i < _activeIndex,
                  tone: tone,
                  onTap: () {
                    // Phase commits get the cinematic signature
                    // triple-pulse — the user has crossed a real
                    // travel boundary (boarded, landed, cleared
                    // customs). Soft selectionClick otherwise.
                    final committing = _isPhaseCommit(_activeIndex, i);
                    if (committing) {
                      Haptics.signature();
                      // Broadcast the commit to the stage detail
                      // card so the user feels and sees the phase
                      // shift land at the same time.
                      _phasePulse.pulse();
                    } else {
                      HapticFeedback.selectionClick();
                    }
                    setState(() => _activeIndex = i);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stage {
  const _Stage(this.label, this.icon, this.subtitle);
  final String label;
  final IconData icon;
  final String subtitle;
}

// ─────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.trip, required this.tone});
  final TripLifecycle? trip;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final title = trip?.name ?? 'Tokyo · 7 nights';
    return Padding(
      padding: const EdgeInsets.only(bottom: N.s3),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 0.5,
                ),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: N.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LIVE TIMELINE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: tone.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
          LiveStatusPill(
            state: LiveSurfaceState.active,
            tone: tone,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// STAGE DETAIL CARD — the promoted detail block for the active stage.
// ─────────────────────────────────────────────────────────────────────

class _StageDetailCard extends StatelessWidget {
  const _StageDetailCard({
    required this.stage,
    required this.index,
    required this.count,
    required this.tone,
    required this.trip,
    this.liveState = LiveSurfaceState.active,
  });
  final _Stage stage;
  final int index;
  final int count;
  final Color tone;
  final TripLifecycle? trip;

  /// Cinematic state of the active stage. Drives the breathing ring
  /// cadence so the user feels the trip's current phase intensity
  /// (committed = single pulse, active = mid cadence, settled = calm).
  final LiveSurfaceState liveState;

  String _nextEventLabel() {
    switch (stage.label) {
      case 'BOARD':
        return 'BOARDING IN';
      case 'CRUISE':
        return 'LANDING IN';
      case 'LAND':
        return 'TAXI IN';
      case 'CUSTOMS':
        return 'EGATE OPENS IN';
      case 'ARRIVAL':
        return 'CHECK-IN IN';
      default:
        return 'NEXT STEP IN';
    }
  }

  Duration _nextEventDuration() {
    switch (stage.label) {
      case 'BOARD':
        return const Duration(hours: 2, minutes: 14, seconds: 35);
      case 'CRUISE':
        return const Duration(hours: 9, minutes: 12);
      case 'LAND':
        return const Duration(minutes: 18);
      case 'CUSTOMS':
        return const Duration(minutes: 4);
      case 'ARRIVAL':
        return const Duration(minutes: 32);
      default:
        return const Duration(hours: 6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = DateTime.now().add(_nextEventDuration());
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(N.rCardLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tone.withValues(alpha: 0.20),
            tone.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(
          color: tone.withValues(alpha: 0.30),
          width: 0.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: BreathingRing(
                      tone: tone,
                      size: 64,
                      duration: liveState.breathingPeriod,
                    ),
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tone.withValues(alpha: 0.20),
                      border: Border.all(
                        color: tone.withValues(alpha: 0.55),
                        width: 0.6,
                      ),
                    ),
                    child: Icon(stage.icon, color: Colors.white, size: 24),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STAGE ${index + 1} · OF · $count',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w900,
                        fontSize: 9,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      stage.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stage.subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.black.withValues(alpha: 0.32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${_nextEventLabel()} ',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1.4,
                  ),
                ),
                Expanded(
                  child: LiveCountdown(
                    target: target,
                    builder: (_, d) {
                      String t() {
                        if (d.isNegative) return 'NOW';
                        final h = d.inHours;
                        final m = (d.inMinutes % 60).toString().padLeft(2, '0');
                        final s = (d.inSeconds % 60).toString().padLeft(2, '0');
                        if (h > 0) {
                          return '${h.toString().padLeft(2, '0')}:$m:$s';
                        }
                        return '$m:$s';
                      }

                      return Text(
                        t(),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          letterSpacing: 1.0,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// TIMELINE ROW
// ─────────────────────────────────────────────────────────────────────

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.stage,
    required this.index,
    required this.last,
    required this.active,
    required this.done,
    required this.tone,
    required this.onTap,
  });
  final _Stage stage;
  final int index;
  final bool last;
  final bool active;
  final bool done;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final discTone = active
        ? tone
        : (done ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.18));
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Disc + connector column.
            SizedBox(
              width: 48,
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: discTone.withValues(alpha: 0.18),
                      border: Border.all(color: discTone, width: 0.8),
                    ),
                    child: Icon(
                      done ? Icons.check_rounded : stage.icon,
                      color: discTone,
                      size: 16,
                    ),
                  ),
                  if (!last)
                    Expanded(
                      child: Container(
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 14, 4, 14),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: active
                        ? tone.withValues(alpha: 0.10)
                        : Colors.white.withValues(alpha: 0.04),
                    border: Border.all(
                      color: active
                          ? tone.withValues(alpha: 0.35)
                          : Colors.white.withValues(alpha: 0.10),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stage.label,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 1.6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              stage.subtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.60),
                                fontWeight: FontWeight.w700,
                                fontSize: 10.5,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        active
                            ? Icons.chevron_right_rounded
                            : (done ? Icons.check_rounded : Icons.circle_outlined),
                        color: discTone,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// ACTIVE CTA
// ─────────────────────────────────────────────────────────────────────

class _ActiveCta extends StatelessWidget {
  const _ActiveCta({required this.stage, required this.tone});
  final _Stage stage;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    String label;
    IconData icon;
    String route;
    switch (stage.label) {
      case 'BOARD':
        label = 'Boarding pass';
        icon = Icons.qr_code_2_rounded;
        route = '/boarding-pass-live';
        break;
      case 'LOUNGE':
        label = 'Lounge access';
        icon = Icons.weekend_rounded;
        route = '/lounge-live';
        break;
      case 'CUSTOMS':
        label = 'Immigration';
        icon = Icons.shield_rounded;
        route = '/immigration-live';
        break;
      case 'CHECK-IN':
        label = 'Check-in';
        icon = Icons.how_to_reg_rounded;
        route = '/boarding-pass-live';
        break;
      case 'LAND':
        label = 'Arrival companion';
        icon = Icons.flight_land_rounded;
        route = '/arrival-live';
        break;
      case 'ARRIVAL':
        label = 'Live navigation';
        icon = Icons.alt_route_rounded;
        route = '/navigation-live';
        break;
      default:
        label = 'Trip overview';
        icon = Icons.timeline_rounded;
        route = '/travel';
    }
    return Row(
      children: [
        Expanded(
          child: LiveCta(
            label: label,
            icon: icon,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(route);
            },
          ),
        ),
        const SizedBox(width: N.s3),
        SizedBox(
          width: 54,
          child: LiveCta(
            label: '',
            icon: Icons.airplane_ticket_rounded,
            secondary: true,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/passport-live');
            },
          ),
        ),
      ],
    );
  }
}


