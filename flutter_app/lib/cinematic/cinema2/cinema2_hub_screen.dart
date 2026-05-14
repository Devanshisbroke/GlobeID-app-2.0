import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';

/// Phase 15f — Cinematics II Hub.
///
/// Capstone surface for **Phase 15 (Brand Cinematics II)**. Lists
/// every cinematic that was minted in 15a-15e plus the operator /
/// engineer governance notes for the wave:
///   • timing budget invariant (each cinematic ≤ 3.2 s)
///   • haptic vocabulary (light · medium · heavy)
///   • frame state machine via pure-data `FramesXxx.phaseAt`
///   • CustomPaint single-pass painter discipline
///   • ValueKey-driven replay
///
/// Linked routes resolve when their phase PRs (15a-15e) land.
class Cinema2HubScreen extends StatelessWidget {
  const Cinema2HubScreen({super.key});

  static const Color _foil = Color(0xFFD4AF37);
  static const Color _foilLight = Color(0xFFE9C75D);

  static const List<_Cinema2Entry> _entries = <_Cinema2Entry>[
    _Cinema2Entry(
      phaseCode: '15A',
      title: 'Wallet · ledger seal',
      subtitle: 'Ribbon → wax → press → settle',
      duration: '2.4 s',
      route: '/ceremony/ledger-seal',
      glyph: 'L',
    ),
    _Cinema2Entry(
      phaseCode: '15B',
      title: 'Trip · milestone bloom',
      subtitle: 'Ring → petals → pulse → settle',
      duration: '2.8 s',
      route: '/ceremony/milestone-bloom',
      glyph: 'B',
    ),
    _Cinema2Entry(
      phaseCode: '15C',
      title: 'Identity · tier promotion',
      subtitle: 'Glow → lift → rings → reveal → hold',
      duration: '3.2 s',
      route: '/ceremony/tier-promotion',
      glyph: 'T',
    ),
    _Cinema2Entry(
      phaseCode: '15D',
      title: 'Discover · favorite lock-in',
      subtitle: 'Toss → apex → land → lock',
      duration: '2.0 s',
      route: '/ceremony/favorite-lockin',
      glyph: 'F',
    ),
    _Cinema2Entry(
      phaseCode: '15E',
      title: 'Services · concierge handoff',
      subtitle: 'User → travel → receive → seal → settle',
      duration: '2.6 s',
      route: '/ceremony/concierge-handoff',
      glyph: 'H',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Os2Text.monoCap(
                      'CINEMA II \u00b7 15F',
                      color: _foil,
                      size: Os2.textTiny,
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Os2Text.title(
                      'CEREMONIES',
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    Os2Text.body(
                      'Five signature cinematics that mark the moments that '
                      'matter — a ledger seal, a milestone bloom, a tier '
                      'promotion, a favorite lock-in, a concierge handoff. '
                      'Engineered as deterministic phase machines and painted '
                      'in a single CustomPaint pass.',
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ],
                ),
              ),
            ),
            // Ceremony tiles.
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: _entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final e = _entries[i];
                  return _CeremonyTile(entry: e);
                },
              ),
            ),
            // Charter section.
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
              sliver: SliverToBoxAdapter(
                child: Os2Text.monoCap(
                  'CHARTER \u00b7 INVARIANTS',
                  color: _foilLight,
                  size: Os2.textTiny,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: _charter.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final c = _charter[i];
                  return _CharterRow(label: c.$1, value: c.$2);
                },
              ),
            ),
            // Operator guidance.
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
              sliver: SliverToBoxAdapter(
                child: Os2Text.monoCap(
                  'OPERATOR \u00b7 GUIDANCE',
                  color: _foilLight,
                  size: Os2.textTiny,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: _guidance.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final g = _guidance[i];
                  return _GuidanceRow(prompt: g.$1, action: g.$2);
                },
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 36, 20, 32),
              sliver: SliverToBoxAdapter(
                child: _WatermarkLine(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const List<(String, String)> _charter = <(String, String)>[
    (
      'TIMING BUDGET',
      'Every Cinema II ceremony resolves within 3.2 s · '
          'ledger-seal 2.4 · bloom 2.8 · promotion 3.2 · '
          'favorite 2.0 · handoff 2.6.',
    ),
    (
      'HAPTIC VOCABULARY',
      'Light impact opens · medium impact lands a primary event · '
          'heavy impact seals the moment · light impact resolves on '
          'completion.',
    ),
    (
      'PHASE STATE MACHINE',
      'Each cinematic exposes a `FramesXxx.phaseAt(elapsed)` pure '
          'function so chrome and haptics stay in sync with the '
          'painter and tests can lock the boundaries.',
    ),
    (
      'SINGLE PAINT PASS',
      'Cinematics are rendered through one CustomPaint per surface · '
          '`shouldRepaint` keyed on `elapsed` + `phase` only · '
          'no widget-tree thrash.',
    ),
    (
      'REPLAY DETERMINISM',
      'Replay is performed by remounting via a `ValueKey<int>` · '
          'animation state is never `seek(0)`-restarted to avoid '
          'haptic / completion races.',
    ),
  ];

  static const List<(String, String)> _guidance = <(String, String)>[
    (
      'NEW CINEMATIC?',
      'Add a `FramesXxx` class with explicit `Duration` constants and '
          'a `phaseAt` pure function before writing the painter.',
    ),
    (
      'NEW HAPTIC?',
      'Stay in the L/M/H ladder. Trigger inside `_tick` keyed by a '
          'phase-equality guard so the haptic fires exactly once.',
    ),
    (
      'NEW SURFACE?',
      'Wrap the cinematic in a Screen that exposes a `REPLAY · …` '
          'CTA using a `ValueKey<int>` mount-generation, plus a '
          'close affordance with a `Close` tooltip.',
    ),
    (
      'EXPOSING TO USERS?',
      'Route under `/ceremony/<name>` via `_blurFadeRoute` and add a '
          'Settings row pointing at it with mono-cap copy that names '
          'the phase code.',
    ),
  ];
}

class _Cinema2Entry {
  const _Cinema2Entry({
    required this.phaseCode,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.route,
    required this.glyph,
  });
  final String phaseCode;
  final String title;
  final String subtitle;
  final String duration;
  final String route;
  final String glyph;
}

class _CeremonyTile extends StatelessWidget {
  const _CeremonyTile({required this.entry});
  final _Cinema2Entry entry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(entry.route),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1018),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.36),
              width: 0.6,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.62),
                    width: 0.8,
                  ),
                ),
                child: Os2Text.title(
                  entry.glyph,
                  color: const Color(0xFFE9C75D),
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Os2Text.monoCap(
                          'PHASE \u00b7 ${entry.phaseCode}',
                          color: const Color(0xFFD4AF37),
                          size: Os2.textTiny,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFD4AF37)
                                  .withValues(alpha: 0.42),
                              width: 0.6,
                            ),
                          ),
                          child: Os2Text.monoCap(
                            entry.duration,
                            color: const Color(0xFFE9C75D),
                            size: 8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Os2Text.title(
                      entry.title,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(height: 2),
                    Os2Text.body(
                      entry.subtitle,
                      color: Colors.white.withValues(alpha: 0.62),
                      size: 12,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: const Color(0xFFD4AF37).withValues(alpha: 0.72),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CharterRow extends StatelessWidget {
  const _CharterRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0D14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 0.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Os2Text.monoCap(
            label,
            color: const Color(0xFFE9C75D),
            size: Os2.textTiny,
          ),
          const SizedBox(height: 4),
          Os2Text.body(
            value,
            color: Colors.white.withValues(alpha: 0.86),
            size: 12,
          ),
        ],
      ),
    );
  }
}

class _GuidanceRow extends StatelessWidget {
  const _GuidanceRow({required this.prompt, required this.action});
  final String prompt;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0D14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.22),
          width: 0.6,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.add_box_outlined,
              size: 14,
              color: const Color(0xFFD4AF37).withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Os2Text.monoCap(
                  prompt,
                  color: const Color(0xFFD4AF37),
                  size: Os2.textTiny,
                ),
                const SizedBox(height: 4),
                Os2Text.body(
                  action,
                  color: Colors.white.withValues(alpha: 0.78),
                  size: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WatermarkLine extends StatelessWidget {
  const _WatermarkLine();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Os2Text.monoCap(
          'CINEMA II \u00b7 15F',
          color: const Color(0xFFD4AF37).withValues(alpha: 0.62),
          size: Os2.textTiny,
        ),
        Os2Text.monoCap(
          'GLOBE \u00b7 ID',
          color: Colors.white.withValues(alpha: 0.42),
          size: Os2.textTiny,
        ),
      ],
    );
  }
}
