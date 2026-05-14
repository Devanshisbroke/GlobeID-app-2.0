import 'package:flutter/material.dart';

import '../../i18n/globe_id_locale.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/pressable.dart';

/// Phase 13a — locale gallery (live preview).
///
/// 5-locale ladder (en / ar / zh / es / ja). Tapping a locale flips
/// the live preview card so the operator can verify that every
/// canonical brand string + chrome direction reads correctly under
/// the new locale. The GLOBE · ID watermark stays LTR Latin in every
/// preview — brand chrome is the constant, body copy is the variable.
class LocaleGalleryScreen extends StatefulWidget {
  const LocaleGalleryScreen({super.key});

  @override
  State<LocaleGalleryScreen> createState() => _LocaleGalleryScreenState();
}

class _LocaleGalleryScreenState extends State<LocaleGalleryScreen> {
  GlobeIdLocale _previewLocale = GlobeIdLocale.enUS;

  @override
  Widget build(BuildContext context) {
    final strings = GlobeIdStrings.of(_previewLocale);
    return PageScaffold(
      eyebrow: 'PHASE · 13A',
      title: 'Locale gallery',
      subtitle: '5 GlobeID-supported locales · brand chrome stays foil',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: [
          _LivePreview(locale: _previewLocale, strings: strings),
          const SizedBox(height: Os2.space6),
          Os2Text.monoCap('LOCALE · LADDER', color: Colors.white.withValues(alpha: 0.48), size: Os2.textTiny),
          const SizedBox(height: Os2.space3),
          for (final l in GlobeIdLocale.values) ...[
            _LocaleTile(
              locale: l,
              active: l == _previewLocale,
              onTap: () => setState(() => _previewLocale = l),
            ),
            const SizedBox(height: Os2.space2),
          ],
          const SizedBox(height: Os2.space4),
          _StringsCard(strings: strings, locale: _previewLocale),
          const SizedBox(height: Os2.space4),
          _BrandConstantsCard(),
        ],
      ),
    );
  }
}

class _LivePreview extends StatelessWidget {
  const _LivePreview({required this.locale, required this.strings});
  final GlobeIdLocale locale;
  final GlobeIdStrings strings;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: locale.textDirection,
      child: Container(
        padding: const EdgeInsets.all(Os2.space5),
        decoration: BoxDecoration(
          color: Os2.floor1,
          borderRadius: BorderRadius.circular(Os2.rCard),
          border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.42),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
              blurRadius: 22,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top brand bar — watermark stays LTR Latin regardless
            // of locale direction (Directionality only flips the
            // surrounding layout, not the watermark text).
            Row(
              children: [
                Os2Text.monoCap(
                  'GLOBE · ID',
                  color: const Color(0xFFD4AF37),
                  size: Os2.textTiny,
                ),
                const Spacer(),
                Os2Text.monoCap(
                  locale.monoCapName,
                  color: Colors.white.withValues(alpha: 0.42),
                  size: Os2.textTiny,
                ),
              ],
            ),
            const SizedBox(height: Os2.space3),
            Text(
              strings.appName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              strings.brandTagline,
              style: TextStyle(
                color: const Color(0xFFE9C75D).withValues(alpha: 0.86),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: Os2.space4),
            _CtaRow(label: strings.continueAction, tone: const Color(0xFFD4AF37)),
            const SizedBox(height: 6),
            _CtaRow(label: strings.scanAction, tone: const Color(0xFFE9C75D)),
            const SizedBox(height: 6),
            _CtaRow(label: strings.payAction, tone: const Color(0xFFC9A961)),
            const SizedBox(height: 6),
            _CtaRow(label: strings.shareAction, tone: const Color(0xFF3FB68B)),
            const SizedBox(height: Os2.space4),
            Container(
              width: 80,
              height: 0.6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFFD4AF37).withValues(alpha: 0.46),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              strings.signedByGlobeId,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.46),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CtaRow extends StatelessWidget {
  const _CtaRow({required this.label, required this.tone});
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.46), width: 0.6),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: tone,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: tone.withValues(alpha: 0.62),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: tone,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocaleTile extends StatelessWidget {
  const _LocaleTile({
    required this.locale,
    required this.active,
    required this.onTap,
  });
  final GlobeIdLocale locale;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = active ? const Color(0xFFD4AF37) : Colors.white.withValues(alpha: 0.42);
    return Pressable(
      semanticLabel: locale.nativeName,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: active ? Os2.floor1 : Colors.transparent,
          borderRadius: BorderRadius.circular(Os2.rChip),
          border: Border.all(color: tone.withValues(alpha: active ? 0.62 : 0.22)),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: tone.withValues(alpha: 0.12),
                    blurRadius: 14,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.16),
                shape: BoxShape.circle,
                border: Border.all(color: tone.withValues(alpha: 0.62)),
              ),
              alignment: Alignment.center,
              child: Text(
                locale.languageCode.toUpperCase(),
                style: TextStyle(
                  color: tone,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locale.nativeName,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: active ? 0.92 : 0.68),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Os2Text.monoCap(
                    locale.tag.toUpperCase(),
                    color: tone,
                    size: Os2.textTiny,
                  ),
                ],
              ),
            ),
            Os2Text.monoCap(
              locale.textDirection == TextDirection.rtl ? 'RTL' : 'LTR',
              color: tone.withValues(alpha: 0.78),
              size: Os2.textTiny,
            ),
          ],
        ),
      ),
    );
  }
}

class _StringsCard extends StatelessWidget {
  const _StringsCard({required this.strings, required this.locale});
  final GlobeIdStrings strings;
  final GlobeIdLocale locale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Os2Text.monoCap(
            '${locale.languageCode.toUpperCase()} · STRINGS',
            color: const Color(0xFFD4AF37),
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space3),
          _Pair(label: 'TAGLINE', value: strings.brandTagline),
          _Pair(label: 'CONTINUE', value: strings.continueAction),
          _Pair(label: 'SCAN', value: strings.scanAction),
          _Pair(label: 'PAY', value: strings.payAction),
          _Pair(label: 'SHARE', value: strings.shareAction),
          _Pair(label: 'VERIFIED', value: strings.verifiedLabel),
          _Pair(label: 'ISSUED', value: strings.issuedLabel),
          _Pair(label: 'CLEARED', value: strings.clearedLabel),
          _Pair(label: 'SIGNATURE', value: strings.signedByGlobeId),
        ],
      ),
    );
  }
}

class _Pair extends StatelessWidget {
  const _Pair({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Os2Text.monoCap(
              label,
              color: Colors.white.withValues(alpha: 0.42),
              size: Os2.textTiny,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
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

class _BrandConstantsCard extends StatelessWidget {
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
            'BRAND · CONSTANTS',
            color: const Color(0xFFD4AF37),
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space3),
          _Pair(label: 'WATERMARK', value: 'GLOBE · ID (LTR · LATIN)'),
          _Pair(label: 'FOIL', value: '#D4AF37 → #E9C75D'),
          _Pair(label: 'SUBSTRATE', value: '#050505 / #050912'),
          _Pair(label: 'HAIRLINE', value: '0.6 px · 46% foil'),
          _Pair(label: 'MONO · CAP', value: 'Departure Mono · w800 · +1.6 tracking'),
        ],
      ),
    );
  }
}
