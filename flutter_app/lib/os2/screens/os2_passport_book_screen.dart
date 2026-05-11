import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../motion/os2_breathing.dart';
import '../os2_tokens.dart';
import '../primitives/os2_beacon.dart';
import '../primitives/os2_divider_rule.dart';
import '../primitives/os2_info_strip.dart';
import '../primitives/os2_magnetic.dart';
import '../primitives/os2_micro_meter.dart';
import '../primitives/os2_pip.dart';
import '../primitives/os2_progress_arc.dart';
import '../primitives/os2_ribbon.dart';
import '../primitives/os2_slab.dart';
import '../primitives/os2_status_pill.dart';
import '../primitives/os2_text.dart';
import '../primitives/os2_timeline.dart';

/// OS 2.0 — Passport book.
///
/// Foil-grade sovereign-identity document screen:
///   • Cover foil hero (rotating sheen, breathing seal);
///   • Identity claim slab (name, DOB, nationality, ID#);
///   • Issuer & verification slab (chain of cross-signs + meters);
///   • Visa wall (4 active visas as squircle tiles);
///   • Audit trail (timeline of issuance & re-verifications);
///   • Trust posture ribbon.
class Os2PassportBookScreen extends ConsumerStatefulWidget {
  const Os2PassportBookScreen({super.key});

  @override
  ConsumerState<Os2PassportBookScreen> createState() =>
      _Os2PassportBookScreenState();
}

class _Os2PassportBookScreenState extends ConsumerState<Os2PassportBookScreen>
    with TickerProviderStateMixin {
  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 11),
  )..repeat();

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Os2.canvas,
      appBar: AppBar(
        backgroundColor: Os2.canvas,
        elevation: 0,
        title: Os2Text.title('Passport book',
            color: Os2.inkBright, size: 18),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Os2.space2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: Row(
                  children: [
                    Os2Beacon(
                      label: 'SOVEREIGN \u00b7 SEALED',
                      tone: Os2.identityTone,
                    ),
                    const Spacer(),
                    Os2StatusPill(
                      label: 'AUDIT',
                      value: 'PASSING',
                      tone: Os2.signalSettled,
                      dense: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Os2.space3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: AnimatedBuilder(
                  animation: _sheen,
                  builder: (_, __) => _PassportCover(progress: _sheen.value),
                ),
              ),
              const SizedBox(height: Os2.space4),
              Os2InfoStrip(
                entries: const [
                  Os2InfoEntry(
                    icon: Icons.flag_rounded,
                    label: 'NATION',
                    value: 'IND',
                    tone: Os2.identityTone,
                  ),
                  Os2InfoEntry(
                    icon: Icons.numbers_rounded,
                    label: 'ID #',
                    value: 'GLB-1024-7XK7',
                    tone: Os2.travelTone,
                  ),
                  Os2InfoEntry(
                    icon: Icons.calendar_today_rounded,
                    label: 'ISSUED',
                    value: '2022-08-14',
                    tone: Os2.servicesTone,
                  ),
                  Os2InfoEntry(
                    icon: Icons.event_busy_rounded,
                    label: 'EXPIRES',
                    value: '2032-08-14',
                    tone: Os2.signalSettled,
                  ),
                  Os2InfoEntry(
                    icon: Icons.workspace_premium_rounded,
                    label: 'TIER',
                    value: 'AVIATOR',
                    tone: Os2.walletTone,
                  ),
                ],
              ),
              const SizedBox(height: Os2.space4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _IssuerSlab(),
              ),
              const SizedBox(height: Os2.space4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _VisaWall(),
              ),
              const SizedBox(height: Os2.space4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _AuditTrail(),
              ),
              const SizedBox(height: Os2.space4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: Os2Ribbon(
                  label: 'TRUST POSTURE',
                  value: 'CROSS-SIGNED \u00b7 12 / 12',
                  tone: Os2.identityTone,
                  trailing: 'SEALED',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PassportCover extends StatelessWidget {
  const _PassportCover({required this.progress});
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
              Os2Text.monoCap('GLOBEID PASSPORT',
                  color: Os2.identityTone, size: 11),
              const Spacer(),
              Os2Text.monoCap('REPUBLIC OF EARTH',
                  color: Os2.inkLow, size: 11),
            ],
          ),
          const SizedBox(height: Os2.space4),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Os2.identityTone.withValues(alpha: 0.30),
                        Os2.identityTone.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(
                      color: Os2.identityTone.withValues(alpha: 0.45),
                      width: 1,
                    ),
                  ),
                ),
                Os2Breathing(
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: Os2.identityTone,
                    size: 72,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Os2.space3),
          // Foil shimmer.
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                begin: Alignment(-1.0 + shift, 0),
                end: Alignment(1.0 + shift, 0),
                colors: [
                  Os2.identityTone.withValues(alpha: 0.05),
                  Os2.identityTone.withValues(alpha: 0.50),
                  Colors.white.withValues(alpha: 0.80),
                  Os2.walletTone.withValues(alpha: 0.50),
                  Os2.travelTone.withValues(alpha: 0.05),
                ],
                stops: const [0, 0.3, 0.5, 0.7, 1],
              ),
            ),
          ),
          const SizedBox(height: Os2.space3),
          Os2Text.display('Devansh Bhardwaj',
              color: Os2.inkBright, size: 28, align: TextAlign.center),
          const SizedBox(height: 4),
          Os2Text.caption('Born 1997 \u00b7 Jaipur, India',
              color: Os2.inkMid, align: TextAlign.center),
          const SizedBox(height: Os2.space3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Os2StatusPill(
                label: 'BIOMETRIC',
                value: 'SEALED',
                tone: Os2.identityTone,
                dense: true,
              ),
              const SizedBox(width: Os2.space2),
              Os2StatusPill(
                label: 'CHAIN',
                value: 'VERIFIED',
                tone: Os2.signalSettled,
                dense: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IssuerSlab extends StatelessWidget {
  const _IssuerSlab();

  @override
  Widget build(BuildContext context) {
    return Os2Slab(
      tone: Os2.identityTone,
      tier: Os2SlabTier.floor2,
      radius: Os2.rCard,
      halo: Os2SlabHalo.corner,
      padding: const EdgeInsets.all(Os2.space4),
      breath: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Os2DividerRule(
            eyebrow: 'ISSUER CROSS-SIGN',
            tone: Os2.identityTone,
            trailing: '12 / 12',
          ),
          const SizedBox(height: Os2.space3),
          Row(
            children: [
              Os2ProgressArc(
                value: 1.0,
                tone: Os2.identityTone,
                diameter: 72,
                label: 'CROSS-SIGNS',
                center: Os2Text.monoCap('12/12',
                    color: Os2.inkBright, size: 12),
              ),
              const SizedBox(width: Os2.space3),
              Os2ProgressArc(
                value: 0.92,
                tone: Os2.signalSettled,
                diameter: 72,
                label: 'AUDIT SCORE',
                center: Os2Text.monoCap('92',
                    color: Os2.inkBright, size: 12),
              ),
              const SizedBox(width: Os2.space3),
              Os2ProgressArc(
                value: 0.74,
                tone: Os2.walletTone,
                diameter: 72,
                label: 'KEY ROTATION',
                center: Os2Text.monoCap('74%',
                    color: Os2.inkBright, size: 12),
              ),
            ],
          ),
          const SizedBox(height: Os2.space4),
          Os2MicroMeter(
            label: 'CHAIN',
            value: 0.86,
            tone: Os2.identityTone,
            trailing: '86%',
          ),
          const SizedBox(height: Os2.space2),
          Os2MicroMeter(
            label: 'BIOM',
            value: 0.94,
            tone: Os2.signalSettled,
            trailing: '94%',
          ),
          const SizedBox(height: Os2.space2),
          Os2MicroMeter(
            label: 'DOCS',
            value: 0.68,
            tone: Os2.servicesTone,
            trailing: '68%',
          ),
          const SizedBox(height: Os2.space2),
          Os2MicroMeter(
            label: 'TRAVEL',
            value: 0.81,
            tone: Os2.travelTone,
            trailing: '81%',
          ),
        ],
      ),
    );
  }
}

class _VisaWall extends StatelessWidget {
  const _VisaWall();

  @override
  Widget build(BuildContext context) {
    final visas = const [
      _Visa('JP', '\ud83c\uddef\ud83c\uddf5', 'Japan', '90D'),
      _Visa('US', '\ud83c\uddfa\ud83c\uddf8', 'United States', '5Y'),
      _Visa('GB', '\ud83c\uddec\ud83c\udde7', 'United Kingdom', '6M'),
      _Visa('SG', '\ud83c\uddf8\ud83c\uddec', 'Singapore', '30D'),
    ];
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
            eyebrow: 'VISA WALL',
            tone: Os2.servicesTone,
            trailing: '4 ACTIVE',
          ),
          const SizedBox(height: Os2.space3),
          Row(
            children: [
              for (var i = 0; i < visas.length; i++) ...[
                Expanded(child: _VisaTile(v: visas[i])),
                if (i < visas.length - 1) const SizedBox(width: Os2.space2),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Visa {
  const _Visa(this.code, this.flag, this.name, this.length);
  final String code;
  final String flag;
  final String name;
  final String length;
}

class _VisaTile extends StatelessWidget {
  const _VisaTile({required this.v});
  final _Visa v;

  @override
  Widget build(BuildContext context) {
    return Os2Magnetic(
      onTap: () {
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.all(Os2.space2),
        decoration: ShapeDecoration(
          color: Os2.floor2,
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(Os2.rChip),
            side: BorderSide(
              color: Os2.servicesTone.withValues(alpha: 0.30),
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            Text(v.flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 2),
            Os2Text.monoCap(v.code, color: Os2.inkBright, size: 11),
            const SizedBox(height: 2),
            Os2Text.monoCap(v.length, color: Os2.servicesTone, size: 9),
          ],
        ),
      ),
    );
  }
}

class _AuditTrail extends StatelessWidget {
  const _AuditTrail();

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
            eyebrow: 'AUDIT TRAIL',
            tone: Os2.travelTone,
            trailing: 'LAST 30D',
          ),
          const SizedBox(height: Os2.space3),
          Os2Timeline(
            tone: Os2.travelTone,
            dense: true,
            nodes: const [
              Os2TimelineNode(
                title: 'Issuer cross-sign \u00b7 GovChain',
                caption: 'Re-verified · key 0x9e..a1',
                trailing: '02D',
                state: Os2NodeState.settled,
              ),
              Os2TimelineNode(
                title: 'Trusted Traveler enrol \u00b7 GLBL',
                caption: 'NEXUS / Global Entry · 5Y',
                trailing: '06D',
                state: Os2NodeState.settled,
              ),
              Os2TimelineNode(
                title: 'Biometric re-seal \u00b7 face vault',
                caption: 'Liveness score 98.2',
                trailing: '12D',
                state: Os2NodeState.settled,
              ),
              Os2TimelineNode(
                title: 'Document refresh \u00b7 birth certificate',
                caption: 'Apostilled \u00b7 chain attest',
                trailing: '24D',
                state: Os2NodeState.settled,
              ),
              Os2TimelineNode(
                title: 'Visa fetch \u00b7 SG entry pass',
                caption: '30-day single \u00b7 auto-issued',
                trailing: '29D',
                state: Os2NodeState.active,
              ),
            ],
          ),
          const SizedBox(height: Os2.space3),
          Os2LabelledPipStack(
            label: 'STREAK',
            tone: Os2.signalSettled,
            pips: const [
              Os2PipState.settled,
              Os2PipState.settled,
              Os2PipState.settled,
              Os2PipState.settled,
              Os2PipState.settled,
              Os2PipState.settled,
              Os2PipState.active,
            ],
            trailing: '7 D',
          ),
        ],
      ),
    );
  }
}
