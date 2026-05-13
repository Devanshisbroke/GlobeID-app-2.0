import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../motion/os2_breathing.dart';
import '../os2_tokens.dart';
import '../primitives/os2_bar.dart';
import '../primitives/os2_beacon.dart';
import '../primitives/os2_chip.dart';
import '../primitives/os2_divider_rule.dart';
import '../primitives/os2_glyph_halo.dart';
import '../primitives/os2_info_strip.dart';
import '../primitives/os2_magnetic.dart';
import '../primitives/os2_pip.dart';
import '../primitives/os2_ribbon.dart';
import '../primitives/os2_slab.dart';
import '../primitives/os2_solari.dart';
import '../primitives/os2_text.dart';
import '../primitives/os2_timeline.dart';

/// OS 2.0 — Boarding pass live.
///
/// Cinematic boarding-pass surface with:
///   • holographic foil hero card (FRA → JFK, LH 401, seat 14A);
///   • live status ribbon ("LIVE · GATE B14 · 16:20");
///   • boarding-group pip stack;
///   • progress bar (group 2 of 5 currently boarding);
///   • departure stage timeline (gate · boarding · onboard · taxi);
///   • crew briefing slab.
class Os2BoardingPassScreen extends ConsumerStatefulWidget {
  const Os2BoardingPassScreen({super.key});

  @override
  ConsumerState<Os2BoardingPassScreen> createState() =>
      _Os2BoardingPassScreenState();
}

class _Os2BoardingPassScreenState extends ConsumerState<Os2BoardingPassScreen>
    with TickerProviderStateMixin {
  late final AnimationController _foil = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat();

  @override
  void dispose() {
    _foil.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Os2.canvas,
      appBar: AppBar(
        backgroundColor: Os2.canvas,
        elevation: 0,
        title: Os2Text.title('Boarding pass',
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
                    Os2Beacon(label: 'LIVE BOARDING', tone: Os2.signalLive),
                    const Spacer(),
                    Os2Magnetic(
                      onTap: () {
                        HapticFeedback.selectionClick();
                      },
                      child: const Os2Chip(
                        label: 'BRIGHTNESS+',
                        icon: Icons.brightness_high_rounded,
                        tone: Os2.identityTone,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Os2.space3),
              // Foil hero card.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: AnimatedBuilder(
                  animation: _foil,
                  builder: (_, __) => _FoilPass(progress: _foil.value),
                ),
              ),
              const SizedBox(height: Os2.space4),
              // Info strip.
              Os2InfoStrip(
                entries: const [
                  Os2InfoEntry(
                    icon: Icons.confirmation_num_rounded,
                    label: 'PNR',
                    value: '7K9X2L',
                    tone: Os2.travelTone,
                  ),
                  Os2InfoEntry(
                    icon: Icons.numbers_rounded,
                    label: 'SEAT',
                    value: '14A',
                    tone: Os2.identityTone,
                  ),
                  Os2InfoEntry(
                    icon: Icons.local_movies_rounded,
                    label: 'CABIN',
                    value: 'PREMIUM',
                    tone: Os2.walletTone,
                  ),
                  Os2InfoEntry(
                    icon: Icons.luggage_rounded,
                    label: 'CHECKED',
                    value: '2 BAGS',
                    tone: Os2.servicesTone,
                  ),
                  Os2InfoEntry(
                    icon: Icons.local_cafe_rounded,
                    label: 'LOUNGE',
                    value: 'STAR',
                    tone: Os2.discoverTone,
                  ),
                ],
              ),
              const SizedBox(height: Os2.space4),
              // Boarding group progress.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _BoardingProgress(),
              ),
              const SizedBox(height: Os2.space4),
              // Departure timeline.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _DepartureTimeline(),
              ),
              const SizedBox(height: Os2.space4),
              // Crew briefing.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _CrewBriefing(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoilPass extends StatelessWidget {
  const _FoilPass({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    final shift = math.sin(progress * math.pi * 2);
    return Os2Slab(
      tone: Os2.identityTone,
      tier: Os2SlabTier.floor1,
      radius: Os2.rHero,
      halo: Os2SlabHalo.edge,
      elevation: Os2SlabElevation.cinematic,
      padding: const EdgeInsets.all(Os2.space5),
      breath: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Os2Text.monoCap('LUFTHANSA \u00b7 LH 401',
                  color: Os2.identityTone, size: 11),
              const Spacer(),
              Os2Text.monoCap('PREMIUM ECONOMY',
                  color: Os2.walletTone, size: 11),
            ],
          ),
          const SizedBox(height: Os2.space3),
          // Foil shimmer band.
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                begin: Alignment(-1.0 + shift, 0),
                end: Alignment(1.0 + shift, 0),
                colors: [
                  Os2.identityTone.withValues(alpha: 0.05),
                  Os2.identityTone.withValues(alpha: 0.55),
                  Colors.white.withValues(alpha: 0.85),
                  Os2.walletTone.withValues(alpha: 0.55),
                  Os2.travelTone.withValues(alpha: 0.05),
                ],
                stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
              ),
            ),
          ),
          const SizedBox(height: Os2.space4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Os2Text.monoCap('FROM',
                        color: Os2.inkMid, size: 10),
                    const SizedBox(height: 4),
                    Os2Text.display('FRA',
                        color: Os2.inkBright, size: 44),
                    const SizedBox(height: 4),
                    Os2Text.caption('Frankfurt · 16:20',
                        color: Os2.inkMid),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Os2GlyphHalo(
                  icon: Icons.flight_takeoff_rounded,
                  tone: Os2.identityTone,
                  size: 48,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Os2Text.monoCap('TO',
                        color: Os2.inkMid, size: 10),
                    const SizedBox(height: 4),
                    Os2Text.display('JFK',
                        color: Os2.inkBright, size: 44),
                    const SizedBox(height: 4),
                    Os2Text.caption('New York · 19:32',
                        color: Os2.inkMid),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Os2.space4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _FoilStat(label: 'GATE', value: 'B14'),
              _FoilStat(label: 'SEAT', value: '14A'),
              _FoilStat(label: 'GROUP', value: '2'),
              _FoilStat(label: 'PNR', value: '7K9X2L'),
            ],
          ),
          const SizedBox(height: Os2.space4),
          Os2Breathing(
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: Os2.space3,
                horizontal: Os2.space4,
              ),
              decoration: ShapeDecoration(
                color: Os2.canvas,
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(Os2.rChip),
                  side: BorderSide(
                    color: Os2.identityTone.withValues(alpha: 0.40),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_2_rounded,
                      color: Os2.identityTone, size: 18),
                  const SizedBox(width: Os2.space2),
                  Os2Text.monoCap(
                    'HMAC \u00b7 BOARDING SIGNED \u00b7 LIVE',
                    color: Os2.identityTone,
                    size: 11,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoilStat extends StatelessWidget {
  const _FoilStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Os2Text.monoCap(label, color: Os2.inkMid, size: Os2.textMicro),
        const SizedBox(height: 2),
        Os2Solari(text: value, fontSize: 18, cellWidth: 16, cellHeight: 24),
      ],
    );
  }
}

class _BoardingProgress extends StatelessWidget {
  const _BoardingProgress();

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
            eyebrow: 'BOARDING PROGRESS',
            tone: Os2.travelTone,
            trailing: 'GROUP 2 OF 5',
          ),
          const SizedBox(height: Os2.space3),
          Os2BarStack(
            tone: Os2.travelTone,
            entries: const [
              Os2BarEntry(label: 'Group 1 · Priority', value: 1.0),
              Os2BarEntry(label: 'Group 2 · Premium', value: 0.62),
              Os2BarEntry(label: 'Group 3 · Main A', value: 0.0),
              Os2BarEntry(label: 'Group 4 · Main B', value: 0.0),
              Os2BarEntry(label: 'Group 5 · Standby', value: 0.0),
            ],
          ),
          const SizedBox(height: Os2.space3),
          Os2LabelledPipStack(
            label: 'PIPELINE',
            tone: Os2.travelTone,
            pips: const [
              Os2PipState.settled,
              Os2PipState.active,
              Os2PipState.pending,
              Os2PipState.pending,
              Os2PipState.pending,
            ],
            trailing: '01H 36M LEFT',
          ),
          const SizedBox(height: Os2.space3),
          Os2Ribbon(
            label: 'LIVE',
            value: 'GATE B14 \u00b7 16:20',
            tone: Os2.signalLive,
            trailing: 'BOARDING NOW',
          ),
        ],
      ),
    );
  }
}

class _DepartureTimeline extends StatelessWidget {
  const _DepartureTimeline();

  @override
  Widget build(BuildContext context) {
    return Os2Slab(
      tone: Os2.signalLive,
      tier: Os2SlabTier.floor2,
      radius: Os2.rCard,
      halo: Os2SlabHalo.corner,
      padding: const EdgeInsets.all(Os2.space4),
      breath: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Os2DividerRule(
            eyebrow: 'DEPARTURE STAGE',
            tone: Os2.signalLive,
            trailing: 'LIVE',
          ),
          const SizedBox(height: Os2.space3),
          Os2Timeline(
            tone: Os2.signalLive,
            dense: true,
            nodes: const [
              Os2TimelineNode(
                title: 'Gate open · B14',
                caption: 'Lufthansa LH 401 · 16:00',
                trailing: 'DONE',
                state: Os2NodeState.settled,
              ),
              Os2TimelineNode(
                title: 'Boarding · Group 2',
                caption: 'Premium cabin · self-board kiosk',
                trailing: 'LIVE',
                state: Os2NodeState.active,
              ),
              Os2TimelineNode(
                title: 'Cabin sealed',
                caption: 'Door close · cross-check · 16:50',
                trailing: '16:50',
                state: Os2NodeState.pending,
              ),
              Os2TimelineNode(
                title: 'Pushback · taxi',
                caption: 'Runway 25R · departure slot 17:08',
                trailing: '17:08',
                state: Os2NodeState.pending,
              ),
              Os2TimelineNode(
                title: 'Wheels up',
                caption: 'Climb · westbound · 9h 12m',
                trailing: '17:20',
                state: Os2NodeState.pending,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CrewBriefing extends StatelessWidget {
  const _CrewBriefing();

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
            eyebrow: 'CREW BRIEFING',
            tone: Os2.pulseTone,
            trailing: 'LH 401',
          ),
          const SizedBox(height: Os2.space3),
          _CrewRow(
            icon: Icons.person_rounded,
            title: 'Capt. R. Müller · 14 years on type',
            sub: 'Pre-flight signed · 16:08',
            tone: Os2.identityTone,
          ),
          const SizedBox(height: Os2.space2),
          _CrewRow(
            icon: Icons.air_rounded,
            title: 'Wind ATL · 240/85 westbound',
            sub: 'Track adjusted · ETA holds',
            tone: Os2.travelTone,
          ),
          const SizedBox(height: Os2.space2),
          _CrewRow(
            icon: Icons.restaurant_menu_rounded,
            title: 'Meal · vegetarian premium',
            sub: 'Pre-selected · 1st service',
            tone: Os2.walletTone,
          ),
          const SizedBox(height: Os2.space2),
          _CrewRow(
            icon: Icons.shield_rounded,
            title: 'Safety · upgraded life-vest demo',
            sub: 'Pre-flight roll-call complete',
            tone: Os2.signalSettled,
          ),
        ],
      ),
    );
  }
}

class _CrewRow extends StatelessWidget {
  const _CrewRow({
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
        Os2GlyphHalo(icon: icon, tone: tone, size: 32),
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
      ],
    );
  }
}
