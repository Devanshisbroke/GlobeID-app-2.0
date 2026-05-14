import 'package:flutter/material.dart';

import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';
import '../models/atelier_catalog.dart';

/// Atelier — single-component detail screen.
///
/// Renders the canonical role + token spec for one primitive. The
/// preview slot is intentionally generic in 14a — Phase 14b will
/// layer in live previews (motion choreography, real instances of
/// the component rendered inline).
class AtelierComponentScreen extends StatelessWidget {
  const AtelierComponentScreen({super.key, required this.componentId});

  final String componentId;

  @override
  Widget build(BuildContext context) {
    final component = AtelierCatalog.byId(componentId);
    if (component == null) {
      return _AtelierNotFound(componentId: componentId);
    }
    return PageScaffold(
      eyebrow: component.domain.label,
      title: component.name,
      subtitle: 'Atelier · canonical reference',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: [
          _PreviewSubstrate(component: component),
          const SizedBox(height: Os2.space5),
          _SectionHeader(
            label: 'CANONICAL · ROLE',
            tone: component.domain.tone,
          ),
          const SizedBox(height: Os2.space2),
          _Card(child: Text(component.role, style: _bodyStyle())),
          const SizedBox(height: Os2.space5),
          _SectionHeader(
            label: 'TOKEN · SPEC',
            tone: component.domain.tone,
          ),
          const SizedBox(height: Os2.space2),
          _Card(
            child: Text(
              component.tokenSummary,
              style: _bodyStyle().copyWith(fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: Os2.space5),
          _SectionHeader(
            label: 'USAGE · SUMMARY',
            tone: component.domain.tone,
          ),
          const SizedBox(height: Os2.space2),
          _Card(
            child: Text(
              _usageBlurbFor(component),
              style: _bodyStyle(),
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle _bodyStyle() => TextStyle(
      color: Colors.white.withValues(alpha: 0.85),
      fontSize: 13,
      fontWeight: FontWeight.w600,
      height: 1.5,
    );

String _usageBlurbFor(AtelierComponent c) {
  switch (c.domain) {
    case AtelierDomain.typography:
      return 'Compose with one Os2Text variant per role. Never mix '
          'two display variants on the same surface. Mono-cap '
          'eyebrows always sit above their content, never below.';
    case AtelierDomain.interaction:
      return 'Wrap every hot tappable. Always set semanticLabel + '
          'semanticHint so screen readers announce the affordance. '
          'Never wrap a disabled element — show a static row instead.';
    case AtelierDomain.state:
      return 'Replaces every blank, spinner, or error string in the '
          'app. Compose the three variants so empty / loading / '
          'error all render with the same chrome ladder.';
    case AtelierDomain.live:
      return 'Live primitives respect reduced motion — ambient ones '
          'collapse to a placeholder, signature ones run at 50 % '
          'duration. Haptics always fire regardless of motion '
          'preferences.';
  }
}

class _PreviewSubstrate extends StatelessWidget {
  const _PreviewSubstrate({required this.component});
  final AtelierComponent component;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space5),
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(
          color: component.domain.tone.withValues(alpha: 0.42),
        ),
        boxShadow: [
          BoxShadow(
            color: component.domain.tone.withValues(alpha: 0.10),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Os2Text.monoCap(
                'PREVIEW · STATIC',
                color: component.domain.tone,
                size: Os2.textTiny,
              ),
              const Spacer(),
              Os2Text.monoCap(
                'N° ${component.id.toUpperCase()}',
                color: Colors.white.withValues(alpha: 0.42),
                size: Os2.textTiny,
              ),
            ],
          ),
          const SizedBox(height: Os2.space4),
          Center(
            child: Text(
              component.summary,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: Os2.space3),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: component.domain.tone.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: component.domain.tone.withValues(alpha: 0.62),
                  width: 0.6,
                ),
              ),
              child: Text(
                'PHASE · 14B · LIVE PREVIEW TBD',
                style: TextStyle(
                  color: component.domain.tone,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.tone});
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
        ),
        Os2Text.monoCap(label, color: tone, size: Os2.textTiny),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: child,
    );
  }
}

class _AtelierNotFound extends StatelessWidget {
  const _AtelierNotFound({required this.componentId});
  final String componentId;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      eyebrow: 'ATELIER · MISS',
      title: 'Component not found',
      subtitle: 'Catalog lookup miss',
      body: Padding(
        padding: const EdgeInsets.all(Os2.space5),
        child: Text(
          'No catalog entry for id "$componentId". The Atelier '
          'catalog is the canonical source — add an entry there '
          'before linking to this route.',
          style: _bodyStyle(),
        ),
      ),
    );
  }
}
