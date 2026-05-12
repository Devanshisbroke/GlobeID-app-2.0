import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../motion/os2_breathing.dart';
import '../os2_tokens.dart';
import '../primitives/os2_action_card.dart';
import '../primitives/os2_beacon.dart';
import '../primitives/os2_divider_rule.dart';
import '../primitives/os2_glyph_halo.dart';
import '../primitives/os2_info_strip.dart';
import '../primitives/os2_magnetic.dart';
import '../primitives/os2_marquee.dart';
import '../primitives/os2_pip.dart';
import '../primitives/os2_ribbon.dart';
import '../primitives/os2_slab.dart';
import '../primitives/os2_text.dart';
import '../primitives/os2_timeline.dart';

/// OS 2.0 — Copilot agentic surface.
///
/// Predictive concierge with:
///   • a hero "intent listening" plate (breathing AGI orb);
///   • a live agentic suggestion strip (Os2Marquee);
///   • a 6-slot quick-action grid;
///   • a multi-step orchestration timeline (the active intent);
///   • a system status panel (queue depth, audit log).
class Os2CopilotScreen extends ConsumerStatefulWidget {
  const Os2CopilotScreen({super.key});

  @override
  ConsumerState<Os2CopilotScreen> createState() =>
      _Os2CopilotScreenState();
}

class _Os2CopilotScreenState extends ConsumerState<Os2CopilotScreen>
    with TickerProviderStateMixin {
  late final AnimationController _orb = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();

  String _input = '';

  @override
  void dispose() {
    _orb.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Os2.canvas,
      appBar: AppBar(
        backgroundColor: Os2.canvas,
        elevation: 0,
        title: Os2Text.title('Copilot', color: Os2.inkBright, size: 18),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Os2.space4,
                  Os2.space2,
                  Os2.space4,
                  Os2.space3,
                ),
                child: Row(
                  children: [
                    Os2Beacon(
                      label: 'AGI · LISTENING',
                      tone: Os2.pulseTone,
                    ),
                    const Spacer(),
                    Os2Text.monoCap('NEURAL · ONLINE',
                        color: Os2.signalSettled, size: 11),
                  ],
                ),
              ),
              // Hero orb plate.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: AnimatedBuilder(
                  animation: _orb,
                  builder: (_, __) => _HeroOrb(progress: _orb.value),
                ),
              ),
              const SizedBox(height: Os2.space3),
              // Compose input.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _ComposeBar(
                  value: _input,
                  onChange: (v) => setState(() => _input = v),
                  onSubmit: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _input = '');
                  },
                ),
              ),
              const SizedBox(height: Os2.space3),
              // Agentic suggestion strip.
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: Os2.space4),
                child: Os2Marquee(
                  items: [
                    'INTENT · prep arrival ride · pending you',
                    'INTENT · prep eSIM US · auto-armed',
                    'INTENT · hotel keys · synced',
                    'BRIEF · wallet treasury · liquid 87%',
                    'BRIEF · identity audit · passing',
                    'BRIEF · concierge · 12 standing protocols',
                  ],
                  tone: Os2.pulseTone,
                ),
              ),
              const SizedBox(height: Os2.space4),
              // Quick actions grid.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _CopilotQuickActions(),
              ),
              const SizedBox(height: Os2.space5),
              // Active orchestration timeline.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _ActiveOrchestration(),
              ),
              const SizedBox(height: Os2.space5),
              // System status.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _SystemStatus(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroOrb extends StatelessWidget {
  const _HeroOrb({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Os2Slab(
      tone: Os2.pulseTone,
      tier: Os2SlabTier.floor1,
      radius: Os2.rHero,
      halo: Os2SlabHalo.edge,
      elevation: Os2SlabElevation.cinematic,
      padding: const EdgeInsets.symmetric(
        horizontal: Os2.space4,
        vertical: Os2.space5,
      ),
      breath: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SizedBox(
              width: 132,
              height: 132,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(132, 132),
                    painter: _OrbHaloPainter(progress: progress),
                  ),
                  Os2Breathing(
                    minScale: 0.985,
                    maxScale: 1.015,
                    child: Os2GlyphHalo(
                      icon: Icons.auto_awesome_rounded,
                      tone: Os2.pulseTone,
                      size: 88,
                      iconSize: 44,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Os2.space3),
          Os2Text.display(
            'The system is listening.',
            color: Os2.inkBright,
            size: 26,
            align: TextAlign.center,
          ),
          const SizedBox(height: Os2.space1),
          Os2Text.caption(
            'Speak an intent. Or pick one of mine.',
            color: Os2.inkMid,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OrbHaloPainter extends CustomPainter {
  _OrbHaloPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 3; i++) {
      final phase = (progress + i / 3) % 1;
      final r = 30 + phase * 60;
      final alpha = (1 - phase) * 0.35;
      final p = Paint()
        ..color = Os2.pulseTone.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      canvas.drawCircle(center, r, p);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbHaloPainter old) =>
      old.progress != progress;
}

class _ComposeBar extends StatelessWidget {
  const _ComposeBar({
    required this.value,
    required this.onChange,
    required this.onSubmit,
  });
  final String value;
  final void Function(String) onChange;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Os2.space3,
        vertical: Os2.space2,
      ),
      decoration: ShapeDecoration(
        color: Os2.floor2,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(Os2.rCard),
          side: BorderSide(
            color: Os2.hairline,
            width: Os2.strokeFine,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.psychology_alt_rounded,
              color: Os2.pulseTone, size: 18),
          const SizedBox(width: Os2.space2),
          Expanded(
            child: TextField(
              onChanged: onChange,
              cursorColor: Os2.pulseTone,
              style: TextStyle(
                fontSize: 15,
                color: Os2.inkBright,
                letterSpacing: 0.1,
              ),
              decoration: InputDecoration(
                hintText: 'Hand me an intent…',
                hintStyle: TextStyle(
                  color: Os2.inkLow,
                  fontSize: 15,
                  letterSpacing: 0.1,
                ),
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: Os2.space2),
          Os2Magnetic(
            onTap: onSubmit,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Os2.space3,
                vertical: Os2.space2,
              ),
              decoration: ShapeDecoration(
                color: Os2.pulseTone,
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(Os2.rChip),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Os2Text.monoCap('SUMMON',
                      color: Os2.canvas, size: 11),
                  const SizedBox(width: 4),
                  Icon(Icons.send_rounded,
                      color: Os2.canvas, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopilotQuickActions extends StatelessWidget {
  const _CopilotQuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = <_QA>[
      _QA('Plan trip', Icons.tune_rounded, Os2.travelTone),
      _QA('Book hotel', Icons.hotel_rounded, Os2.servicesTone),
      _QA('Get ride', Icons.local_taxi_rounded, Os2.discoverTone),
      _QA('Send money', Icons.send_to_mobile_rounded, Os2.walletTone),
      _QA('Verify ID', Icons.fingerprint_rounded, Os2.identityTone),
      _QA('Emergency', Icons.health_and_safety_rounded, Os2.signalCritical),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Os2DividerRule(
          eyebrow: 'STANDING INTENTS',
          tone: Os2.pulseTone,
          trailing: '${actions.length} READY',
        ),
        const SizedBox(height: Os2.space3),
        for (var i = 0; i < actions.length; i += 3) ...[
          Row(
            children: [
              for (var j = i; j < i + 3 && j < actions.length; j++) ...[
                Expanded(
                  child: Os2ActionCard(
                    title: actions[j].title,
                    icon: actions[j].icon,
                    tone: actions[j].tone,
                    dense: true,
                    onTap: () {
                      HapticFeedback.selectionClick();
                    },
                  ),
                ),
                if (j < i + 2 && j + 1 < actions.length)
                  const SizedBox(width: Os2.space2),
              ],
            ],
          ),
          if (i + 3 < actions.length)
            const SizedBox(height: Os2.space2),
        ],
      ],
    );
  }
}

class _QA {
  const _QA(this.title, this.icon, this.tone);
  final String title;
  final IconData icon;
  final Color tone;
}

class _ActiveOrchestration extends StatelessWidget {
  const _ActiveOrchestration();

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
            eyebrow: 'ACTIVE INTENT',
            tone: Os2.travelTone,
            trailing: 'STEP 3 OF 6',
          ),
          const SizedBox(height: Os2.space3),
          Os2Text.title(
            'Prepare arrival in JFK',
            color: Os2.inkBright,
            size: 18,
          ),
          const SizedBox(height: Os2.space1),
          Os2Text.caption(
            'AGI is orchestrating end-to-end. You\'re in the loop only when '
            'something needs your seal.',
            color: Os2.inkMid,
          ),
          const SizedBox(height: Os2.space3),
          Os2Timeline(
            tone: Os2.travelTone,
            dense: true,
            nodes: const [
              Os2TimelineNode(
                title: 'eSIM \u00b7 US data + voice',
                caption: '10GB / 7 days · auto-activate on touchdown',
                trailing: 'ARMED',
                state: Os2NodeState.settled,
              ),
              Os2TimelineNode(
                title: 'Customs \u00b7 declaration',
                caption: 'Pre-filed via GlobeID · e-Gate cleared',
                trailing: 'CLEARED',
                state: Os2NodeState.settled,
              ),
              Os2TimelineNode(
                title: 'Ride \u00b7 curbside pickup',
                caption: 'Mercedes EQS · WM-2241 · 19:32',
                trailing: 'STAGING',
                state: Os2NodeState.active,
              ),
              Os2TimelineNode(
                title: 'Hotel \u00b7 contactless check-in',
                caption: 'Soma Suites · room 1408 · keys synced',
                trailing: '21:00',
                state: Os2NodeState.pending,
              ),
              Os2TimelineNode(
                title: 'Dinner \u00b7 The Saint',
                caption: 'Concierge held · 4 guests',
                trailing: '20:30',
                state: Os2NodeState.pending,
              ),
              Os2TimelineNode(
                title: 'Sleep \u00b7 do-not-disturb',
                caption: 'Auto-engaged after dinner',
                trailing: '23:30',
                state: Os2NodeState.pending,
              ),
            ],
          ),
          const SizedBox(height: Os2.space3),
          Os2LabelledPipStack(
            label: 'PROGRESS',
            tone: Os2.travelTone,
            pips: const [
              Os2PipState.settled,
              Os2PipState.settled,
              Os2PipState.active,
              Os2PipState.pending,
              Os2PipState.pending,
              Os2PipState.pending,
            ],
            trailing: '3 / 6 STEPS',
          ),
        ],
      ),
    );
  }
}

class _SystemStatus extends StatelessWidget {
  const _SystemStatus();

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
            eyebrow: 'SYSTEM STATUS',
            tone: Os2.servicesTone,
            trailing: 'OK',
          ),
          const SizedBox(height: Os2.space3),
          Os2InfoStrip(
            entries: const [
              Os2InfoEntry(
                icon: Icons.bolt_rounded,
                label: 'INTENTS',
                value: '12 RUNNING',
                tone: Os2.pulseTone,
              ),
              Os2InfoEntry(
                icon: Icons.queue_rounded,
                label: 'QUEUE',
                value: '3 PENDING',
                tone: Os2.travelTone,
              ),
              Os2InfoEntry(
                icon: Icons.history_rounded,
                label: 'AUDIT',
                value: 'PASSING',
                tone: Os2.signalSettled,
              ),
              Os2InfoEntry(
                icon: Icons.memory_rounded,
                label: 'NEURAL',
                value: '64%',
                tone: Os2.identityTone,
              ),
            ],
          ),
          const SizedBox(height: Os2.space3),
          Os2Ribbon(
            label: 'CONCIERGE',
            value: 'STANDING BY',
            tone: Os2.signalSettled,
            trailing: 'AVG 32S',
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
double _orbWave(double t) => 0.5 + 0.5 * math.sin(t * math.pi * 2);
