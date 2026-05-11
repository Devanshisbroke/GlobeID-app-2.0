import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/travel_record.dart';
import '../../features/user/user_provider.dart';
import '../os2_tokens.dart';
import '../primitives/os2_beacon.dart';
import '../primitives/os2_chip.dart';
import '../primitives/os2_divider_rule.dart';
import '../primitives/os2_info_strip.dart';
import '../primitives/os2_magnetic.dart';
import '../primitives/os2_pip.dart';
import '../primitives/os2_ribbon.dart';
import '../primitives/os2_slab.dart';
import '../primitives/os2_solari.dart';
import '../primitives/os2_text.dart';
import '../primitives/os2_timeline.dart';
import '../primitives/os2_world_header.dart';

/// OS 2.0 — Travel world.
///
/// Solari-board hangar. Hierarchy:
///   1. World header (Travel · GMT · DEPARTING beacon).
///   2. Departure stage hero — the next journey is laid out like a
///      Solari split-flap board: huge origin/destination codes,
///      flight number, gate, time, status. The stage breathes.
///   3. Boarding pass stack — physical passes stacked with parallax,
///      tap to open boarding-pass-live.
///   4. Lifecycle ribbon — explicit stages (PLAN \u2192 PACK \u2192 CHECK-IN \u2192
///      LOUNGE \u2192 BOARD \u2192 LAND) with current stage glowing.
///   5. Atmospheric descent panel — typographic only, no map.
class TravelWorld extends ConsumerWidget {
  const TravelWorld({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final records = user.records.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final active = records.where((r) => r.type == 'current').firstOrNull;
    final upcoming = records.where((r) => r.type == 'upcoming').toList();
    final past = records.where((r) => r.type == 'past').toList();
    final focal = active ?? (upcoming.isNotEmpty ? upcoming.first : null);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Os2WorldHeader(
              world: Os2World.travel,
              title: 'Travel',
              subtitle:
                  'Departure stage \u00b7 ${upcoming.length} upcoming \u00b7 ${past.length} flown',
              beacon: active != null ? 'IN FLIGHT' : 'READY',
            ),
            const SizedBox(height: Os2.space4),
            if (focal != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _DepartureStage(
                  record: focal,
                  isActive: active != null,
                ),
              ),
              const SizedBox(height: Os2.space4),
              // Quick info strip.
              Os2InfoStrip(
                entries: [
                  Os2InfoEntry(
                    icon: Icons.flight_takeoff_rounded,
                    label: 'GATE',
                    value: 'B14',
                    tone: Os2.travelTone,
                  ),
                  Os2InfoEntry(
                    icon: Icons.airline_seat_recline_extra_rounded,
                    label: 'SEAT',
                    value: '14A',
                    tone: Os2.travelTone,
                  ),
                  Os2InfoEntry(
                    icon: Icons.timer_rounded,
                    label: 'BOARDING',
                    value: '16:20',
                    tone: Os2.signalLive,
                    onTap: () =>
                        GoRouter.of(context).push('/boarding-pass-live'),
                  ),
                  Os2InfoEntry(
                    icon: Icons.local_airport_rounded,
                    label: 'AIRPORT',
                    value: 'FRA T1',
                    tone: Os2.servicesTone,
                    onTap: () => GoRouter.of(context).push('/airport-mode'),
                  ),
                  Os2InfoEntry(
                    icon: Icons.luggage_rounded,
                    label: 'CHECKED',
                    value: '2 BAGS',
                    tone: Os2.identityTone,
                  ),
                ],
              ),
              const SizedBox(height: Os2.space5),
              // Lifecycle ribbon.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _LifecycleRibbon(active: active != null),
              ),
              const SizedBox(height: Os2.space5),
              // Lifecycle timeline.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _JourneyTimeline(record: focal),
              ),
              const SizedBox(height: Os2.space5),
            ],
            // Boarding pass stack.
            if (upcoming.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space5),
                child: _SectionLabel(label: 'BOARDING PASS STACK'),
              ),
              const SizedBox(height: Os2.space3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _BoardingStack(records: upcoming),
              ),
              const SizedBox(height: Os2.space5),
            ],
            if (past.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space5),
                child: _SectionLabel(label: 'FLIGHT LOG'),
              ),
              const SizedBox(height: Os2.space3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _PastLog(records: past.take(6).toList()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 18, height: 1, color: Os2.travelTone.withValues(alpha: 0.55)),
        const SizedBox(width: 8),
        Os2Text.caption(label, color: Os2.travelTone),
      ],
    );
  }
}

// ─────────────────────────────────────────── Departure stage hero

class _DepartureStage extends StatelessWidget {
  const _DepartureStage({required this.record, required this.isActive});
  final TravelRecord record;
  final bool isActive;

  String _airportCode(String s) {
    final upper = s.toUpperCase();
    final m = RegExp(r'\b[A-Z]{3}\b').firstMatch(upper);
    return m?.group(0) ?? s.substring(0, s.length.clamp(0, 3)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final from = _airportCode(record.from);
    final to = _airportCode(record.to);
    return Os2Magnetic(
      onTap: () => GoRouter.of(context).push('/trip/${record.id}'),
      child: Os2Slab(
        tone: Os2.travelTone,
        tier: Os2SlabTier.floor2,
        radius: Os2.rHero,
        halo: Os2SlabHalo.full,
        elevation: Os2SlabElevation.cinematic,
        padding: const EdgeInsets.all(Os2.space5),
        breath: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Os2Chip(
                  label: isActive ? 'IN FLIGHT' : 'NEXT DEPARTURE',
                  tone: Os2.travelTone,
                  icon: Icons.flight_takeoff_rounded,
                  intensity: Os2ChipIntensity.solid,
                ),
                const SizedBox(width: Os2.space2),
                if (record.flightNumber != null)
                  Os2Chip(
                    label: record.flightNumber!,
                    tone: Os2.travelTone,
                    intensity: Os2ChipIntensity.subtle,
                  ),
                const Spacer(),
                Os2Beacon(
                  label: isActive ? 'TRACKING' : 'ON TIME',
                  tone: isActive ? Os2.signalLive : Os2.signalSettled,
                ),
              ],
            ),
            const SizedBox(height: Os2.space5),
            // Solari split-flap row.
            LayoutBuilder(
              builder: (context, box) {
                final tight = box.maxWidth < 360;
                final cellW = tight ? 26.0 : 34.0;
                final cellH = tight ? 38.0 : 48.0;
                final font = tight ? 26.0 : 34.0;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Os2Text.caption('FROM', color: Os2.inkLow),
                          const SizedBox(height: 4),
                          Os2Solari(
                            text: from,
                            tone: Os2.travelTone,
                            cellWidth: cellW,
                            cellHeight: cellH,
                            fontSize: font,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: Os2.travelTone.withValues(alpha: 0.85),
                        size: 32,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Os2Text.caption('TO', color: Os2.inkLow),
                          const SizedBox(height: 4),
                          Os2Solari(
                            text: to,
                            tone: Os2.travelTone,
                            cellWidth: cellW,
                            cellHeight: cellH,
                            fontSize: font,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: Os2.space5),
            Container(height: 0.6, color: Os2.hairline),
            const SizedBox(height: Os2.space4),
            Row(
              children: [
                Expanded(
                  child: _MetaCol(
                    label: 'AIRLINE',
                    value: record.airline,
                  ),
                ),
                Expanded(
                  child: _MetaCol(
                    label: 'DURATION',
                    value: record.duration,
                  ),
                ),
                Expanded(
                  child: _MetaCol(
                    label: 'DATE',
                    value: record.date.length >= 10
                        ? record.date.substring(5).replaceAll('-', '·')
                        : record.date,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Os2.space4),
            Row(
              children: [
                _StageChip(
                  icon: Icons.qr_code_2_rounded,
                  label: 'Boarding',
                  onTap: () => GoRouter.of(context).push(
                    '/boarding/${record.id}/leg-1',
                  ),
                ),
                const SizedBox(width: 8),
                _StageChip(
                  icon: Icons.airport_shuttle_rounded,
                  label: 'Airport',
                  onTap: () => GoRouter.of(context).push('/airport'),
                ),
                const SizedBox(width: 8),
                _StageChip(
                  icon: Icons.luggage_rounded,
                  label: 'Packing',
                  onTap: () => GoRouter.of(context).push('/packing'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaCol extends StatelessWidget {
  const _MetaCol({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Os2Text.caption(label, color: Os2.inkLow),
        const SizedBox(height: 3),
        Os2Text.title(value, color: Os2.inkBright, size: 14, maxLines: 1),
      ],
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Os2Magnetic(
      onTap: onTap,
      pressedScale: 0.94,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: ShapeDecoration(
          color: Os2.travelTone.withValues(alpha: 0.16),
          shape: StadiumBorder(
            side: BorderSide(
              color: Os2.travelTone.withValues(alpha: 0.40),
              width: Os2.strokeFine,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Os2.travelTone),
            const SizedBox(width: 6),
            Os2Text.caption(label.toUpperCase(),
                color: Os2.travelTone, size: 11),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────── Lifecycle ribbon

class _LifecycleRibbon extends StatelessWidget {
  const _LifecycleRibbon({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    const stages = [
      ('PLAN', Icons.event_note_rounded),
      ('PACK', Icons.luggage_rounded),
      ('CHECK-IN', Icons.fact_check_rounded),
      ('LOUNGE', Icons.local_cafe_rounded),
      ('BOARD', Icons.confirmation_number_rounded),
      ('LAND', Icons.flight_land_rounded),
    ];
    final currentIndex = active ? 4 : 2;
    return Os2Slab(
      tone: Os2.travelTone,
      tier: Os2SlabTier.floor1,
      radius: Os2.rCard,
      halo: Os2SlabHalo.none,
      elevation: Os2SlabElevation.flat,
      padding: const EdgeInsets.symmetric(
        horizontal: Os2.space4,
        vertical: Os2.space4,
      ),
      breath: false,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (int i = 0; i < stages.length; i++)
            _LifecycleStage(
              label: stages[i].$1,
              icon: stages[i].$2,
              state: i < currentIndex
                  ? _LifeStageState.done
                  : i == currentIndex
                      ? _LifeStageState.active
                      : _LifeStageState.pending,
            ),
        ],
      ),
    );
  }
}

enum _LifeStageState { done, active, pending }

class _LifecycleStage extends StatelessWidget {
  const _LifecycleStage({
    required this.label,
    required this.icon,
    required this.state,
  });
  final String label;
  final IconData icon;
  final _LifeStageState state;

  @override
  Widget build(BuildContext context) {
    final tone = state == _LifeStageState.active
        ? Os2.travelTone
        : state == _LifeStageState.done
            ? Os2.signalSettled
            : Os2.inkLow;
    final fill = state == _LifeStageState.active
        ? tone.withValues(alpha: 0.18)
        : Colors.transparent;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(
              color: tone.withValues(
                alpha: state == _LifeStageState.pending ? 0.18 : 0.50,
              ),
              width: Os2.strokeFine,
            ),
            boxShadow: state == _LifeStageState.active
                ? [
                    BoxShadow(
                      color: tone.withValues(alpha: 0.45),
                      blurRadius: 12,
                      spreadRadius: -1,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              state == _LifeStageState.done
                  ? Icons.check_rounded
                  : icon,
              size: 13,
              color: tone,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Os2Text.caption(label, color: tone, size: 9),
      ],
    );
  }
}

// ─────────────────────────────────────────── Boarding stack

class _BoardingStack extends StatelessWidget {
  const _BoardingStack({required this.records});
  final List<TravelRecord> records;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < records.length; i++) ...[
          _BoardingPassSlab(record: records[i]),
          if (i < records.length - 1) const SizedBox(height: Os2.space3),
        ],
      ],
    );
  }
}

class _BoardingPassSlab extends StatelessWidget {
  const _BoardingPassSlab({required this.record});
  final TravelRecord record;

  String _airportCode(String s) {
    final upper = s.toUpperCase();
    final m = RegExp(r'\b[A-Z]{3}\b').firstMatch(upper);
    return m?.group(0) ?? s.substring(0, s.length.clamp(0, 3)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final from = _airportCode(record.from);
    final to = _airportCode(record.to);
    return Os2Magnetic(
      onTap: () => GoRouter.of(context).push(
        '/boarding/${record.id}/leg-1',
      ),
      child: Os2Slab(
        tone: Os2.travelTone,
        tier: Os2SlabTier.floor1,
        radius: Os2.rCard,
        halo: Os2SlabHalo.corner,
        elevation: Os2SlabElevation.resting,
        padding: const EdgeInsets.symmetric(
          horizontal: Os2.space4,
          vertical: Os2.space4,
        ),
        breath: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Os2Text.caption(
                  record.flightNumber ?? 'BOARDING',
                  color: Os2.travelTone,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Os2Text.headline(
                      from,
                      color: Os2.inkBright,
                      size: 22,
                      weight: FontWeight.w900,
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right_rounded,
                        size: 16, color: Os2.inkLow),
                    const SizedBox(width: 6),
                    Os2Text.headline(
                      to,
                      color: Os2.inkBright,
                      size: 22,
                      weight: FontWeight.w900,
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Os2Text.caption('DEP', color: Os2.inkLow),
                const SizedBox(height: 4),
                Os2Text.title(
                  record.date.length >= 10
                      ? record.date.substring(5).replaceAll('-', '·')
                      : record.date,
                  color: Os2.inkBright,
                  size: 14,
                ),
              ],
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right_rounded,
                color: Os2.inkLow, size: 18),
          ],
        ),
      ),
    );
  }
}

class _PastLog extends StatelessWidget {
  const _PastLog({required this.records});
  final List<TravelRecord> records;
  @override
  Widget build(BuildContext context) {
    return Os2Slab(
      tone: Os2.travelTone,
      radius: Os2.rCard,
      tier: Os2SlabTier.floor1,
      halo: Os2SlabHalo.none,
      elevation: Os2SlabElevation.flat,
      padding: const EdgeInsets.symmetric(
        horizontal: Os2.space4,
        vertical: Os2.space2,
      ),
      breath: false,
      child: Column(
        children: [
          for (int i = 0; i < records.length; i++) ...[
            _PastRow(record: records[i]),
            if (i < records.length - 1)
              Container(height: 0.5, color: Os2.hairlineSoft),
          ],
        ],
      ),
    );
  }
}

class _PastRow extends StatelessWidget {
  const _PastRow({required this.record});
  final TravelRecord record;

  String _airportCode(String s) {
    final upper = s.toUpperCase();
    final m = RegExp(r'\b[A-Z]{3}\b').firstMatch(upper);
    return m?.group(0) ?? s.substring(0, s.length.clamp(0, 3)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Os2.space3),
      child: Row(
        children: [
          Os2Text.monoCap(
            '${_airportCode(record.from)} \u2192 ${_airportCode(record.to)}',
            color: Os2.inkBright,
            size: 13,
          ),
          const Spacer(),
          Os2Text.caption(
            record.date.length >= 10
                ? record.date.substring(0, 10)
                : record.date,
            color: Os2.inkLow,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────── Journey timeline

class _JourneyTimeline extends StatelessWidget {
  const _JourneyTimeline({required this.record});
  final TravelRecord record;

  @override
  Widget build(BuildContext context) {
    final from = record.from.length > 20
        ? record.from.substring(0, 20)
        : record.from;
    final to =
        record.to.length > 20 ? record.to.substring(0, 20) : record.to;
    return Os2Slab(
      tone: Os2.travelTone,
      tier: Os2SlabTier.floor2,
      radius: Os2.rCard,
      halo: Os2SlabHalo.corner,
      elevation: Os2SlabElevation.resting,
      padding: const EdgeInsets.all(Os2.space4),
      breath: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Os2DividerRule(
            eyebrow: 'JOURNEY ORCHESTRATION',
            tone: Os2.travelTone,
            trailing: 'AGI · LIVE',
          ),
          const SizedBox(height: Os2.space3),
          Os2Timeline(
            tone: Os2.travelTone,
            nodes: [
              Os2TimelineNode(
                title: 'Pack · brief',
                caption: 'Concierge composed your kit · 11 items',
                trailing: 'DONE',
                state: Os2NodeState.settled,
              ),
              Os2TimelineNode(
                title: 'Check-in · $from',
                caption: 'Mobile check-in cleared · seat 14A',
                trailing: 'DONE',
                state: Os2NodeState.settled,
              ),
              Os2TimelineNode(
                title: 'Lounge · Star Alliance',
                caption: 'Access available · 64 / 110 occupancy',
                trailing: 'OPEN',
                state: Os2NodeState.active,
              ),
              Os2TimelineNode(
                title: 'Boarding · Gate B14',
                caption: 'Group 2 · 16:20 · self-board kiosk',
                trailing: '16:20',
                state: Os2NodeState.pending,
              ),
              Os2TimelineNode(
                title: 'Land · $to',
                caption: 'Customs queue · ride staged · 21°C',
                trailing: '19:32',
                state: Os2NodeState.pending,
              ),
              Os2TimelineNode(
                title: 'Stay · concierge handoff',
                caption: 'Hotel notified · contactless check-in',
                trailing: '21:00',
                state: Os2NodeState.pending,
              ),
            ],
          ),
          const SizedBox(height: Os2.space3),
          Os2LabelledPipStack(
            label: 'STAGES COMPLETE',
            tone: Os2.travelTone,
            trailing: '2 / 6',
            pips: const [
              Os2PipState.settled,
              Os2PipState.settled,
              Os2PipState.active,
              Os2PipState.pending,
              Os2PipState.pending,
              Os2PipState.pending,
            ],
          ),
          const SizedBox(height: Os2.space3),
          Os2Ribbon(
            label: 'LIVE',
            value: 'GATE B14 · 16:20',
            tone: Os2.signalLive,
            trailing: 'BOARDING IN 2H 12M',
          ),
        ],
      ),
    );
  }
}
