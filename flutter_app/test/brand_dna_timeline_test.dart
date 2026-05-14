import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/atelier/models/brand_dna_timeline.dart';

void main() {
  group('BrandDnaTimeline', () {
    test('enumerates 14 shipped chapters (Phase 01 → 14)', () {
      expect(BrandDnaTimeline.chapters, hasLength(14));
    });

    test('phase labels are unique and in author order', () {
      final labels = BrandDnaTimeline.chapters
          .map((c) => c.phaseLabel)
          .toList();
      expect(labels.toSet().length, labels.length,
          reason: 'phase labels must be unique');
      // Phase 01 first, Phase 14 last.
      expect(labels.first, 'PHASE · 01');
      expect(labels.last, 'PHASE · 14');
    });

    test('chapter ids are unique and follow phase-NN slug pattern', () {
      final ids = BrandDnaTimeline.chapters.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final id in ids) {
        expect(
          RegExp(r'^phase-\d{2}$').hasMatch(id),
          isTrue,
          reason: 'id "$id" should match phase-NN',
        );
      }
    });

    test('every chapter has non-empty title, headline, summary, invariant',
        () {
      for (final c in BrandDnaTimeline.chapters) {
        expect(c.title, isNotEmpty);
        expect(c.headline, isNotEmpty);
        expect(c.summary, isNotEmpty);
        expect(c.brandInvariant, isNotEmpty);
      }
    });

    test('every chapter tone is fully opaque (alpha == 0xff)', () {
      for (final c in BrandDnaTimeline.chapters) {
        // The Color.toARGB32 modern API is available; fall back to
        // .value via .alpha shorthand which is non-deprecated.
        expect(c.tone.a, 1.0);
      }
    });

    test('byId resolves a known chapter and returns null on miss', () {
      expect(BrandDnaTimeline.byId('phase-01'), isNotNull);
      expect(BrandDnaTimeline.byId('phase-14'), isNotNull);
      expect(BrandDnaTimeline.byId('does-not-exist'), isNull);
    });

    test('headlines are concise (≤120 chars) — fit on one card', () {
      for (final c in BrandDnaTimeline.chapters) {
        expect(
          c.headline.length,
          lessThanOrEqualTo(120),
          reason: '${c.phaseLabel} headline too long: "${c.headline}"',
        );
      }
    });
  });
}
