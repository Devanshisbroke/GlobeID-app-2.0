import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../os2_tokens.dart';
import '../primitives/os2_beacon.dart';
import '../primitives/os2_dial.dart';
import '../primitives/os2_divider_rule.dart';
import '../primitives/os2_glyph_halo.dart';
import '../primitives/os2_info_strip.dart';
import '../primitives/os2_pip.dart';
import '../primitives/os2_ribbon.dart';
import '../primitives/os2_slab.dart';
import '../primitives/os2_solari.dart';
import '../primitives/os2_text.dart';
import '../primitives/os2_timeline.dart';

/// OS 2.0 — Airport orchestrator.
///
/// Cinematic seven-stage airport experience:
///   1. Curbside arrival
///   2. Check-in / bag drop
///   3. Security & screening
///   4. Border / customs
///   5. Airside · lounge
///   6. Gate · boarding
///   7. Onboard
///
/// Each stage shows a Solari clock, dial gauge (queue / congestion),
/// info strip (gate / terminal / time-to-board), ribbon (live status),
/// and a milestone pip stack.
class Os2AirportOrchestrator extends ConsumerStatefulWidget {
  const Os2AirportOrchestrator({super.key});

  @override
  ConsumerState<Os2AirportOrchestrator> createState() =>
      _Os2AirportOrchestratorState();
}

class _Os2AirportOrchestratorState
    extends ConsumerState<Os2AirportOrchestrator> {
  int _stage = 4; // Currently airside · lounge.

  static const _stages = <_AirportStage>[
    _AirportStage(
      title: 'Curbside arrival',
      caption: 'Drop-off · 02 lane',
      icon: Icons.local_taxi_rounded,
      tone: Os2.discoverTone,
      queue: 18,
      eta: '03:14',
    ),
    _AirportStage(
      title: 'Check-in · bag drop',
      caption: 'Lufthansa premium · row 12',
      icon: Icons.luggage_rounded,
      tone: Os2.servicesTone,
      queue: 32,
      eta: '02:48',
    ),
    _AirportStage(
      title: 'Security & screening',
      caption: 'Trusted Traveler · Lane 4',
      icon: Icons.security_rounded,
      tone: Os2.signalLive,
      queue: 6,
      eta: '02:22',
    ),
    _AirportStage(
      title: 'Border · customs',
      caption: 'e-Gate · auto-cleared',
      icon: Icons.travel_explore_rounded,
      tone: Os2.identityTone,
      queue: 12,
      eta: '01:46',
    ),
    _AirportStage(
      title: 'Airside · lounge',
      caption: 'Star Alliance · seat S-12',
      icon: Icons.local_cafe_rounded,
      tone: Os2.walletTone,
      queue: 64,
      eta: '01:18',
    ),
    _AirportStage(
      title: 'Gate · boarding',
      caption: 'B14 · Group 2',
      icon: Icons.airline_seat_recline_extra_rounded,
      tone: Os2.travelTone,
      queue: 86,
      eta: '00:24',
    ),
    _AirportStage(
      title: 'Onboard',
      caption: 'Seat 14A · door closed',
      icon: Icons.flight_takeoff_rounded,
      tone: Os2.signalSettled,
      queue: 100,
      eta: '00:00',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final stage = _stages[_stage];
    return Scaffold(
      backgroundColor: Os2.canvas,
      appBar: AppBar(
        backgroundColor: Os2.canvas,
        elevation: 0,
        title: Os2Text.title('Airport orchestrator',
            color: Os2.inkBright, size: 18),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.only(bottom: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Os2.space4,
                  Os2.space2,
                  Os2.space4,
                  Os2.space2,
                ),
                child: Row(
                  children: [
                    Os2Beacon(label: 'LIVE · FRA T1', tone: stage.tone),
                    const Spacer(),
                    Os2Text.monoCap(
                      'STAGE ${_stage + 1} / ${_stages.length}',
                      color: Os2.inkMid,
                      size: 11,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Os2.space3),
              // Hero focal slab.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _StageHero(stage: stage),
              ),
              const SizedBox(height: Os2.space4),
              // Quick info strip.
              Os2InfoStrip(
                entries: const [
                  Os2InfoEntry(
                    icon: Icons.access_time_rounded,
                    label: 'BOARDING',
                    value: '16:20',
                    tone: Os2.signalLive,
                  ),
                  Os2InfoEntry(
                    icon: Icons.flight_takeoff_rounded,
                    label: 'GATE',
                    value: 'B14',
                    tone: Os2.travelTone,
                  ),
                  Os2InfoEntry(
                    icon: Icons.directions_walk_rounded,
                    label: 'WALK',
                    value: '12 MIN',
                    tone: Os2.discoverTone,
                  ),
                  Os2InfoEntry(
                    icon: Icons.access_alarm_rounded,
                    label: 'BUFFER',
                    value: '01H 18M',
                    tone: Os2.signalSettled,
                  ),
                ],
              ),
              const SizedBox(height: Os2.space4),
              // Timeline.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _StageTimeline(
                  stages: _stages,
                  current: _stage,
                  onSelect: (i) => setState(() => _stage = i),
                ),
              ),
              const SizedBox(height: Os2.space5),
              // Live operations slab.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _LiveOperations(),
              ),
              const SizedBox(height: Os2.space5),
              // Concierge slab.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _ConciergeSlab(stage: stage),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AirportStage {
  const _AirportStage({
    required this.title,
    required this.caption,
    required this.icon,
    required this.tone,
    required this.queue,
    required this.eta,
  });

  final String title;
  final String caption;
  final IconData icon;
  final Color tone;
  final int queue; // 0–100, % occupancy / progress.
  final String eta;
}

class _StageHero extends StatelessWidget {
  const _StageHero({required this.stage});
  final _AirportStage stage;

  @override
  Widget build(BuildContext context) {
    return Os2Slab(
      tone: stage.tone,
      tier: Os2SlabTier.floor1,
      radius: Os2.rHero,
      halo: Os2SlabHalo.edge,
      elevation: Os2SlabElevation.cinematic,
      padding: const EdgeInsets.all(Os2.space4),
      breath: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Os2GlyphHalo(icon: stage.icon, tone: stage.tone, size: 56),
              const SizedBox(width: Os2.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Os2Text.monoCap(
                      'STAGE \u00b7 ${stage.eta}',
                      color: stage.tone,
                      size: 11,
                    ),
                    const SizedBox(height: 4),
                    Os2Text.title(stage.title,
                        color: Os2.inkBright, size: 20),
                    const SizedBox(height: 2),
                    Os2Text.caption(stage.caption, color: Os2.inkMid),
                  ],
                ),
              ),
              Os2Solari(text: stage.eta, fontSize: 28),
            ],
          ),
          const SizedBox(height: Os2.space4),
          Row(
            children: [
              Expanded(
                child: Os2Dial(
                  value: stage.queue / 100.0,
                  tone: stage.tone,
                  label: 'CONGESTION',
                  center: Os2Text.monoCap('${stage.queue}%', color: Os2.inkBright, size: Os2.textRg),
                ),
              ),
              const SizedBox(width: Os2.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Os2Ribbon(
                      label: 'LIVE',
                      value: stage.title.toUpperCase(),
                      tone: stage.tone,
                      trailing: stage.eta,
                    ),
                    const SizedBox(height: Os2.space3),
                    Os2LabelledPipStack(
                      label: 'PROGRESS',
                      tone: stage.tone,
                      pips: _progressPips(stage.queue),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Os2PipState> _progressPips(int q) {
    final filled = (q / 100 * 7).round().clamp(0, 7);
    return List.generate(7, (i) {
      if (i < filled) return Os2PipState.settled;
      if (i == filled) return Os2PipState.active;
      return Os2PipState.pending;
    });
  }
}

class _StageTimeline extends StatelessWidget {
  const _StageTimeline({
    required this.stages,
    required this.current,
    required this.onSelect,
  });

  final List<_AirportStage> stages;
  final int current;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    return Os2Slab(
      tone: Os2.travelTone,
      tier: Os2SlabTier.floor2,
      radius: Os2.rCard,
      halo: Os2SlabHalo.corner,
      padding: const EdgeInsets.all(Os2.space4),
      breath: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Os2DividerRule(
            eyebrow: 'TIMELINE',
            tone: Os2.travelTone,
            trailing: 'ORCHESTRATING',
          ),
          const SizedBox(height: Os2.space3),
          Os2Timeline(
            tone: Os2.travelTone,
            nodes: [
              for (var i = 0; i < stages.length; i++)
                Os2TimelineNode(
                  title: stages[i].title,
                  caption: stages[i].caption,
                  trailing: stages[i].eta,
                  state: i < current
                      ? Os2NodeState.settled
                      : i == current
                          ? Os2NodeState.active
                          : Os2NodeState.pending,
                  onTap: () => onSelect(i),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveOperations extends StatelessWidget {
  const _LiveOperations();

  @override
  Widget build(BuildContext context) {
    return Os2Slab(
      tone: Os2.servicesTone,
      tier: Os2SlabTier.floor2,
      radius: Os2.rCard,
      halo: Os2SlabHalo.corner,
      padding: const EdgeInsets.all(Os2.space4),
      breath: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Os2DividerRule(
            eyebrow: 'LIVE OPS',
            tone: Os2.servicesTone,
            trailing: 'AGI · WATCHING',
          ),
          const SizedBox(height: Os2.space3),
          Row(
            children: [
              Expanded(
                child: Os2Dial(
                  value: 0.42,
                  tone: Os2.servicesTone,
                  label: 'LANE 4 · TT',
                  center: Os2Text.monoCap('42%', color: Os2.inkBright, size: Os2.textRg),
                ),
              ),
              const SizedBox(width: Os2.space3),
              Expanded(
                child: Os2Dial(
                  value: 0.86,
                  tone: Os2.travelTone,
                  label: 'B-PIER',
                  center: Os2Text.monoCap('86%', color: Os2.inkBright, size: Os2.textRg),
                ),
              ),
              const SizedBox(width: Os2.space3),
              Expanded(
                child: Os2Dial(
                  value: 0.64,
                  tone: Os2.walletTone,
                  label: 'LOUNGE',
                  center: Os2Text.monoCap('64%', color: Os2.inkBright, size: Os2.textRg),
                ),
              ),
            ],
          ),
          const SizedBox(height: Os2.space3),
          Os2Ribbon(
            label: 'SAFETY',
            value: 'ALL CLEAR',
            tone: Os2.signalSettled,
            trailing: 'NO INCIDENTS',
          ),
          const SizedBox(height: Os2.space2),
          Os2Ribbon(
            label: 'OPS BRIEF',
            value: 'NORMAL · OTP 92%',
            tone: Os2.servicesTone,
            trailing: 'ON-TIME',
          ),
        ],
      ),
    );
  }
}

class _ConciergeSlab extends StatelessWidget {
  const _ConciergeSlab({required this.stage});
  final _AirportStage stage;

  @override
  Widget build(BuildContext context) {
    return Os2Slab(
      tone: Os2.pulseTone,
      tier: Os2SlabTier.floor2,
      radius: Os2.rCard,
      halo: Os2SlabHalo.corner,
      padding: const EdgeInsets.all(Os2.space4),
      breath: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Os2DividerRule(
            eyebrow: 'CONCIERGE',
            tone: Os2.pulseTone,
            trailing: 'STANDBY',
          ),
          const SizedBox(height: Os2.space3),
          _ConciergeRow(
            icon: Icons.local_taxi_rounded,
            title: 'Ride staged at curbside · 19:32',
            sub: 'GlobeID Lift · Mercedes EQS · plate WM-2241',
            tone: Os2.discoverTone,
          ),
          const SizedBox(height: Os2.space2),
          _ConciergeRow(
            icon: Icons.hotel_rounded,
            title: 'Hotel notified · contactless check-in',
            sub: 'Soma Suites \u00b7 room 1408 \u00b7 keys synced',
            tone: Os2.servicesTone,
          ),
          const SizedBox(height: Os2.space2),
          _ConciergeRow(
            icon: Icons.sim_card_rounded,
            title: 'eSIM provisioned · auto-activate on touchdown',
            sub: 'US data + voice \u00b7 10GB \u00b7 7 days',
            tone: Os2.identityTone,
          ),
        ],
      ),
    );
  }
}

class _ConciergeRow extends StatelessWidget {
  const _ConciergeRow({
    required this.icon,
    required this.title,
    required this.sub,
    required this.tone,
  });
  final IconData icon;
  final String title;
  final String sub;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Os2GlyphHalo(icon: icon, tone: tone, size: 36),
        const SizedBox(width: Os2.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Os2Text.title(title, color: Os2.inkBright, size: Os2.textRg),
              const SizedBox(height: 2),
              Os2Text.caption(sub, color: Os2.inkMid),
            ],
          ),
        ),
        const SizedBox(width: Os2.space2),
        Os2Text.monoCap('\u2192', color: tone, size: Os2.textMd),
      ],
    );
  }
}

// Used for ambient halo math; left as a tiny safe helper.
// ignore: unused_element
double _haloPulse(double t) => 0.5 + 0.5 * math.sin(t * math.pi * 2);
