import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../i18n/brand_contrast.dart';
import '../../i18n/brand_direction.dart';
import '../../i18n/brand_motion_policy.dart';
import '../../i18n/brand_text_scale.dart';
import '../../i18n/globe_id_locale.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/pressable.dart';

/// Phase 13f — Localization + Accessibility capstone hub.
///
/// Consolidates 13a-13e (i18n scaffold · RTL · Dynamic Type ·
/// Reduced Motion · WCAG) into one lab where the operator
/// inspects the brand's status across every dimension. Each
/// module has a live status chip — pulled from the actual
/// MediaQuery + Locale state — and a CTA into the dedicated lab.
class LocaleA11yHubScreen extends StatelessWidget {
  const LocaleA11yHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activeLocale = GlobeIdLocaleScope.localeOf(context);
    final isRtl = BrandDirection.isRtl(context);
    final scaler = MediaQuery.textScalerOf(context);
    final scale10 = scaler.scale(10) / 10.0;
    final reducedMotion = BrandMotionPolicy.isReduced(context);
    final foilOnOled = BrandContrast.ratio(
      const Color(0xFFD4AF37),
      const Color(0xFF050505),
    );
    final band = BrandContrast.bandFor(foilOnOled);

    final modules = <_HubModule>[
      _HubModule(
        eyebrow: 'PHASE · 13A',
        title: 'Locale scaffold',
        subtitle: '5 canonical locales · RTL aware · LTR brand chrome',
        statusLabel: activeLocale.monoCapName,
        statusTone: const Color(0xFFD4AF37),
        route: '/lab/locale-gallery',
        icon: Icons.translate_rounded,
      ),
      _HubModule(
        eyebrow: 'PHASE · 13B',
        title: 'RTL audit',
        subtitle: 'BrandLtr · MirrorAware · brandAligned primitives',
        statusLabel: isRtl ? 'RTL · MIRROR' : 'LTR · NATIVE',
        statusTone: isRtl ? const Color(0xFFC9A961) : const Color(0xFFE9C75D),
        route: '/lab/rtl-audit',
        icon: Icons.format_textdirection_r_to_l_rounded,
      ),
      _HubModule(
        eyebrow: 'PHASE · 13C',
        title: 'Dynamic Type audit',
        subtitle: 'Body unrestricted · chrome ≤ 1.35× · credential ≤ 1.20×',
        statusLabel: '${(scale10 * 100).round()}% · ${_textScaleLabel(scale10)}',
        statusTone: scale10 > BrandTextScale.chromeCap
            ? const Color(0xFF6B8FB8)
            : const Color(0xFFE9C75D),
        route: '/lab/dynamic-type',
        icon: Icons.format_size_rounded,
      ),
      _HubModule(
        eyebrow: 'PHASE · 13D',
        title: 'Reduced motion audit',
        subtitle: 'Structural · ambient · signature each adapt differently',
        statusLabel: reducedMotion ? 'REDUCED · ON' : 'MOTION · FULL',
        statusTone: reducedMotion
            ? const Color(0xFF6B8FB8)
            : const Color(0xFFE9C75D),
        route: '/lab/reduced-motion',
        icon: Icons.motion_photos_paused_rounded,
      ),
      _HubModule(
        eyebrow: 'PHASE · 13E',
        title: 'WCAG contrast audit',
        subtitle: 'Foil + chrome + accents vs OLED · objective ratios',
        statusLabel: 'FOIL · ${foilOnOled.toStringAsFixed(1)}:1 · ${band.label}',
        statusTone: band == ContrastBand.aaaNormal
            ? const Color(0xFFE9C75D)
            : (band == ContrastBand.fail
                ? const Color(0xFFEF6464)
                : const Color(0xFF6B8FB8)),
        route: '/lab/wcag',
        icon: Icons.contrast_rounded,
      ),
    ];

    return PageScaffold(
      eyebrow: 'PHASE · 13F',
      title: 'Locale + Accessibility',
      subtitle: 'Capstone · 5 modules · live brand status',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: [
          const _LiveStateCard(),
          const SizedBox(height: Os2.space4),
          for (final module in modules) ...[
            _ModuleCard(module: module),
            const SizedBox(height: Os2.space3),
          ],
          const SizedBox(height: Os2.space3),
          const _InvariantsCard(),
        ],
      ),
    );
  }
}

class _HubModule {
  const _HubModule({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusTone,
    required this.route,
    required this.icon,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String statusLabel;
  final Color statusTone;
  final String route;
  final IconData icon;
}

String _textScaleLabel(double scale) {
  if (scale <= 1.05) return 'DEFAULT';
  if (scale <= 1.35) return 'CHROME CAP';
  if (scale <= 1.55) return 'LARGE';
  return 'XL';
}

class _LiveStateCard extends StatelessWidget {
  const _LiveStateCard();

  @override
  Widget build(BuildContext context) {
    final locale = GlobeIdLocaleScope.localeOf(context);
    final isRtl = BrandDirection.isRtl(context);
    final reducedMotion = BrandMotionPolicy.isReduced(context);
    final foilOnOled = BrandContrast.ratio(
      const Color(0xFFD4AF37),
      const Color(0xFF050505),
    );
    return BrandLtr(
      child: Container(
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
                  'GLOBE · ID · LIVE',
                  color: const Color(0xFFD4AF37),
                  size: Os2.textTiny,
                ),
                const Spacer(),
                Os2Text.monoCap(
                  'N° 13F.00',
                  color: Colors.white.withValues(alpha: 0.42),
                  size: Os2.textTiny,
                ),
              ],
            ),
            const SizedBox(height: Os2.space2),
            const Text(
              'Brand status · current session',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: Os2.space3),
            _LiveRow(label: 'LOCALE', value: locale.monoCapName),
            _LiveRow(
              label: 'DIRECTION',
              value: isRtl ? 'RTL · ${locale.languageCode.toUpperCase()}' : 'LTR · ${locale.languageCode.toUpperCase()}',
            ),
            _LiveRow(
              label: 'MOTION',
              value: reducedMotion ? 'REDUCED' : 'FULL',
              tone: reducedMotion
                  ? const Color(0xFF6B8FB8)
                  : const Color(0xFFE9C75D),
            ),
            _LiveRow(
              label: 'FOIL · OLED',
              value: '${foilOnOled.toStringAsFixed(1)}:1 · ${BrandContrast.bandFor(foilOnOled).label}',
              tone: const Color(0xFFE9C75D),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveRow extends StatelessWidget {
  const _LiveRow({required this.label, required this.value, this.tone});
  final String label;
  final String value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Os2Text.monoCap(
              label,
              color: Colors.white.withValues(alpha: 0.42),
              size: Os2.textTiny,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: tone ?? Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module});
  final _HubModule module;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: '${module.title} lab',
      semanticHint: 'opens the ${module.title.toLowerCase()} audit screen',
      onTap: () => context.push(module.route),
      child: Container(
        padding: const EdgeInsets.all(Os2.space4),
        decoration: BoxDecoration(
          color: Os2.floor1,
          borderRadius: BorderRadius.circular(Os2.rCard),
          border: Border.all(
            color: module.statusTone.withValues(alpha: 0.46),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: module.statusTone.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: module.statusTone.withValues(alpha: 0.62),
                ),
              ),
              child: Icon(
                module.icon,
                size: 22,
                color: module.statusTone,
              ),
            ),
            const SizedBox(width: Os2.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Os2Text.monoCap(
                    module.eyebrow,
                    color: module.statusTone,
                    size: Os2.textTiny,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    module.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    module.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: module.statusTone.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: module.statusTone.withValues(alpha: 0.62),
                        width: 0.6,
                      ),
                    ),
                    child: Text(
                      module.statusLabel,
                      style: TextStyle(
                        color: module.statusTone,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            MirrorAware(
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.white.withValues(alpha: 0.42),
              ),
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
            'CAPSTONE · INVARIANTS',
            color: const Color(0xFFD4AF37),
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space3),
          for (final inv in _invariants) _InvariantRow(text: inv),
        ],
      ),
    );
  }
}

const _invariants = <String>[
  'GLOBE · ID watermark stays Latin LTR in every locale (BrandLtr)',
  'Case N° stays Latin LTR + monospace · locale-immutable',
  'Mono-cap eyebrow vocabulary is locale-invariant (English)',
  'Chrome text caps at 1.35× under Dynamic Type — never deforms',
  'Ambient ornaments do not render under reduced motion',
  'Signature ceremonies run at 50% duration under reduced motion',
  'Haptic signatures always fire — never categorized as motion',
  'Foil gold + body white pairs meet AA Normal on OLED',
  'Hairlines composited on OLED clear AA Normal (~4.7:1)',
  'Semantic accent reds intentionally reserved for non-text roles',
];

class _InvariantRow extends StatelessWidget {
  const _InvariantRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 8),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.62),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
