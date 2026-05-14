import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/pressable.dart';
import '../models/brand_tokens.dart';

/// Phase 14c — Brand-token export viewer.
///
/// Renders the live BrandTokens.toPrettyJson() output and lets the
/// operator copy it. The asset at `assets/atelier/tokens.json` is
/// kept in lock-step with this exporter (enforced by a test), so
/// designers / web / watch surfaces can read either source.
class TokensExportScreen extends StatelessWidget {
  const TokensExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final json = BrandTokens.toPrettyJson();
    final summary = _buildSummary();
    return PageScaffold(
      eyebrow: 'ATELIER · 14C',
      title: 'Brand Tokens',
      subtitle: 'Schema v${BrandTokens.schemaVersion} · '
          '${BrandTokens.totalCount} tokens · JSON',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: [
          _ExportIntro(json: json),
          const SizedBox(height: Os2.space5),
          _SectionHeader(label: 'SCHEMA · OVERVIEW'),
          const SizedBox(height: Os2.space2),
          for (final row in summary) ...[
            _SummaryRow(row: row),
            const SizedBox(height: Os2.space2),
          ],
          const SizedBox(height: Os2.space5),
          _SectionHeader(label: 'TOKEN · JSON'),
          const SizedBox(height: Os2.space2),
          _JsonBlock(json: json),
          const SizedBox(height: Os2.space5),
          _SectionHeader(label: 'CONSUMER · NOTES'),
          const SizedBox(height: Os2.space2),
          _Card(
            child: Text(
              'tokens.json is the canonical export. Downstream surfaces '
              '(marketing site, watch face, web companion) read this '
              'file instead of mirroring the in-app constants. The '
              '\$schema field is bumped whenever the shape of the '
              'document changes; consumers should pin to a major '
              'version and migrate explicitly.',
              style: _body(),
            ),
          ),
        ],
      ),
    );
  }

  List<_SummaryEntry> _buildSummary() {
    return <_SummaryEntry>[
      _SummaryEntry(
        label: 'COLORS',
        count: BrandTokens.colorTokens().length,
        tone: const Color(0xFFD4AF37),
      ),
      _SummaryEntry(
        label: 'SPACING',
        count: BrandTokens.spacingTokens().length,
        tone: const Color(0xFFE9C75D),
      ),
      _SummaryEntry(
        label: 'RADIUS',
        count: BrandTokens.radiusTokens().length,
        tone: const Color(0xFFC9A961),
      ),
      _SummaryEntry(
        label: 'TYPOGRAPHY',
        count: BrandTokens.typographyTokens().length,
        tone: const Color(0xFFE9C75D),
      ),
      _SummaryEntry(
        label: 'MOTION · DURATION',
        count: BrandTokens.motionDurationTokens().length,
        tone: const Color(0xFF6B8FB8),
      ),
      _SummaryEntry(
        label: 'MOTION · CURVE',
        count: BrandTokens.motionCurveTokens().length,
        tone: const Color(0xFF6B8FB8),
      ),
    ];
  }
}

TextStyle _body() => TextStyle(
      color: Colors.white.withValues(alpha: 0.78),
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      height: 1.45,
    );

class _SummaryEntry {
  const _SummaryEntry({
    required this.label,
    required this.count,
    required this.tone,
  });
  final String label;
  final int count;
  final Color tone;
}

class _ExportIntro extends StatelessWidget {
  const _ExportIntro({required this.json});
  final String json;

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
                'TOKEN · EXPORT',
                color: const Color(0xFFD4AF37),
                size: Os2.textTiny,
              ),
              const Spacer(),
              Os2Text.monoCap(
                'N° 14C.00',
                color: Colors.white.withValues(alpha: 0.42),
                size: Os2.textTiny,
              ),
            ],
          ),
          const SizedBox(height: Os2.space2),
          const Text(
            'Canonical JSON for every brand token',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: Os2.space2),
          Text(
            'Colors · spacing · radius · typography · motion. '
            'Generated live from the in-app Motion + Os2 token sources. '
            'Asset at assets/atelier/tokens.json mirrors this output '
            'and is enforced by a test.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: Os2.space3),
          Pressable(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: json));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tokens copied · paste anywhere'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            semanticLabel: 'Copy tokens JSON',
            semanticHint: 'copies the full brand token export to clipboard',
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.62),
                ),
              ),
              child: Os2Text.monoCap(
                'COPY · JSON',
                color: const Color(0xFFD4AF37),
                size: Os2.textTiny,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.row});
  final _SummaryEntry row;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Os2.space4,
        vertical: Os2.space3,
      ),
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(
          color: row.tone.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: row.tone,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Os2Text.monoCap(
              row.label,
              color: Colors.white,
              size: Os2.textXs,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: row.tone.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: row.tone.withValues(alpha: 0.62),
                width: 0.6,
              ),
            ),
            child: Text(
              row.count.toString(),
              style: TextStyle(
                color: row.tone,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JsonBlock extends StatelessWidget {
  const _JsonBlock({required this.json});
  final String json;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space3),
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        borderRadius: BorderRadius.circular(Os2.rTile),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.32),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          json,
          style: const TextStyle(
            color: Color(0xFFE9C75D),
            fontFamily: 'monospace',
            fontSize: 11,
            height: 1.4,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
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
