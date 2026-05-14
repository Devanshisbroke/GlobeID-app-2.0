import 'package:flutter/material.dart';

import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';
import '../models/visual_regression_catalog.dart';

/// Phase 14d — Visual regression specimen lab.
///
/// Operator-facing surface that paints every catalog specimen at
/// its canonical size on top of a neutral substrate. Eyeballing
/// drift is intentional — the structural invariants are caught by
/// `test/visual_regression_test.dart`; this surface is for the
/// human reviewer to verify rendering against design intent.
class VisualRegressionScreen extends StatelessWidget {
  const VisualRegressionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = VisualRegressionCatalog.groups();
    return PageScaffold(
      eyebrow: 'ATELIER · 14D',
      title: 'Visual Regression',
      subtitle:
          '${VisualRegressionCatalog.specimens.length} specimens · '
          '${groups.length} groups · canonical sizing',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: [
          const _RegressionIntro(),
          const SizedBox(height: Os2.space5),
          for (final group in groups) ...[
            _GroupHeader(label: group),
            const SizedBox(height: Os2.space2),
            for (final s in VisualRegressionCatalog.specimens
                .where((sp) => sp.group == group)) ...[
              _SpecimenCard(specimen: s),
              const SizedBox(height: Os2.space2),
            ],
            const SizedBox(height: Os2.space4),
          ],
        ],
      ),
    );
  }
}

class _RegressionIntro extends StatelessWidget {
  const _RegressionIntro();

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
                'REGRESSION · LAB',
                color: const Color(0xFFD4AF37),
                size: Os2.textTiny,
              ),
              const Spacer(),
              Os2Text.monoCap(
                'N° 14D.00',
                color: Colors.white.withValues(alpha: 0.42),
                size: Os2.textTiny,
              ),
            ],
          ),
          const SizedBox(height: Os2.space2),
          const Text(
            'Canonical specimens for visual drift detection',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: Os2.space2),
          Text(
            'Each primitive is rendered at the size locked-in by the '
            'brand. The operator reviews this surface visually; the '
            'structural invariants (paint occurs, layout matches '
            'canonical size, tone is in family) are enforced by '
            'visual_regression_test.dart.',
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

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 10),
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

class _SpecimenCard extends StatelessWidget {
  const _SpecimenCard({required this.specimen});
  final VisualSpecimen specimen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(
          color: specimen.tone.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  specimen.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: specimen.tone.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: specimen.tone.withValues(alpha: 0.62),
                    width: 0.6,
                  ),
                ),
                child: Text(
                  '${specimen.canonicalSize.width.toInt()}×'
                  '${specimen.canonicalSize.height.toInt()}',
                  style: TextStyle(
                    color: specimen.tone,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Os2.space2),
          Text(
            specimen.summary,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: Os2.space3),
          // Specimen sit on a neutral checkerboard to catch
          // transparent-pixel drift.
          Container(
            padding: const EdgeInsets.all(Os2.space2),
            decoration: BoxDecoration(
              color: const Color(0xFF111114),
              borderRadius: BorderRadius.circular(Os2.rTile),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Center(
              child: SizedBox(
                width: specimen.canonicalSize.width,
                height: specimen.canonicalSize.height,
                child: Builder(
                  builder: (ctx) => specimen.builder(ctx),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
