import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../motion/motion.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';

/// Phases of the issuance ceremony. Used by tests + render code to
/// keep timing logic in one place.
enum IssuancePhase {
  loadingInk,
  arcSwing,
  press,
  bleed,
  settled,
}

extension IssuancePhaseTiming on IssuancePhase {
  /// Cumulative end time as a fraction of [IssuanceCeremony.duration].
  /// Phase boundaries are tuned so the press lands on the same frame
  /// the signature haptic fires.
  double get end {
    switch (this) {
      case IssuancePhase.loadingInk:
        return 0.24;
      case IssuancePhase.arcSwing:
        return 0.47;
      case IssuancePhase.press:
        return 0.56;
      case IssuancePhase.bleed:
        return 0.84;
      case IssuancePhase.settled:
        return 1.0;
    }
  }
}

/// `IssuanceCeremony` — a 3.2 s cinematic that plays when a new
/// credential is being issued. Five phases:
///
///   1. LOADING INK    (0 → 0.24) — stamp glyph fills with gold
///   2. ARC SWING      (0.24 → 0.47) — stamp arcs down from above
///   3. PRESS          (0.47 → 0.56) — radial flash + signature haptic
///   4. BLEED          (0.56 → 0.84) — ink rings expand and settle
///   5. SETTLED        (0.84 → 1.0) — credential preview snaps into
///      focus, mono-cap MINTED chip pulses, GLOBE·ID watermark drifts
///
/// The widget composes from existing GlobeID primitives — no new
/// visual language. Same gold/mono-cap/OLED thread as every other
/// surface.
class IssuanceCeremony extends StatefulWidget {
  const IssuanceCeremony({
    super.key,
    required this.title,
    required this.subtitle,
    required this.issuer,
    required this.blockHeight,
    this.duration = const Duration(milliseconds: 3200),
    this.onComplete,
  });

  /// Credential label e.g. `Republic of Iceland · Passport`.
  final String title;

  /// One-line subtitle e.g. `Bearer · Devansh Barai`.
  final String subtitle;

  /// Issuer copy that appears below the seal, e.g. `Republic of
  /// Iceland · Ministry of the Interior`.
  final String issuer;

  /// Deterministic block height shown on the minted chip. Caller
  /// derives this from the credential id (same recipe as
  /// `CredentialAttestation.derive` in Phase 8a).
  final int blockHeight;

  /// Override the ceremony length. Defaults to 3.2 s — long enough
  /// to read as a ritual, short enough to never feel like a wait.
  final Duration duration;

  /// Fired exactly once when the ceremony lands at [IssuancePhase.settled].
  final VoidCallback? onComplete;

  @override
  State<IssuanceCeremony> createState() => _IssuanceCeremonyState();
}

class _IssuanceCeremonyState extends State<IssuanceCeremony>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  bool _pressFired = false;
  bool _completeFired = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(_handle);
    _c.forward();
  }

  void _handle() {
    final t = _c.value;
    // Signature haptic on the press frame — fires once.
    if (!_pressFired && t >= IssuancePhase.arcSwing.end) {
      _pressFired = true;
      Haptics.signature();
    }
    if (!_completeFired && t >= 1.0) {
      _completeFired = true;
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    _c.removeListener(_handle);
    _c.dispose();
    super.dispose();
  }

  IssuancePhase _phaseFor(double t) {
    for (final phase in IssuancePhase.values) {
      if (t <= phase.end) return phase;
    }
    return IssuancePhase.settled;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final phase = _phaseFor(t);
        return Container(
          color: Os2.canvas,
          padding: const EdgeInsets.symmetric(horizontal: Os2.space6),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Watermark — drifts in over the settled phase.
              Positioned(
                top: 64,
                child: Opacity(
                  opacity: t.clamp(0.0, 1.0) > IssuancePhase.bleed.end
                      ? ((t - IssuancePhase.bleed.end) /
                              (1.0 - IssuancePhase.bleed.end))
                          .clamp(0.0, 1.0)
                      : 0.0,
                  child: const Os2Text.watermark('GLOBE·ID · ISSUANCE'),
                ),
              ),
              _StampStage(t: t, phase: phase),
              if (t >= IssuancePhase.bleed.end)
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: ((t - IssuancePhase.bleed.end) /
                            (1.0 - IssuancePhase.bleed.end))
                        .clamp(0.0, 1.0),
                    child: _SettledCard(
                      title: widget.title,
                      subtitle: widget.subtitle,
                      issuer: widget.issuer,
                      blockHeight: widget.blockHeight,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StampStage extends StatelessWidget {
  const _StampStage({required this.t, required this.phase});
  final double t;
  final IssuancePhase phase;

  @override
  Widget build(BuildContext context) {
    // Ink loading 0 → 1 across phase 1.
    final inkT = (t / IssuancePhase.loadingInk.end).clamp(0.0, 1.0);

    // Arc travel: y from -240 → 0, rotation from 0.45 rad → 0 rad
    // across phase 2.
    final arcRaw = ((t - IssuancePhase.loadingInk.end) /
            (IssuancePhase.arcSwing.end - IssuancePhase.loadingInk.end))
        .clamp(0.0, 1.0);
    final arcEase = Curves.easeInCubic.transform(arcRaw);
    final dy = phase == IssuancePhase.loadingInk
        ? -240.0
        : t >= IssuancePhase.arcSwing.end
            ? 0.0
            : -240.0 * (1.0 - arcEase);
    final rot = phase == IssuancePhase.loadingInk
        ? 0.45
        : t >= IssuancePhase.arcSwing.end
            ? 0.0
            : 0.45 * (1.0 - arcEase);

    // Press flash — bright halo for the ~100 ms press phase.
    final pressRaw = ((t - IssuancePhase.arcSwing.end) /
            (IssuancePhase.press.end - IssuancePhase.arcSwing.end))
        .clamp(0.0, 1.0);
    final pressFlash = phase == IssuancePhase.press
        ? math.sin(pressRaw * math.pi)
        : 0.0;

    // Bleed rings — three concentric rings expand outward.
    final bleedRaw = ((t - IssuancePhase.press.end) /
            (IssuancePhase.bleed.end - IssuancePhase.press.end))
        .clamp(0.0, 1.0);
    final bleedT = Curves.easeOutCubic.transform(bleedRaw);

    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Press flash radial.
          if (pressFlash > 0)
            Container(
              width: 240 + pressFlash * 80,
              height: 240 + pressFlash * 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Os2.goldLight.withValues(alpha: 0.62 * pressFlash),
                    Os2.goldDeep.withValues(alpha: 0.32 * pressFlash),
                    Os2.goldDeep.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          // Bleed rings — only paint after press.
          if (bleedT > 0)
            ..._buildBleedRings(bleedT),
          // The stamp itself.
          Transform.translate(
            offset: Offset(0, dy),
            child: Transform.rotate(
              angle: rot,
              child: _StampGlyph(
                inkFill: inkT,
                pressed: t >= IssuancePhase.arcSwing.end,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBleedRings(double t) {
    return [
      for (var i = 0; i < 3; i++)
        Container(
          width: 80 + (i + 1) * 60 * t,
          height: 80 + (i + 1) * 60 * t,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Os2.goldDeep.withValues(
                alpha: (0.42 - i * 0.12) * (1.0 - t * 0.5),
              ),
            ),
          ),
        ),
    ];
  }
}

class _StampGlyph extends StatelessWidget {
  const _StampGlyph({required this.inkFill, required this.pressed});
  final double inkFill;
  final bool pressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156,
      height: 156,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Os2.goldLight.withValues(alpha: 0.18 * inkFill),
            Os2.goldDeep.withValues(alpha: 0.36 * inkFill),
            Os2.canvas,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
        border: Border.all(
          color: Os2.goldDeep.withValues(alpha: 0.62),
          width: 2.4,
        ),
        boxShadow: [
          if (pressed)
            BoxShadow(
              color: Os2.goldDeep.withValues(alpha: 0.45),
              blurRadius: 28,
              spreadRadius: 4,
            ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Os2Text.monoCap(
              'GLOBE · ID',
              color: Os2.goldLight,
              size: Os2.textTiny,
            ),
            const SizedBox(height: 6),
            Os2Text.display(
              'SEAL',
              color: Os2.goldDeep,
              size: 28,
            ),
            const SizedBox(height: 4),
            Os2Text.monoCap(
              'ATELIER · ${DateTime.now().year}',
              color: Os2.goldLight,
              size: Os2.textTiny,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettledCard extends StatelessWidget {
  const _SettledCard({
    required this.title,
    required this.subtitle,
    required this.issuer,
    required this.blockHeight,
  });
  final String title;
  final String subtitle;
  final String issuer;
  final int blockHeight;

  @override
  Widget build(BuildContext context) {
    final block = blockHeight.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return Container(
      padding: const EdgeInsets.all(Os2.space5),
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(color: Os2.goldDeep.withValues(alpha: 0.46)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Os2.space2,
            runSpacing: 4,
            children: [
              Os2Text.monoCap(
                'CREDENTIAL · MINTED',
                color: Os2.goldDeep,
                size: Os2.textTiny,
              ),
              Os2Text.monoCap(
                'BLOCK $block',
                color: Os2.inkLow,
                size: Os2.textTiny,
              ),
            ],
          ),
          const SizedBox(height: Os2.space3),
          Os2Text.title(
            title,
            color: Os2.inkBright,
            size: Os2.textLg,
          ),
          const SizedBox(height: 4),
          Os2Text.body(
            subtitle,
            color: Os2.inkMid,
            size: Os2.textSm,
          ),
          const SizedBox(height: Os2.space3),
          Os2Text.monoCap(
            'ISSUED BY · $issuer',
            color: Os2.inkLow,
            size: Os2.textTiny,
          ),
        ],
      ),
    );
  }
}
