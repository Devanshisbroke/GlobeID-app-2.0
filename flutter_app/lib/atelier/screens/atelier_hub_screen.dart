import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/pressable.dart';

/// Phase 14f — Atelier capstone hub.
///
/// Brings the five Atelier sub-phases (14a-14e) under one surface:
///
///   - Component gallery     (14a · 19 primitives · 4 domains)
///   - Motion choreography   (14b · 10 durations · 6 curves)
///   - Brand tokens          (14c · 67 tokens · JSON)
///   - Visual regression     (14d · 8 specimens · canonical)
///   - DNA timeline          (14e · 14 chapters · invariants)
///
/// The hub is intentionally lean — it routes to the labs, surfaces
/// their stats live, and reads as the single entry-point for the
/// whole Atelier domain.
class AtelierHubScreen extends StatelessWidget {
  const AtelierHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = _hubModules();
    return PageScaffold(
      eyebrow: 'ATELIER · 14F',
      title: 'Atelier · Hub',
      subtitle:
          '${modules.length} modules · gallery · motion · tokens · '
          'regression · DNA',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: [
          const _HubIntro(),
          const SizedBox(height: Os2.space5),
          _SectionHeader(label: 'ATELIER · MODULES'),
          const SizedBox(height: Os2.space2),
          for (final m in modules) ...[
            _ModuleCard(module: m),
            const SizedBox(height: Os2.space2),
          ],
          const SizedBox(height: Os2.space5),
          _SectionHeader(label: 'INVARIANTS · CHARTER'),
          const SizedBox(height: Os2.space2),
          const _InvariantsCard(),
          const SizedBox(height: Os2.space5),
          _SectionHeader(label: 'OPERATOR · GUIDANCE'),
          const SizedBox(height: Os2.space2),
          const _GuidanceCard(),
        ],
      ),
    );
  }

  List<_HubModule> _hubModules() {
    return const <_HubModule>[
      _HubModule(
        phase: '14A',
        title: 'Component gallery',
        summary: '19 primitives across 4 domains',
        stat: '19 / 4',
        statLabel: 'PRIMITIVES · DOMAINS',
        route: '/atelier',
        tone: Color(0xFFD4AF37),
      ),
      _HubModule(
        phase: '14B',
        title: 'Motion choreography',
        summary: '10 durations · 6 curves · live preview',
        stat: '10 / 6',
        statLabel: 'DURATIONS · CURVES',
        route: '/atelier/lab/motion',
        tone: Color(0xFFE9C75D),
      ),
      _HubModule(
        phase: '14C',
        title: 'Brand tokens · export',
        summary: '67 tokens · tokens.json · schema v1',
        stat: '67',
        statLabel: 'TOKENS',
        route: '/atelier/lab/tokens',
        tone: Color(0xFFC9A961),
      ),
      _HubModule(
        phase: '14D',
        title: 'Visual regression',
        summary: '8 specimens · canonical sizing',
        stat: '8',
        statLabel: 'SPECIMENS',
        route: '/atelier/lab/regression',
        tone: Color(0xFFB8902B),
      ),
      _HubModule(
        phase: '14E',
        title: 'Brand DNA timeline',
        summary: '14 chapters · append-only · invariants',
        stat: '14',
        statLabel: 'CHAPTERS',
        route: '/atelier/lab/dna-timeline',
        tone: Color(0xFFD4AF37),
      ),
    ];
  }
}

class _HubModule {
  const _HubModule({
    required this.phase,
    required this.title,
    required this.summary,
    required this.stat,
    required this.statLabel,
    required this.route,
    required this.tone,
  });

  final String phase;
  final String title;
  final String summary;
  final String stat;
  final String statLabel;
  final String route;
  final Color tone;
}

class _HubIntro extends StatelessWidget {
  const _HubIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.42),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Os2Text.monoCap(
                'ATELIER · HUB',
                color: const Color(0xFFD4AF37),
                size: Os2.textTiny,
              ),
              const Spacer(),
              Os2Text.monoCap(
                'N° 14F.00',
                color: Colors.white.withValues(alpha: 0.42),
                size: Os2.textTiny,
              ),
            ],
          ),
          const SizedBox(height: Os2.space2),
          const Text(
            'The brand · documented · exportable · regressed',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: Os2.space2),
          Text(
            'Atelier is the single source of truth for the GlobeID '
            'design language. Component gallery (14a). Motion '
            'choreography (14b). Token export (14c). Visual '
            'regression (14d). DNA timeline (14e). This hub (14f) '
            'routes between them.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.only(right: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFD4AF37),
            shape: BoxShape.circle,
          ),
        ),
        Os2Text.monoCap(
          label,
          color: const Color(0xFFD4AF37),
          size: Os2.textTiny,
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module});
  final _HubModule module;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => context.push(module.route),
      semanticLabel: '${module.title}, opens ${module.phase} lab',
      semanticHint: module.summary,
      child: Container(
        padding: const EdgeInsets.all(Os2.space4),
        decoration: BoxDecoration(
          color: Os2.floor1,
          borderRadius: BorderRadius.circular(Os2.rCard),
          border: Border.all(
            color: module.tone.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: module.tone.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: module.tone.withValues(alpha: 0.62),
                  width: 0.6,
                ),
              ),
              child: Text(
                module.phase,
                style: TextStyle(
                  color: module.tone,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: Os2.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    module.summary,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Os2.space2),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  module.stat,
                  style: TextStyle(
                    color: module.tone,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    fontFamily: 'monospace',
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Os2Text.monoCap(
                  module.statLabel,
                  color: Colors.white.withValues(alpha: 0.42),
                  size: 8.5,
                ),
              ],
            ),
            const SizedBox(width: Os2.space2),
            Icon(
              Icons.chevron_right_rounded,
              color: module.tone.withValues(alpha: 0.72),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _InvariantsCard extends StatelessWidget {
  const _InvariantsCard();

  @override
  Widget build(BuildContext context) {
    const invariants = <String>[
      'Foil gold is #D4AF37 (base) and #E9C75D (light). No other gold.',
      'OLED canvas is #050505. No grey backgrounds.',
      'Mono-cap chrome runs Departure Mono, w800, +1.6 tracking.',
      'Hairline frames are 0.6 px wide · 42 % gold alpha.',
      'GLOBE · ID watermark is locale-immutable, painted LTR.',
      'Motion vocabulary is named. No magic durations or curves.',
      'Haptics vocabulary is named. No bare Haptics calls.',
      'No bespoke sheets. Every modal goes through AppleSheet.',
      'Every Live surface breathes. Cadence reflects underlying state.',
      'Every "first time" earns a ceremony. No first-mount is silent.',
      'Every credential carries chain-of-custody attestation chrome.',
      'Empty / error / loading states ship via CinematicStateChrome.',
      'Hot tappables announce role + label + hint to assistive tech.',
      'Network failure ships brand chrome — STALE chips, not gone.',
      'Reduced motion respects role taxonomy (structural / ambient / signature).',
      'WCAG AA contrast everywhere; AAA where text size allows.',
      'Type scale is named (textTiny → textH1). No magic font sizes.',
      'Atelier is append-only. Existing chapters cannot be rewritten.',
    ];
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final inv in invariants) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6, right: 10),
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD4AF37),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      inv,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GuidanceLine(
            head: 'NEW · SURFACE?',
            body:
                'Compose from AtelierCatalog primitives first. Add a new '
                'primitive only after auditing whether an existing one '
                'covers the role.',
          ),
          const SizedBox(height: Os2.space3),
          _GuidanceLine(
            head: 'NEW · MOTION?',
            body:
                'Pick a named Motion duration + curve. If no existing '
                'token fits, propose one to the bible before shipping.',
          ),
          const SizedBox(height: Os2.space3),
          _GuidanceLine(
            head: 'NEW · TOKEN?',
            body:
                'Add the constant to Os2 / Motion first, then re-export '
                'tokens.json so downstream surfaces stay in sync.',
          ),
          const SizedBox(height: Os2.space3),
          _GuidanceLine(
            head: 'NEW · BRAND DECISION?',
            body:
                'Add a chapter to BrandDnaTimeline. Append-only — never '
                'rewrite a shipped chapter.',
          ),
        ],
      ),
    );
  }
}

class _GuidanceLine extends StatelessWidget {
  const _GuidanceLine({required this.head, required this.body});
  final String head;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Os2Text.monoCap(
            head,
            color: const Color(0xFFD4AF37),
            size: Os2.textTiny,
          ),
        ),
        Expanded(
          child: Text(
            body,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
