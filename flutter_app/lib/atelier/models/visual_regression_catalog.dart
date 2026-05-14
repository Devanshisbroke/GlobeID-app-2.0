import 'package:flutter/material.dart';

import '../../cinematic/live/live_primitives.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';

/// Atelier — visual-regression specimen catalog.
///
/// Each specimen is a small, deterministic widget that paints one
/// brand primitive at a known canonical size. The catalog is the
/// source of truth for both:
///
///   1. The manual visual-regression lab (operator scrolls a grid of
///      primitives and eyeballs drift), and
///   2. The structural invariants tests (paint occurs, color hash
///      lands in the expected family, layout doesn't shift).
class VisualRegressionCatalog {
  VisualRegressionCatalog._();

  static const List<VisualSpecimen> specimens = <VisualSpecimen>[
    VisualSpecimen(
      id: 'os2text-monocap',
      group: 'TYPOGRAPHY',
      name: 'Os2Text · monoCap',
      summary: 'Mono-cap brand chrome eyebrow / pill label',
      canonicalSize: Size(180, 18),
      tone: Color(0xFFD4AF37),
      builder: _buildMonoCap,
    ),
    VisualSpecimen(
      id: 'os2text-display',
      group: 'TYPOGRAPHY',
      name: 'Os2Text · display',
      summary: 'Hero numeral · tabular figures',
      canonicalSize: Size(220, 64),
      tone: Color(0xFFFFFFFF),
      builder: _buildDisplay,
    ),
    VisualSpecimen(
      id: 'globe-id-signature',
      group: 'LIVE',
      name: 'GlobeIdSignature',
      summary: 'GLOBE · ID watermark mark · serial-aware',
      canonicalSize: Size(180, 18),
      tone: Color(0xFFE9C75D),
      builder: _buildSignature,
    ),
    VisualSpecimen(
      id: 'live-status-pill-idle',
      group: 'LIVE',
      name: 'LiveStatusPill · idle',
      summary: 'State chip — idle surface',
      canonicalSize: Size(140, 26),
      tone: Color(0xFFB8902B),
      builder: _buildPillIdle,
    ),
    VisualSpecimen(
      id: 'live-status-pill-active',
      group: 'LIVE',
      name: 'LiveStatusPill · active',
      summary: 'State chip — surface armed + connected',
      canonicalSize: Size(140, 26),
      tone: Color(0xFFD4AF37),
      builder: _buildPillActive,
    ),
    VisualSpecimen(
      id: 'live-status-pill-committed',
      group: 'LIVE',
      name: 'LiveStatusPill · committed',
      summary: 'State chip — credential committed',
      canonicalSize: Size(140, 26),
      tone: Color(0xFFE9C75D),
      builder: _buildPillCommitted,
    ),
    VisualSpecimen(
      id: 'hairline-frame',
      group: 'SURFACE',
      name: 'Hairline frame',
      summary: 'Canonical brand frame (0.6 px · gold · 42% alpha)',
      canonicalSize: Size(180, 80),
      tone: Color(0xFFD4AF37),
      builder: _buildHairlineFrame,
    ),
    VisualSpecimen(
      id: 'watermark-substrate',
      group: 'SURFACE',
      name: 'Watermark substrate',
      summary: 'OLED canvas + GLOBE·ID watermark',
      canonicalSize: Size(200, 100),
      tone: Color(0xFF050505),
      builder: _buildWatermarkSubstrate,
    ),
  ];

  /// Returns the specimen by id (null if not found).
  static VisualSpecimen? byId(String id) {
    for (final s in specimens) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Returns a unique list of group labels in author order.
  static List<String> groups() {
    final out = <String>[];
    for (final s in specimens) {
      if (!out.contains(s.group)) out.add(s.group);
    }
    return out;
  }

  static Widget _buildMonoCap(BuildContext context) {
    return Os2Text.monoCap(
      'GLOBE · MONO',
      color: const Color(0xFFD4AF37),
      size: Os2.textXs,
    );
  }

  static Widget _buildDisplay(BuildContext context) {
    return const Text(
      '0048',
      style: TextStyle(
        color: Colors.white,
        fontSize: 56,
        fontWeight: FontWeight.w900,
        letterSpacing: -2.4,
        fontFamily: 'monospace',
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }

  static Widget _buildSignature(BuildContext context) {
    return const GlobeIdSignature();
  }

  static Widget _buildPillIdle(BuildContext context) {
    return const LiveStatusPill(state: LiveSurfaceState.idle);
  }

  static Widget _buildPillActive(BuildContext context) {
    return const LiveStatusPill(state: LiveSurfaceState.active);
  }

  static Widget _buildPillCommitted(BuildContext context) {
    return const LiveStatusPill(state: LiveSurfaceState.committed);
  }

  static Widget _buildHairlineFrame(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        borderRadius: BorderRadius.circular(Os2.rTile),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.42),
          width: 0.6,
        ),
      ),
      alignment: Alignment.center,
      child: Os2Text.monoCap(
        'HAIRLINE · FRAME',
        color: const Color(0xFFD4AF37),
        size: Os2.textTiny,
      ),
    );
  }

  static Widget _buildWatermarkSubstrate(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF050505),
              borderRadius: BorderRadius.circular(Os2.rTile),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          right: 12,
          child: Opacity(
            opacity: 0.6,
            child: Os2Text.monoCap(
              'GLOBE · ID',
              color: Colors.white,
              size: Os2.textTiny,
            ),
          ),
        ),
      ],
    );
  }
}

class VisualSpecimen {
  const VisualSpecimen({
    required this.id,
    required this.group,
    required this.name,
    required this.summary,
    required this.canonicalSize,
    required this.tone,
    required this.builder,
  });

  final String id;
  final String group;
  final String name;
  final String summary;
  final Size canonicalSize;
  final Color tone;
  final WidgetBuilder builder;
}
