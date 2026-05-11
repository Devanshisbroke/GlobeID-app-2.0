import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../os2_tokens.dart';
import '../primitives/os2_action_card.dart';
import '../primitives/os2_beacon.dart';
import '../primitives/os2_divider_rule.dart';
import '../primitives/os2_info_strip.dart';
import '../primitives/os2_micro_meter.dart';
import '../primitives/os2_pip.dart';
import '../primitives/os2_progress_arc.dart';
import '../primitives/os2_ribbon.dart';
import '../primitives/os2_slab.dart';
import '../primitives/os2_status_pill.dart';
import '../primitives/os2_text.dart';
import '../primitives/os2_timeline.dart';

/// OS 2.0 — Trust hub.
///
/// Central trust-posture surface combining audit, security, identity
/// signals into one cinematic dashboard. Sections:
///   • Trust score hero (large arc + breakdown);
///   • Signal info strip (chain · biom · sessions · keys);
///   • Cross-sign arc grid;
///   • Threat / posture meters;
///   • Recent verifications timeline;
///   • Standing protocols (action card grid).
class Os2TrustHub extends ConsumerWidget {
  const Os2TrustHub({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Os2.canvas,
      appBar: AppBar(
        backgroundColor: Os2.canvas,
        elevation: 0,
        title: Os2Text.title('Trust', color: Os2.inkBright, size: 18),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Os2.space2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: Row(
                  children: [
                    Os2Beacon(label: 'TRUST \u00b7 SEALED',
                        tone: Os2.identityTone),
                    const Spacer(),
                    Os2StatusPill(
                      label: 'POSTURE',
                      value: 'A+',
                      tone: Os2.signalSettled,
                      dense: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Os2.space3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _TrustHero(),
              ),
              const SizedBox(height: Os2.space4),
              Os2InfoStrip(
                entries: const [
                  Os2InfoEntry(
                    icon: Icons.fingerprint_rounded,
                    label: 'BIOM',
                    value: '94',
                    tone: Os2.identityTone,
                  ),
                  Os2InfoEntry(
                    icon: Icons.security_rounded,
                    label: 'CHAIN',
                    value: '92',
                    tone: Os2.signalSettled,
                  ),
                  Os2InfoEntry(
                    icon: Icons.devices_rounded,
                    label: 'DEVICES',
                    value: '3 TRUSTED',
                    tone: Os2.travelTone,
                  ),
                  Os2InfoEntry(
                    icon: Icons.key_rounded,
                    label: 'KEYS',
                    value: '12 ACTIVE',
                    tone: Os2.walletTone,
                  ),
                  Os2InfoEntry(
                    icon: Icons.history_toggle_off_rounded,
                    label: 'INCIDENT',
                    value: 'NONE',
                    tone: Os2.signalSettled,
                  ),
                ],
              ),
              const SizedBox(height: Os2.space4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _CrossSignGrid(),
              ),
              const SizedBox(height: Os2.space4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _PostureMeters(),
              ),
              const SizedBox(height: Os2.space4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _RecentVerifications(),
              ),
              const SizedBox(height: Os2.space4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _Protocols(),
              ),
              const SizedBox(height: Os2.space4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: Os2Ribbon(
                  label: 'POSTURE',
                  value: 'CROSS-SIGNED \u00b7 NO INCIDENTS',
                  tone: Os2.signalSettled,
                  trailing: 'A+',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustHero extends StatelessWidget {
  const _TrustHero();

  @override
  Widget build(BuildContext context) {
    return Os2Slab(
      tone: Os2.identityTone,
      tier: Os2SlabTier.floor1,
      radius: Os2.rHero,
      halo: Os2SlabHalo.edge,
      elevation: Os2SlabElevation.cinematic,
      padding: const EdgeInsets.all(Os2.space4),
      breath: true,
      child: Row(
        children: [
          Os2ProgressArc(
            value: 0.92,
            tone: Os2.signalSettled,
            diameter: 120,
            strokeWidth: 6,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Os2Text.display('92', color: Os2.inkBright, size: 30),
                Os2Text.monoCap('TRUST', color: Os2.inkLow, size: 9),
              ],
            ),
          ),
          const SizedBox(width: Os2.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Os2Text.monoCap('SOVEREIGN \u00b7 GLOBEID OS2',
                    color: Os2.identityTone, size: 11),
                const SizedBox(height: 4),
                Os2Text.display('A+ posture',
                    color: Os2.inkBright, size: 22),
                const SizedBox(height: 4),
                Os2Text.caption(
                  'All 12 cross-signs verified. No incidents in 180 days.',
                  color: Os2.inkMid,
                ),
                const SizedBox(height: Os2.space3),
                Os2LabelledPipStack(
                  label: 'AUDIT',
                  tone: Os2.signalSettled,
                  pips: const [
                    Os2PipState.settled,
                    Os2PipState.settled,
                    Os2PipState.settled,
                    Os2PipState.settled,
                    Os2PipState.active,
                  ],
                  trailing: '4 / 5',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CrossSignGrid extends StatelessWidget {
  const _CrossSignGrid();

  @override
  Widget build(BuildContext context) {
    final issuers = const [
      ('GovChain', 'IND', 1.0, Os2.identityTone),
      ('Aadhaar', 'IND', 0.96, Os2.travelTone),
      ('Apostille', 'EU', 0.88, Os2.servicesTone),
      ('GlobalSign', 'CA', 0.92, Os2.walletTone),
      ('Trustline', 'CH', 0.74, Os2.discoverTone),
      ('VaultKey', 'OS2', 1.0, Os2.signalSettled),
    ];
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
            eyebrow: 'CROSS-SIGN GRID',
            tone: Os2.identityTone,
            trailing: '6 ISSUERS',
          ),
          const SizedBox(height: Os2.space3),
          for (var row = 0; row < 2; row++) ...[
            Row(
              children: [
                for (var col = 0; col < 3; col++) ...[
                  Expanded(
                    child: _IssuerTile(
                      name: issuers[row * 3 + col].$1,
                      tag: issuers[row * 3 + col].$2,
                      value: issuers[row * 3 + col].$3,
                      tone: issuers[row * 3 + col].$4,
                    ),
                  ),
                  if (col < 2) const SizedBox(width: Os2.space2),
                ],
              ],
            ),
            if (row == 0) const SizedBox(height: Os2.space2),
          ],
        ],
      ),
    );
  }
}

class _IssuerTile extends StatelessWidget {
  const _IssuerTile({
    required this.name,
    required this.tag,
    required this.value,
    required this.tone,
  });
  final String name;
  final String tag;
  final double value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space3),
      decoration: ShapeDecoration(
        color: Os2.floor2,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(Os2.rChip),
          side: BorderSide(
            color: tone.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Os2Text.monoCap(tag, color: tone, size: 9),
          const SizedBox(height: 2),
          Os2Text.title(name, color: Os2.inkBright, size: 13, maxLines: 1),
          const SizedBox(height: Os2.space2),
          Os2ProgressArc(
            value: value,
            tone: tone,
            diameter: 48,
            strokeWidth: 3,
            center: Os2Text.monoCap(
              '${(value * 100).round()}',
              color: Os2.inkBright,
              size: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostureMeters extends StatelessWidget {
  const _PostureMeters();
  @override
  Widget build(BuildContext context) {
    return Os2Slab(
      tone: Os2.signalSettled,
      tier: Os2SlabTier.floor2,
      radius: Os2.rCard,
      halo: Os2SlabHalo.corner,
      padding: const EdgeInsets.all(Os2.space4),
      breath: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Os2DividerRule(
            eyebrow: 'POSTURE METERS',
            tone: Os2.signalSettled,
            trailing: 'LIVE',
          ),
          const SizedBox(height: Os2.space3),
          Os2MicroMeter(
            label: 'BIOM',
            value: 0.94,
            tone: Os2.identityTone,
            trailing: '94%',
          ),
          const SizedBox(height: Os2.space2),
          Os2MicroMeter(
            label: 'CHAIN',
            value: 0.92,
            tone: Os2.signalSettled,
            trailing: '92%',
          ),
          const SizedBox(height: Os2.space2),
          Os2MicroMeter(
            label: 'DEVICE',
            value: 0.81,
            tone: Os2.travelTone,
            trailing: '81%',
          ),
          const SizedBox(height: Os2.space2),
          Os2MicroMeter(
            label: 'NETWORK',
            value: 0.76,
            tone: Os2.servicesTone,
            trailing: '76%',
          ),
          const SizedBox(height: Os2.space2),
          Os2MicroMeter(
            label: 'BEHAVIOUR',
            value: 0.88,
            tone: Os2.walletTone,
            trailing: '88%',
          ),
          const SizedBox(height: Os2.space2),
          Os2MicroMeter(
            label: 'COVERAGE',
            value: 0.65,
            tone: Os2.discoverTone,
            trailing: '65%',
          ),
        ],
      ),
    );
  }
}

class _RecentVerifications extends StatelessWidget {
  const _RecentVerifications();
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
            eyebrow: 'RECENT VERIFICATIONS',
            tone: Os2.travelTone,
            trailing: 'LAST 30D',
          ),
          const SizedBox(height: Os2.space3),
          Os2Timeline(
            tone: Os2.travelTone,
            dense: true,
            nodes: const [
              Os2TimelineNode(
                title: 'GovChain re-attest',
                caption: 'Key 0x9e..a1 \u00b7 rotated',
                trailing: '02D',
                state: Os2NodeState.settled,
              ),
              Os2TimelineNode(
                title: 'Biometric liveness',
                caption: 'Score 98.2 \u00b7 face vault',
                trailing: '07D',
                state: Os2NodeState.settled,
              ),
              Os2TimelineNode(
                title: 'Issuer ping \u00b7 Apostille',
                caption: 'Latency 142ms \u00b7 pass',
                trailing: '12D',
                state: Os2NodeState.settled,
              ),
              Os2TimelineNode(
                title: 'Device fingerprint',
                caption: 'Pixel 9 Pro \u00b7 trusted',
                trailing: '24D',
                state: Os2NodeState.active,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Protocols extends StatelessWidget {
  const _Protocols();
  @override
  Widget build(BuildContext context) {
    final acts = <_PA>[
      _PA('Re-seal vault', Icons.lock_rounded, Os2.identityTone),
      _PA('Rotate keys', Icons.refresh_rounded, Os2.walletTone),
      _PA('Rerun audit', Icons.fact_check_rounded, Os2.signalSettled),
      _PA('Add issuer', Icons.add_link_rounded, Os2.travelTone),
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
            eyebrow: 'STANDING PROTOCOLS',
            tone: Os2.servicesTone,
            trailing: '4 READY',
          ),
          const SizedBox(height: Os2.space3),
          Row(
            children: [
              Expanded(
                child: Os2ActionCard(
                  title: acts[0].title,
                  icon: acts[0].icon,
                  tone: acts[0].tone,
                  dense: true,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: Os2.space2),
              Expanded(
                child: Os2ActionCard(
                  title: acts[1].title,
                  icon: acts[1].icon,
                  tone: acts[1].tone,
                  dense: true,
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: Os2.space2),
          Row(
            children: [
              Expanded(
                child: Os2ActionCard(
                  title: acts[2].title,
                  icon: acts[2].icon,
                  tone: acts[2].tone,
                  dense: true,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: Os2.space2),
              Expanded(
                child: Os2ActionCard(
                  title: acts[3].title,
                  icon: acts[3].icon,
                  tone: acts[3].tone,
                  dense: true,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PA {
  const _PA(this.title, this.icon, this.tone);
  final String title;
  final IconData icon;
  final Color tone;
}
