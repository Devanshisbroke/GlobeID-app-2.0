import 'dart:async';

import 'package:flutter/material.dart';

import '../bible_tokens.dart';
import '../bible_typography.dart';
import '../chrome/bible_pressable.dart';
import '../chrome/bible_premium_card.dart';
import '../chrome/bible_scaffold.dart';
import '../chrome/bible_widgets.dart';

/// GlobeID — **Arrival / Local Mode** (§11.11 _The Soft Landing_).
///
/// Registers: Recovery. Spine: Travel.
///
/// First impression after deplaning. The screen reads slowly: a calm
/// hero welcome card, time in local + home zones, a paper-plane
/// animation that finishes on landing, then three cascade CTAs
/// (taxi, eSIM, lounge). No noise, no chrome. Tone: Sunrise.
class BibleArrivalScreen extends StatefulWidget {
  const BibleArrivalScreen({super.key});

  @override
  State<BibleArrivalScreen> createState() => _BibleArrivalScreenState();
}

class _BibleArrivalScreenState extends State<BibleArrivalScreen>
    with TickerProviderStateMixin {
  late final AnimationController _planeCtrl;
  late final List<AnimationController> _cascadeCtrls;
  final List<Timer> _timers = <Timer>[];

  @override
  void initState() {
    super.initState();
    _planeCtrl = AnimationController(
      vsync: this,
      duration: B.dPortal,
    )..forward();
    _cascadeCtrls = List.generate(
      4,
      (i) => AnimationController(
        vsync: this,
        duration: B.dSheet,
      ),
    );
    _scheduleCascade();
  }

  void _scheduleCascade() {
    for (var i = 0; i < _cascadeCtrls.length; i++) {
      _timers.add(
        Timer(B.cSection * (i + 1), () {
          if (mounted) _cascadeCtrls[i].forward();
        }),
      );
    }
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _planeCtrl.dispose();
    for (final c in _cascadeCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BiblePageScaffold(
      emotion: BEmotion.recovery,
      tone: B.runwayAmber.withValues(alpha: 0.06),
      density: BDensity.atrium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: B.space5),
          _WelcomeHero(planeCtrl: _planeCtrl),
          const SizedBox(height: B.space5),
          _ClockRow(),
          const SizedBox(height: B.space5),
          _CascadeCta(
            ctrl: _cascadeCtrls[0],
            label: 'Open eSIM — NTT 5G',
            caption: 'Auto-activates · 8 GB ready',
            tone: B.jetCyan,
            icon: Icons.sim_card_rounded,
            primary: true,
          ),
          const SizedBox(height: B.space3),
          _CascadeCta(
            ctrl: _cascadeCtrls[1],
            label: 'Call my driver',
            caption: 'Hiroshi K · arrived at Bay 04',
            tone: B.honeyAmber,
            icon: Icons.local_taxi_rounded,
          ),
          const SizedBox(height: B.space3),
          _CascadeCta(
            ctrl: _cascadeCtrls[2],
            label: 'Reserve JAL Sakura lounge',
            caption: '2h pod · ¥ 0 · platinum',
            tone: B.foilGold,
            icon: Icons.weekend_rounded,
          ),
          const SizedBox(height: B.space3),
          _CascadeCta(
            ctrl: _cascadeCtrls[3],
            label: 'Switch to Tokyo wallet',
            caption: 'JPY · ¥ 1.84 m available',
            tone: B.treasuryGreen,
            icon: Icons.account_balance_wallet_rounded,
          ),
          const SizedBox(height: B.space6),
          const BibleSectionHeader(
            eyebrow: 'local intelligence',
            title: 'Right now in Tokyo',
          ),
          _LocalGrid(),
          const SizedBox(height: B.space6),
        ],
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({required this.planeCtrl});
  final AnimationController planeCtrl;
  @override
  Widget build(BuildContext context) {
    return BiblePremiumCard(
      tone: B.runwayAmber,
      padding: const EdgeInsets.all(B.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                '🇯🇵',
                style: TextStyle(fontSize: 40),
              ),
              const SizedBox(width: B.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BText.eyebrow(
                      '— soft landing —',
                      color: B.runwayAmber,
                    ),
                    const SizedBox(height: B.space1),
                    BText.display('ようこそ, Devansh.', size: 24),
                    const SizedBox(height: B.space1),
                    BText.caption(
                      'Welcome to Tokyo. The pulse of Japan is at your fingertips.',
                      color: B.inkOnDarkMid,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: B.space4),
          _PaperPlane(controller: planeCtrl),
        ],
      ),
    );
  }
}

class _PaperPlane extends StatelessWidget {
  const _PaperPlane({required this.controller});
  final AnimationController controller;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          final t = controller.value;
          return Stack(
            children: [
              // Trail
              Positioned(
                left: 0,
                right: 24,
                top: 24,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        B.runwayAmber.withValues(alpha: 0),
                        B.runwayAmber.withValues(alpha: 0.6 * t),
                      ],
                    ),
                  ),
                ),
              ),
              // Plane glyph
              Align(
                alignment: Alignment(-1.0 + 2.0 * t, -0.5 + 1.0 * t),
                child: const Icon(
                  Icons.flight_land_rounded,
                  color: B.runwayAmber,
                  size: 26,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ClockRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ClockTile(
            eyebrow: 'tokyo · JST',
            value: '17 : 42',
            caption: 'Local · friday',
            tone: B.jetCyan,
          ),
        ),
        const SizedBox(width: B.space3),
        Expanded(
          child: _ClockTile(
            eyebrow: 'london · GMT',
            value: '09 : 42',
            caption: 'Home · 8h behind',
            tone: B.polarBlue,
          ),
        ),
      ],
    );
  }
}

class _ClockTile extends StatelessWidget {
  const _ClockTile({
    required this.eyebrow,
    required this.value,
    required this.caption,
    required this.tone,
  });
  final String eyebrow;
  final String value;
  final String caption;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    return BiblePremiumCard(
      tone: tone,
      padding: const EdgeInsets.all(B.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BText.eyebrow(eyebrow, color: tone),
          const SizedBox(height: B.space3),
          BText.solari(value, size: 28, color: B.inkOnDarkHigh),
          const SizedBox(height: B.space1),
          BText.caption(caption, color: B.inkOnDarkMid),
        ],
      ),
    );
  }
}

class _CascadeCta extends StatelessWidget {
  const _CascadeCta({
    required this.ctrl,
    required this.label,
    required this.caption,
    required this.tone,
    required this.icon,
    this.primary = false,
  });
  final AnimationController ctrl;
  final String label;
  final String caption;
  final Color tone;
  final IconData icon;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, child) {
        return Opacity(
          opacity: ctrl.value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - ctrl.value)),
            child: child,
          ),
        );
      },
      child: BiblePressable(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(B.space4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(B.rCard),
            color: tone.withValues(alpha: primary ? 0.16 : 0.08),
            border: Border.all(
              color: tone.withValues(alpha: primary ? 0.55 : 0.30),
              width: 0.6,
            ),
          ),
          child: Row(
            children: [
              BibleGlyphHalo(icon: icon, tone: tone, size: 44),
              const SizedBox(width: B.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BText.title(label, size: 15),
                    const SizedBox(height: 2),
                    BText.caption(caption, color: B.inkOnDarkMid, maxLines: 2),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: B.inkOnDarkLow,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocalGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(
              child: _LocalTile(
                eyebrow: 'weather',
                value: '11°C',
                caption: 'Clear · feels 9°',
                tone: B.polarBlue,
                icon: Icons.wb_sunny_rounded,
              ),
            ),
            SizedBox(width: B.space3),
            Expanded(
              child: _LocalTile(
                eyebrow: 'fx · yen',
                value: '1 £ = ¥ 191',
                caption: '+ 0.18% today',
                tone: B.foilGold,
                icon: Icons.currency_yen_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: B.space3),
        Row(
          children: const [
            Expanded(
              child: _LocalTile(
                eyebrow: 'cellular',
                value: 'NTT · 5G',
                caption: '8 GB available',
                tone: B.jetCyan,
                icon: Icons.sim_card_rounded,
              ),
            ),
            SizedBox(width: B.space3),
            Expanded(
              child: _LocalTile(
                eyebrow: 'consulate',
                value: 'IND · 2.4km',
                caption: '24/7 emergency line',
                tone: B.diplomaticGarnet,
                icon: Icons.support_agent_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LocalTile extends StatelessWidget {
  const _LocalTile({
    required this.eyebrow,
    required this.value,
    required this.caption,
    required this.tone,
    required this.icon,
  });
  final String eyebrow;
  final String value;
  final String caption;
  final Color tone;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return BiblePremiumCard(
      tone: tone,
      padding: const EdgeInsets.all(B.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: tone),
              const SizedBox(width: B.space1),
              BText.eyebrow(eyebrow, color: tone),
            ],
          ),
          const SizedBox(height: B.space2),
          BText.title(value, size: 16),
          const SizedBox(height: 2),
          BText.caption(caption, color: B.inkOnDarkMid),
        ],
      ),
    );
  }
}
