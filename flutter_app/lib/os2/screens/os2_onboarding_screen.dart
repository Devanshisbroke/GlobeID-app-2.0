import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/onboarding_provider.dart';
import '../../motion/motion.dart';
import '../motion/os2_breathing.dart';
import '../os2_tokens.dart';
import '../primitives/os2_beacon.dart';
import '../primitives/os2_chip.dart';
import '../primitives/os2_divider_rule.dart';
import '../primitives/os2_glyph_halo.dart';
import '../primitives/os2_magnetic.dart';
import '../primitives/os2_pip.dart';
import '../primitives/os2_text.dart';

/// OS 2.0 — Cinematic onboarding.
///
/// Five-stage reveal sequence: Welcome, Identity, Wallet, Travel,
/// Concierge. Each stage is a full-bleed OLED slab with:
///   • a hero glyph haloed in the stage's tone, breathing slowly;
///   • a giant display headline, terse body, supporting captions;
///   • a tone-tinted radial vignette glow;
///   • a quartet of supporting feature pips (typographic);
///   • a synchronized progress pip stack at the top.
class Os2OnboardingScreen extends ConsumerStatefulWidget {
  const Os2OnboardingScreen({super.key});

  @override
  ConsumerState<Os2OnboardingScreen> createState() =>
      _Os2OnboardingScreenState();
}

class _Os2OnboardingScreenState extends ConsumerState<Os2OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _index = 0;

  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..repeat();

  static const _stages = <_OnboardStage>[
    _OnboardStage(
      eyebrow: 'WELCOME',
      title: 'GlobeID',
      body: 'The operating system for global identity, travel, money, '
          'and orchestration. Engineered for the next century of mobility.',
      icon: Icons.public_rounded,
      tone: Os2.pulseTone,
      bullets: [
        _Bullet('Sovereign identity', Icons.fingerprint_rounded),
        _Bullet('Multi-currency treasury', Icons.account_balance_rounded),
        _Bullet('Live travel orchestration', Icons.flight_takeoff_rounded),
        _Bullet('Always-on concierge', Icons.support_agent_rounded),
      ],
    ),
    _OnboardStage(
      eyebrow: 'IDENTITY',
      title: 'One verified you',
      body: 'A jewel-grade passport, trusted-traveler programs, '
          'and 12 verifiable cross-signs — all in one foil sanctum.',
      icon: Icons.workspace_premium_rounded,
      tone: Os2.identityTone,
      bullets: [
        _Bullet('Foil-grade passport', Icons.menu_book_rounded),
        _Bullet('Trusted programs', Icons.verified_user_rounded),
        _Bullet('Tier ladder', Icons.stairs_rounded),
        _Bullet('Live verification', Icons.fact_check_rounded),
      ],
    ),
    _OnboardStage(
      eyebrow: 'TREASURY',
      title: 'Liquid worldwide',
      body: 'Hold any currency, spend anywhere, settle instantly. '
          'No correspondent banks. No spread. Treasury-grade clarity.',
      icon: Icons.account_balance_wallet_rounded,
      tone: Os2.walletTone,
      bullets: [
        _Bullet('Multi-currency vault', Icons.toll_rounded),
        _Bullet('Instant FX pour', Icons.water_drop_rounded),
        _Bullet('Live spend pulse', Icons.timeline_rounded),
        _Bullet('Treasury sweep', Icons.cyclone_rounded),
      ],
    ),
    _OnboardStage(
      eyebrow: 'TRAVEL',
      title: 'Departure stage, always set',
      body: 'Boarding passes, lounges, gates, customs, and rides all '
          'orchestrated end-to-end. The airport becomes a single tap.',
      icon: Icons.flight_takeoff_rounded,
      tone: Os2.travelTone,
      bullets: [
        _Bullet('Solari departure stage', Icons.access_time_rounded),
        _Bullet('Boarding-pass stack', Icons.confirmation_num_rounded),
        _Bullet('Airport orchestrator', Icons.local_airport_rounded),
        _Bullet('Customs & arrival', Icons.luggage_rounded),
      ],
    ),
    _OnboardStage(
      eyebrow: 'CONCIERGE',
      title: 'The system listens.',
      body: 'An always-on AGI concierge that reads your day, '
          'anticipates intents, and quietly handles them in your name.',
      icon: Icons.psychology_rounded,
      tone: Os2.servicesTone,
      bullets: [
        _Bullet('Agentic intents', Icons.bolt_rounded),
        _Bullet('Predictive briefs', Icons.auto_awesome_rounded),
        _Bullet('Hand-off to humans', Icons.support_agent_rounded),
        _Bullet('Standing protocols', Icons.shield_rounded),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Signature haptic on first paint — user crosses into GlobeID.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Haptics.signature();
    });
  }

  @override
  void dispose() {
    _ambient.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _advance() {
    if (_index < _stages.length - 1) {
      _pageCtrl.nextPage(duration: Os2.mIn, curve: Os2.cTakeoff);
      Haptics.navigate();
    } else {
      _finish();
    }
  }

  void _back() {
    if (_index > 0) {
      _pageCtrl.previousPage(duration: Os2.mIn, curve: Os2.cTakeoff);
      Haptics.navigate();
    }
  }

  Future<void> _finish() async {
    // Crossing into the live app — signature moment.
    await Haptics.signature();
    await ref.read(onboardingProvider.notifier).complete();
    if (!mounted) return;
    GoRouter.of(context).go('/');
  }

  @override
  Widget build(BuildContext context) {
    final stage = _stages[_index];
    return Scaffold(
      backgroundColor: Os2.canvas,
      body: Stack(
        children: [
          // Ambient radial halo (stage-tone tinted).
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _ambient,
                builder: (_, __) => CustomPaint(
                  painter: _AmbientHaloPainter(
                    tone: stage.tone,
                    progress: _ambient.value,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _Header(
                  index: _index,
                  total: _stages.length,
                  tone: stage.tone,
                  onSkip: _finish,
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    itemCount: _stages.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (_, i) => _StagePage(stage: _stages[i]),
                  ),
                ),
                _Footer(
                  index: _index,
                  total: _stages.length,
                  tone: stage.tone,
                  onBack: _back,
                  onAdvance: _advance,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardStage {
  const _OnboardStage({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.icon,
    required this.tone,
    required this.bullets,
  });

  final String eyebrow;
  final String title;
  final String body;
  final IconData icon;
  final Color tone;
  final List<_Bullet> bullets;
}

class _Bullet {
  const _Bullet(this.label, this.icon);
  final String label;
  final IconData icon;
}

// ─────────────────────────────────────────── Header

class _Header extends StatelessWidget {
  const _Header({
    required this.index,
    required this.total,
    required this.tone,
    required this.onSkip,
  });

  final int index;
  final int total;
  final Color tone;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final pips = List.generate(total, (i) {
      if (i < index) return Os2PipState.settled;
      if (i == index) return Os2PipState.active;
      return Os2PipState.pending;
    });
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Os2.space5,
        Os2.space4,
        Os2.space5,
        Os2.space3,
      ),
      child: Row(
        children: [
          Os2Beacon(label: 'GLOBEID OS2', tone: tone),
          const Spacer(),
          Os2PipStack(pips: pips, tone: tone),
          const SizedBox(width: Os2.space3),
          Os2Magnetic(
            onTap: onSkip,
            child: Os2Text.monoCap('SKIP', color: Os2.inkLow, size: 11),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────── Stage page

class _StagePage extends StatelessWidget {
  const _StagePage({required this.stage});
  final _OnboardStage stage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Os2.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          // Hero glyph.
          Os2Breathing(
            child: Center(
              child: Os2GlyphHalo(
                icon: stage.icon,
                tone: stage.tone,
                size: 132,
                iconSize: 62,
              ),
            ),
          ),
          const SizedBox(height: Os2.space5),
          Os2Text.monoCap(stage.eyebrow, color: stage.tone, size: 11),
          const SizedBox(height: Os2.space2),
          Os2Text.display(
            stage.title,
            color: Os2.inkBright,
            size: 38,
            maxLines: 3,
          ),
          const SizedBox(height: Os2.space3),
          Os2Text.body(
            stage.body,
            color: Os2.inkMid,
            size: 15,
            maxLines: 5,
          ),
          const SizedBox(height: Os2.space5),
          Os2DividerRule(
            eyebrow: 'IN THIS LAYER',
            tone: stage.tone,
          ),
          const SizedBox(height: Os2.space3),
          for (final b in stage.bullets) ...[
            Row(
              children: [
                Os2GlyphHalo(icon: b.icon, tone: stage.tone, size: 26),
                const SizedBox(width: Os2.space3),
                Expanded(
                  child: Os2Text.title(
                    b.label,
                    color: Os2.inkHigh,
                    size: 15,
                    maxLines: 1,
                  ),
                ),
                Os2Text.monoCap(
                  '\u2192',
                  color: stage.tone,
                  size: 13,
                ),
              ],
            ),
            const SizedBox(height: Os2.space2),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────── Footer

class _Footer extends StatelessWidget {
  const _Footer({
    required this.index,
    required this.total,
    required this.tone,
    required this.onBack,
    required this.onAdvance,
  });

  final int index;
  final int total;
  final Color tone;
  final VoidCallback onBack;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final isLast = index == total - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Os2.space5,
        Os2.space3,
        Os2.space5,
        Os2.space5,
      ),
      child: Row(
        children: [
          if (index > 0)
            Os2Magnetic(
              onTap: onBack,
              child: const Os2Chip(
                label: 'BACK',
                tone: Os2.inkMid,
                intensity: Os2ChipIntensity.subtle,
              ),
            )
          else
            const SizedBox(width: 1),
          const Spacer(),
          Os2Magnetic(
            onTap: onAdvance,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Os2.space5,
                vertical: Os2.space3,
              ),
              decoration: ShapeDecoration(
                color: tone,
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(Os2.rChip),
                ),
                shadows: [
                  BoxShadow(
                    color: tone.withValues(alpha: 0.35),
                    blurRadius: 20,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Os2Text.title(
                    isLast ? 'Enter GlobeID' : 'Continue',
                    color: Os2.canvas,
                    size: 14,
                  ),
                  const SizedBox(width: Os2.space2),
                  Icon(
                    isLast
                        ? Icons.bolt_rounded
                        : Icons.chevron_right_rounded,
                    color: Os2.canvas,
                    size: 16,
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

// ─────────────────────────────────────────── Ambient halo

class _AmbientHaloPainter extends CustomPainter {
  _AmbientHaloPainter({required this.tone, required this.progress});

  final Color tone;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = math.sin(progress * math.pi * 2);
    final dy = size.height * 0.28 + t * 12;
    final dx = size.width * 0.5 + math.cos(progress * math.pi * 2) * 16;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          tone.withValues(alpha: 0.20),
          tone.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(
          Rect.fromCircle(center: Offset(dx, dy), radius: size.width * 0.7));
    canvas.drawCircle(Offset(dx, dy), size.width * 0.7, paint);
  }

  @override
  bool shouldRepaint(covariant _AmbientHaloPainter old) =>
      old.tone != tone || old.progress != progress;
}
