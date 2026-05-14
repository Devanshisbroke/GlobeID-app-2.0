import 'package:flutter/material.dart';

import '../../i18n/brand_contrast.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';

/// Phase 13e — WCAG AA contrast audit lab.
///
/// Audits every GlobeID brand tone against every canonical
/// substrate. Each row shows the contrast ratio + WCAG band so
/// the operator can see at a glance which pairings pass AA / AAA
/// and which need re-tuning.
class WcagAuditScreen extends StatelessWidget {
  const WcagAuditScreen({super.key});

  static const Color _oledDeep = Color(0xFF050505);
  static const Color _oledTilt = Color(0xFF050912);
  static const Color _floorOne = Color(0xFF0A0C12);
  static const Color _floorTwo = Color(0xFF11141C);

  static const Color _foilGold = Color(0xFFD4AF37);
  static const Color _foilLight = Color(0xFFE9C75D);
  static const Color _foilMuted = Color(0xFFC9A961);
  static const Color _hairline46 = Color(0x76FFFFFF);
  static const Color _bodyHigh = Color(0xFFFFFFFF);
  static const Color _bodyMid = Color(0xB3FFFFFF);
  static const Color _bodyLow = Color(0x7AFFFFFF);
  static const Color _emerald = Color(0xFF14B886);
  static const Color _coral = Color(0xFFEF6464);
  static const Color _classifiedRed = Color(0xFFA22236);

  @override
  Widget build(BuildContext context) {
    final pairs = <_ContrastPair>[
      const _ContrastPair('Foil gold', _foilGold, 'OLED deep', _oledDeep),
      const _ContrastPair('Foil gold', _foilGold, 'OLED tilt', _oledTilt),
      const _ContrastPair('Foil gold', _foilGold, 'Floor 1', _floorOne),
      const _ContrastPair('Foil gold', _foilGold, 'Floor 2', _floorTwo),
      const _ContrastPair('Foil light', _foilLight, 'OLED deep', _oledDeep),
      const _ContrastPair('Foil muted', _foilMuted, 'OLED deep', _oledDeep),
      const _ContrastPair(
          'Hairline 46%', _hairline46, 'OLED deep', _oledDeep),
      const _ContrastPair('Body high', _bodyHigh, 'OLED deep', _oledDeep),
      const _ContrastPair('Body mid', _bodyMid, 'OLED deep', _oledDeep),
      const _ContrastPair('Body low', _bodyLow, 'OLED deep', _oledDeep),
      const _ContrastPair('Emerald', _emerald, 'OLED deep', _oledDeep),
      const _ContrastPair('Coral', _coral, 'OLED deep', _oledDeep),
      const _ContrastPair(
          'Classified red', _classifiedRed, 'OLED deep', _oledDeep),
    ];

    final groups = <_Group>[
      _Group(
        eyebrow: 'BRAND · FOIL',
        pairs: pairs.where((p) => p.fgLabel.startsWith('Foil')).toList(),
      ),
      _Group(
        eyebrow: 'CHROME · HAIRLINE / BODY',
        pairs: pairs
            .where((p) =>
                p.fgLabel.startsWith('Hairline') ||
                p.fgLabel.startsWith('Body'))
            .toList(),
      ),
      _Group(
        eyebrow: 'SEMANTIC · ACCENTS',
        pairs: pairs
            .where((p) =>
                p.fgLabel.startsWith('Emerald') ||
                p.fgLabel.startsWith('Coral') ||
                p.fgLabel.startsWith('Classified'))
            .toList(),
      ),
    ];

    return PageScaffold(
      eyebrow: 'PHASE · 13E',
      title: 'WCAG AA contrast audit',
      subtitle: 'Brand foil + chrome + accents vs canonical substrates',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: [
          for (final group in groups) ...[
            _GroupCard(group: group),
            const SizedBox(height: Os2.space3),
          ],
          const _LegendCard(),
        ],
      ),
    );
  }
}

class _Group {
  const _Group({required this.eyebrow, required this.pairs});
  final String eyebrow;
  final List<_ContrastPair> pairs;
}

class _ContrastPair {
  const _ContrastPair(this.fgLabel, this.fg, this.bgLabel, this.bg);
  final String fgLabel;
  final Color fg;
  final String bgLabel;
  final Color bg;
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});
  final _Group group;

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
            group.eyebrow,
            color: const Color(0xFFD4AF37),
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space3),
          for (final pair in group.pairs) _PairRow(pair: pair),
        ],
      ),
    );
  }
}

class _PairRow extends StatelessWidget {
  const _PairRow({required this.pair});
  final _ContrastPair pair;

  @override
  Widget build(BuildContext context) {
    // Composite translucent foregrounds onto the substrate so the
    // measured ratio reflects what the eye actually sees (hairlines
    // at 46% alpha don't visually contrast as full white).
    final ratio = BrandContrast.effectiveRatio(pair.fg, pair.bg);
    final band = BrandContrast.bandFor(ratio);
    final bandTone = _bandTone(band);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: pair.bg,
          borderRadius: BorderRadius.circular(Os2.rChip),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: pair.fg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 0.6,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pair.fgLabel,
                    style: TextStyle(
                      color: pair.fg,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.1,
                    ),
                  ),
                  Text(
                    'on · ${pair.bgLabel}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.42),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              ratio.toStringAsFixed(2),
              style: TextStyle(
                color: pair.fg,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: bandTone.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: bandTone.withValues(alpha: 0.62), width: 0.6),
              ),
              child: Text(
                band.label,
                style: TextStyle(
                  color: bandTone,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _bandTone(ContrastBand band) {
  switch (band) {
    case ContrastBand.aaaNormal:
      return const Color(0xFFE9C75D);
    case ContrastBand.aaNormal:
      return const Color(0xFFD4AF37);
    case ContrastBand.aaLarge:
      return const Color(0xFF6B8FB8);
    case ContrastBand.fail:
      return const Color(0xFFEF6464);
  }
}

class _LegendCard extends StatelessWidget {
  const _LegendCard();

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
            'WCAG · LEGEND',
            color: const Color(0xFFD4AF37),
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space3),
          _LegendRow(
            band: ContrastBand.aaaNormal,
            threshold: '≥ 7.0',
            note: 'AAA · best-in-class for normal body text',
          ),
          _LegendRow(
            band: ContrastBand.aaNormal,
            threshold: '≥ 4.5',
            note: 'AA · normal body text',
          ),
          _LegendRow(
            band: ContrastBand.aaLarge,
            threshold: '≥ 3.0',
            note: 'AA · large text (≥ 18 pt / 14 pt bold) + non-text',
          ),
          _LegendRow(
            band: ContrastBand.fail,
            threshold: '< 3.0',
            note: 'Fails WCAG — re-tune or upgrade tone weight',
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.band,
    required this.threshold,
    required this.note,
  });
  final ContrastBand band;
  final String threshold;
  final String note;

  @override
  Widget build(BuildContext context) {
    final tone = _bandTone(band);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: tone.withValues(alpha: 0.62), width: 0.6),
              ),
              child: Text(
                band.label,
                style: TextStyle(
                  color: tone,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: 58,
            child: Text(
              threshold,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Expanded(
            child: Text(
              note,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
