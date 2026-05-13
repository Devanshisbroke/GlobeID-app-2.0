import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../cinematic/live/live_primitives.dart';
import '../../motion/motion.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/pressable.dart';

/// `VisaRenewalCeremony` — the cinematic surface the Copilot opens
/// when it detects an expiring visa. Four sequential stages walk the
/// bearer through the renewal as if they were standing inside a
/// Swiss consulate:
///
///   1. **Detect**   — "We see your Schengen visa expires in 11
///                      days." Hero countdown, foil sweep, sealed
///                      crest.
///   2. **Verify**   — Confirm bearer identity with a biometric
///                      placeholder + signature haptic on commit.
///   3. **Submit**   — Auto-filled fields from the vault, single-tap
///                      digital signature.
///   4. **Confirm**  — Reference number rolls in, ETA, GlobeID seal.
///
/// Every stage composes existing GlobeID primitives only:
///   • [Os2Text] variants for typography (display / monoCap / body)
///   • [BreathingHalo] for the alive thread on the hero crest
///   • [RollingDigits] for the cinematic reference number reveal
///   • [Pressable] with semantic labels for every affordance
///   • foil-gold gradients (`Os2.foilGoldHero`) for hero glyphs
///   • mono-cap chrome and gold hairline rules everywhere
///
/// The flow is fully self-contained — no network calls, no real
/// API. State is process-local; the screen exits via `context.pop`
/// or, on the final stage, via a "Done" CTA that pops back to the
/// caller. Deep-link entry point is `/visa/renew` with optional
/// `?country=` and `?days=` query parameters.
class VisaRenewalCeremony extends StatefulWidget {
  const VisaRenewalCeremony({
    super.key,
    this.country = 'Schengen Area',
    this.flag = '🇪🇺',
    this.daysToExpiry = 11,
    this.visaType = 'Schengen short-stay',
    this.tone = Os2.goldDeep,
  });

  /// Display name of the visa-issuing region. Pre-filled from the
  /// Copilot's detection payload; bearer cannot edit it.
  final String country;

  /// Flag glyph rendered next to the country name.
  final String flag;

  /// Days remaining on the existing visa at detection time. Used
  /// for the hero countdown.
  final int daysToExpiry;

  /// Human-readable visa type (`Schengen short-stay`,
  /// `Tourist · 90 days`, etc.).
  final String visaType;

  /// Accent tone for the ceremony. Defaults to deep gold so the
  /// flow reads as a GlobeID signature moment; callers can pass a
  /// country-specific advisory tone if they prefer.
  final Color tone;

  @override
  State<VisaRenewalCeremony> createState() => _VisaRenewalCeremonyState();
}

class _VisaRenewalCeremonyState extends State<VisaRenewalCeremony>
    with TickerProviderStateMixin {
  int _stage = 0;
  static const _stages = <_StageDescriptor>[
    _StageDescriptor(
      key: 'detect',
      eyebrow: 'COPILOT · RENEW',
      kicker: 'STAGE 1 OF 4',
      title: 'We see your visa expires soon',
    ),
    _StageDescriptor(
      key: 'verify',
      eyebrow: 'COPILOT · VERIFY',
      kicker: 'STAGE 2 OF 4',
      title: 'Confirm bearer identity',
    ),
    _StageDescriptor(
      key: 'submit',
      eyebrow: 'COPILOT · SUBMIT',
      kicker: 'STAGE 3 OF 4',
      title: 'Sign the renewal',
    ),
    _StageDescriptor(
      key: 'confirm',
      eyebrow: 'COPILOT · ISSUED',
      kicker: 'STAGE 4 OF 4',
      title: 'Renewal submitted',
    ),
  ];

  late int _referenceTarget;

  @override
  void initState() {
    super.initState();
    // Deterministic-feeling reference number derived from the country
    // hash so the demo always lands on the same digits for the same
    // input — keeps screenshots and tests stable.
    _referenceTarget = 100000 + (widget.country.hashCode.abs() % 899999);
  }

  void _advance() {
    if (_stage == _stages.length - 1) {
      _exit();
      return;
    }
    setState(() => _stage += 1);
    // Signature haptic on the irreversible commit ("Sign the renewal"
    // → "Renewal submitted"). All other transitions feel lighter.
    if (_stages[_stage].key == 'confirm') {
      unawaited(Haptics.signature());
    } else {
      Haptics.tap();
    }
  }

  void _exit() {
    Haptics.close();
    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/visa');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stage = _stages[_stage];
    return Scaffold(
      backgroundColor: Os2.canvas,
      body: SafeArea(
        child: Column(
          children: [
            _Chrome(
              eyebrow: stage.eyebrow,
              kicker: stage.kicker,
              onClose: _exit,
            ),
            const _GoldHairlineDivider(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 360),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey<int>(_stage),
                  child: _stageBody(stage),
                ),
              ),
            ),
            const _GoldHairlineDivider(),
            _Footer(
              stage: stage,
              isFinal: _stage == _stages.length - 1,
              onAdvance: _advance,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stageBody(_StageDescriptor stage) {
    switch (stage.key) {
      case 'detect':
        return _DetectStage(
          country: widget.country,
          flag: widget.flag,
          daysToExpiry: widget.daysToExpiry,
          visaType: widget.visaType,
          tone: widget.tone,
        );
      case 'verify':
        return _VerifyStage(tone: widget.tone);
      case 'submit':
        return _SubmitStage(
          country: widget.country,
          flag: widget.flag,
          visaType: widget.visaType,
          tone: widget.tone,
        );
      case 'confirm':
        return _ConfirmStage(
          country: widget.country,
          referenceTarget: _referenceTarget,
          tone: widget.tone,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Stage descriptor
// ─────────────────────────────────────────────────────────────────

class _StageDescriptor {
  const _StageDescriptor({
    required this.key,
    required this.eyebrow,
    required this.kicker,
    required this.title,
  });
  final String key;
  final String eyebrow;
  final String kicker;
  final String title;
}

// ─────────────────────────────────────────────────────────────────
// Chrome
// ─────────────────────────────────────────────────────────────────

class _Chrome extends StatelessWidget {
  const _Chrome({
    required this.eyebrow,
    required this.kicker,
    required this.onClose,
  });

  final String eyebrow;
  final String kicker;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Os2.space5,
        Os2.space4,
        Os2.space3,
        Os2.space3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Os2Text.monoCap(
                  eyebrow,
                  color: Os2.goldDeep,
                  size: Os2.textXs,
                ),
                const SizedBox(height: 2),
                Os2Text.monoCap(
                  kicker,
                  color: Os2.inkMid,
                  size: Os2.textTiny,
                ),
              ],
            ),
          ),
          Pressable(
            scale: 0.92,
            semanticLabel: 'Close visa renewal',
            semanticHint: 'returns to the previous screen',
            onTap: onClose,
            child: Container(
              padding: const EdgeInsets.all(Os2.space2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Os2.floor2,
                border: Border.all(color: Os2.hairline),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Os2.inkHigh,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldHairlineDivider extends StatelessWidget {
  const _GoldHairlineDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: Os2.strokeFine,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0x00D4AF37),
            Os2.goldHairline,
            Color(0x00D4AF37),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Stage 1 — Detect
// ─────────────────────────────────────────────────────────────────

class _DetectStage extends StatelessWidget {
  const _DetectStage({
    required this.country,
    required this.flag,
    required this.daysToExpiry,
    required this.visaType,
    required this.tone,
  });

  final String country;
  final String flag;
  final int daysToExpiry;
  final String visaType;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Os2.space5,
        vertical: Os2.space5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BreathingHalo(
            tone: tone,
            state: LiveSurfaceState.armed,
            maxAlpha: 0.32,
            expand: 28,
            child: Container(
              padding: const EdgeInsets.all(Os2.space5),
              decoration: BoxDecoration(
                color: Os2.floor1,
                borderRadius: BorderRadius.circular(Os2.rCard),
                border: Border.all(
                  color: tone.withValues(alpha: 0.34),
                  width: Os2.strokeRegular,
                ),
              ),
              child: Row(
                children: [
                  Text(flag, style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: Os2.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Os2Text.monoCap(
                          'VISA · ${country.toUpperCase()}',
                          color: Os2.inkHigh,
                          size: Os2.textTiny,
                        ),
                        const SizedBox(height: 4),
                        Os2Text.headline(
                          visaType,
                          color: Os2.inkBright,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Os2.space6),
          Center(
            child: Os2Text.credential(
              '$daysToExpiry',
              color: Os2.inkBright,
              size: 88,
              gradient: Os2.foilGoldHero,
            ),
          ),
          const SizedBox(height: Os2.space1),
          Center(
            child: Os2Text.monoCap(
              'DAYS UNTIL EXPIRY',
              color: Os2.inkMid,
              size: Os2.textSm,
            ),
          ),
          const SizedBox(height: Os2.space6),
          Os2Text.body(
            'GlobeID Copilot detected your $country visa is inside the '
            'renewal window. Starting the renewal now keeps your '
            'cleared trips on track and avoids the summer backlog.',
            color: Os2.inkHigh,
            size: Os2.textBase,
            maxLines: 6,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Stage 2 — Verify
// ─────────────────────────────────────────────────────────────────

class _VerifyStage extends StatefulWidget {
  const _VerifyStage({required this.tone});
  final Color tone;
  @override
  State<_VerifyStage> createState() => _VerifyStageState();
}

class _VerifyStageState extends State<_VerifyStage> {
  bool _passport = false;
  bool _selfie = false;
  bool _residency = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Os2.space5,
        vertical: Os2.space5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Os2Text.body(
            'Confirm bearer identity. These vault credentials are '
            'cryptographically attested and never leave the device.',
            color: Os2.inkHigh,
            size: Os2.textBase,
            maxLines: 4,
          ),
          const SizedBox(height: Os2.space5),
          _VerifyTile(
            tone: widget.tone,
            label: 'Passport biometric',
            sub: 'Active session · Face ID',
            checked: _passport,
            onTap: () {
              Haptics.tap();
              setState(() => _passport = !_passport);
            },
          ),
          const SizedBox(height: Os2.space3),
          _VerifyTile(
            tone: widget.tone,
            label: 'Live selfie capture',
            sub: 'Real-time match · 96.4%',
            checked: _selfie,
            onTap: () {
              Haptics.tap();
              setState(() => _selfie = !_selfie);
            },
          ),
          const SizedBox(height: Os2.space3),
          _VerifyTile(
            tone: widget.tone,
            label: 'Residency proof',
            sub: 'Utility bill on file · 8 days ago',
            checked: _residency,
            onTap: () {
              Haptics.tap();
              setState(() => _residency = !_residency);
            },
          ),
        ],
      ),
    );
  }
}

class _VerifyTile extends StatelessWidget {
  const _VerifyTile({
    required this.tone,
    required this.label,
    required this.sub,
    required this.checked,
    required this.onTap,
  });

  final Color tone;
  final String label;
  final String sub;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.98,
      onTap: onTap,
      semanticLabel: label,
      semanticHint: 'toggles ${label.toLowerCase()} for visa renewal',
      child: Container(
        padding: const EdgeInsets.all(Os2.space4),
        decoration: BoxDecoration(
          color: Os2.floor1,
          borderRadius: BorderRadius.circular(Os2.rChip),
          border: Border.all(
            color: checked
                ? tone.withValues(alpha: 0.6)
                : Os2.hairline,
            width: Os2.strokeRegular,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: checked ? tone : Colors.transparent,
                border: Border.all(
                  color: checked ? tone : Os2.hairline,
                  width: Os2.strokeRegular,
                ),
              ),
              child: checked
                  ? const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: Os2.canvas,
                    )
                  : null,
            ),
            const SizedBox(width: Os2.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Os2Text.title(
                    label,
                    color: Os2.inkBright,
                    size: Os2.textRg,
                  ),
                  const SizedBox(height: 2),
                  Os2Text.body(
                    sub,
                    color: Os2.inkMid,
                    size: Os2.textSm,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Stage 3 — Submit
// ─────────────────────────────────────────────────────────────────

class _SubmitStage extends StatelessWidget {
  const _SubmitStage({
    required this.country,
    required this.flag,
    required this.visaType,
    required this.tone,
  });

  final String country;
  final String flag;
  final String visaType;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: Os2.space5,
        vertical: Os2.space5,
      ),
      physics: const BouncingScrollPhysics(),
      children: [
        Os2Text.body(
          'Review the pre-filled application. Every field is sourced '
          'from your vault and verifiable against the issuer registry.',
          color: Os2.inkHigh,
          size: Os2.textBase,
          maxLines: 4,
        ),
        const SizedBox(height: Os2.space5),
        _SummaryRow(label: 'COUNTRY', value: '$flag  $country'),
        _SummaryRow(label: 'VISA TYPE', value: visaType),
        const _SummaryRow(label: 'BEARER NAME', value: 'Devansh B.'),
        const _SummaryRow(label: 'PASSPORT', value: 'A• ••• 4218'),
        const _SummaryRow(label: 'RESIDENCY', value: 'India · 2014–present'),
        const _SummaryRow(label: 'PURPOSE', value: 'Tourism · 14 days'),
        const SizedBox(height: Os2.space5),
        Container(
          padding: const EdgeInsets.all(Os2.space4),
          decoration: BoxDecoration(
            color: Os2.floor2,
            borderRadius: BorderRadius.circular(Os2.rChip),
            border: Border.all(color: Os2.hairline),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, color: tone, size: 24),
              const SizedBox(width: Os2.space3),
              Expanded(
                child: Os2Text.body(
                  'Signing this seals the application with your '
                  'GlobeID cryptographic key and submits it to the '
                  'consulate API.',
                  color: Os2.inkHigh,
                  size: Os2.textSm,
                  maxLines: 4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Os2.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Os2Text.monoCap(
              label,
              color: Os2.inkMid,
              size: Os2.textTiny,
            ),
          ),
          Expanded(
            child: Os2Text.body(
              value,
              color: Os2.inkBright,
              size: Os2.textBase,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Stage 4 — Confirm
// ─────────────────────────────────────────────────────────────────

class _ConfirmStage extends StatelessWidget {
  const _ConfirmStage({
    required this.country,
    required this.referenceTarget,
    required this.tone,
  });

  final String country;
  final int referenceTarget;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Os2.space5,
        vertical: Os2.space5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BreathingHalo(
            tone: tone,
            state: LiveSurfaceState.committed,
            maxAlpha: 0.36,
            expand: 32,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Os2.space5,
                vertical: Os2.space7,
              ),
              decoration: BoxDecoration(
                color: Os2.floor1,
                borderRadius: BorderRadius.circular(Os2.rCard),
                border: Border.all(
                  color: tone.withValues(alpha: 0.5),
                  width: Os2.strokeRegular,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    size: 48,
                    color: tone,
                  ),
                  const SizedBox(height: Os2.space3),
                  Os2Text.monoCap(
                    'GLOBE·ID · REFERENCE',
                    color: Os2.inkMid,
                    size: Os2.textTiny,
                  ),
                  const SizedBox(height: Os2.space2),
                  RollingDigits(
                    target: referenceTarget,
                    digits: 6,
                    prefix: 'GID-',
                    style: const TextStyle(
                      color: Os2.inkBright,
                      fontFamily: 'monospace',
                      fontFeatures: [FontFeature.tabularFigures()],
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.4,
                    ),
                    duration: const Duration(milliseconds: 1100),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Os2.space6),
          Os2Text.title(
            'Submitted to the $country consulate',
            color: Os2.inkBright,
            size: Os2.textLg,
          ),
          const SizedBox(height: Os2.space2),
          Os2Text.body(
            'Estimated turnaround 5–7 business days. Copilot will '
            'surface your new visa in this app the moment it is '
            'sealed by the issuer registry.',
            color: Os2.inkHigh,
            size: Os2.textBase,
            maxLines: 5,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Footer
// ─────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({
    required this.stage,
    required this.isFinal,
    required this.onAdvance,
  });

  final _StageDescriptor stage;
  final bool isFinal;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final ctaLabel = switch (stage.key) {
      'detect' => 'BEGIN RENEWAL',
      'verify' => 'CONFIRM IDENTITY',
      'submit' => 'SIGN AND SUBMIT',
      'confirm' => 'DONE',
      _ => 'CONTINUE',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Os2.space5,
        Os2.space4,
        Os2.space5,
        Os2.space5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Os2Text.title(
            stage.title,
            color: Os2.inkBright,
            size: Os2.textLg,
          ),
          const SizedBox(height: Os2.space3),
          Pressable(
            scale: 0.97,
            onTap: onAdvance,
            semanticLabel: ctaLabel,
            semanticHint: isFinal
                ? 'closes the renewal flow'
                : 'advances to the next stage',
            child: Container(
              height: Os2.touchMin,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: Os2.foilGoldHero,
                borderRadius: BorderRadius.circular(Os2.rChip),
                boxShadow: [
                  BoxShadow(
                    color: Os2.goldDeep.withValues(alpha: 0.34),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Os2Text.monoCap(
                ctaLabel,
                color: Os2.canvas,
                size: Os2.textSm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
