import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/pressable.dart';
import '../models/atelier_catalog.dart';

/// Phase 14a — Atelier gallery scaffold.
///
/// Top-level entry into the GlobeID internal design system. The
/// operator descends through domains (typography → interaction →
/// state → live) and taps any component to read its canonical
/// role + token spec in a dedicated detail surface.
class AtelierGalleryScreen extends StatelessWidget {
  const AtelierGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final grouped = AtelierCatalog.grouped();
    return PageScaffold(
      eyebrow: 'ATELIER · 14A',
      title: 'Design System',
      subtitle: 'Catalog · 19 primitives · 4 domains',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: [
          const _AtelierIntro(),
          const SizedBox(height: Os2.space5),
          for (final domain in AtelierDomain.values) ...[
            _DomainHeader(domain: domain),
            const SizedBox(height: Os2.space3),
            for (final c in grouped[domain] ?? <AtelierComponent>[]) ...[
              _ComponentCard(component: c),
              const SizedBox(height: Os2.space2),
            ],
            const SizedBox(height: Os2.space5),
          ],
          const _AtelierFooter(),
        ],
      ),
    );
  }
}

class _AtelierIntro extends StatelessWidget {
  const _AtelierIntro();

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
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.10),
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
                'ATELIER · MANIFEST',
                color: const Color(0xFFD4AF37),
                size: Os2.textTiny,
              ),
              const Spacer(),
              Os2Text.monoCap(
                'N° 14A.00',
                color: Colors.white.withValues(alpha: 0.42),
                size: Os2.textTiny,
              ),
            ],
          ),
          const SizedBox(height: Os2.space2),
          const Text(
            'Every brand primitive in one place',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: Os2.space2),
          Text(
            'Atelier is the internal reference for the GlobeID design '
            'language. Eighteen primitives, four domains. Tap any '
            'card to read its canonical role + tokens.',
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

class _DomainHeader extends StatelessWidget {
  const _DomainHeader({required this.domain});
  final AtelierDomain domain;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 10, bottom: 4),
            decoration: BoxDecoration(
              color: domain.tone,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: domain.tone.withValues(alpha: 0.62),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Os2Text.monoCap(
                domain.label,
                color: domain.tone,
                size: Os2.textTiny,
              ),
              const SizedBox(height: 2),
              Text(
                domain.subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComponentCard extends StatelessWidget {
  const _ComponentCard({required this.component});
  final AtelierComponent component;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: '${component.name} reference',
      semanticHint: 'opens the canonical role and token spec',
      onTap: () => context.push('/atelier/${component.id}'),
      child: Container(
        padding: const EdgeInsets.all(Os2.space4),
        decoration: BoxDecoration(
          color: Os2.floor1,
          borderRadius: BorderRadius.circular(Os2.rCard),
          border: Border.all(
            color: component.domain.tone.withValues(alpha: 0.32),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: component.domain.tone.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: component.domain.tone.withValues(alpha: 0.62),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _initials(component.name),
                style: TextStyle(
                  color: component.domain.tone,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
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
                    component.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    component.summary,
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
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: Colors.white.withValues(alpha: 0.42),
            ),
          ],
        ),
      ),
    );
  }
}

String _initials(String name) {
  // "Os2Text.display" → "OD"; "BreathingHalo" → "BH"; "Pressable" → "P".
  // Picks the first letter of each capitalised segment.
  final letters = <String>[];
  for (final ch in name.split('')) {
    if (ch == '.' || ch == ' ' || ch == '_') continue;
    if (ch == ch.toUpperCase() && ch != ch.toLowerCase()) {
      letters.add(ch);
    }
  }
  if (letters.length >= 2) return '${letters[0]}${letters[1]}';
  if (letters.length == 1) return letters[0];
  return name.substring(0, 1).toUpperCase();
}

class _AtelierFooter extends StatelessWidget {
  const _AtelierFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Os2Text.monoCap(
            'ATELIER · ROADMAP',
            color: const Color(0xFFD4AF37),
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space2),
          _RoadmapRow(
            phase: '14A',
            label: 'Component gallery scaffold',
            done: true,
          ),
          _RoadmapRow(
            phase: '14B',
            label: 'Motion choreography lab',
            done: false,
          ),
          _RoadmapRow(
            phase: '14C',
            label: 'Brand token export (tokens.json)',
            done: false,
          ),
          _RoadmapRow(
            phase: '14D',
            label: 'Visual regression golden tests',
            done: false,
          ),
          _RoadmapRow(
            phase: '14E',
            label: 'Brand DNA timeline doc',
            done: false,
          ),
          _RoadmapRow(
            phase: '14F',
            label: 'Atelier capstone hub',
            done: false,
          ),
        ],
      ),
    );
  }
}

class _RoadmapRow extends StatelessWidget {
  const _RoadmapRow({
    required this.phase,
    required this.label,
    required this.done,
  });
  final String phase;
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final tone = done
        ? const Color(0xFFE9C75D)
        : Colors.white.withValues(alpha: 0.42);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 40,
            child: Text(
              phase,
              style: TextStyle(
                color: tone,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: done
                    ? Colors.white.withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.52),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
