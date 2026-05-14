import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/atelier/models/atelier_catalog.dart';

void main() {
  group('AtelierCatalog', () {
    test('catalog enumerates every primitive across 4 domains', () {
      expect(AtelierCatalog.all, hasLength(19));
      final domains =
          AtelierCatalog.all.map((c) => c.domain).toSet();
      expect(domains, hasLength(4));
      expect(domains, containsAll(AtelierDomain.values));
    });

    test('every component has a stable id, name, summary, and tokens', () {
      for (final c in AtelierCatalog.all) {
        expect(c.id, isNotEmpty);
        expect(c.name, isNotEmpty);
        expect(c.summary, isNotEmpty);
        expect(c.role, isNotEmpty);
        expect(c.tokenSummary, isNotEmpty);
      }
    });

    test('ids are unique', () {
      final ids = AtelierCatalog.all.map((c) => c.id).toSet();
      expect(ids, hasLength(AtelierCatalog.all.length));
    });

    test('byId resolves a known component and returns null on miss', () {
      expect(AtelierCatalog.byId('breathing-halo'), isNotNull);
      expect(AtelierCatalog.byId('breathing-halo')!.name, 'BreathingHalo');
      expect(AtelierCatalog.byId('does-not-exist'), isNull);
    });

    test('grouped() preserves domain authoring order and length sum', () {
      final grouped = AtelierCatalog.grouped();
      expect(grouped.keys, AtelierDomain.values);
      final total =
          grouped.values.fold<int>(0, (sum, list) => sum + list.length);
      expect(total, AtelierCatalog.all.length);
    });

    test('every AtelierDomain exposes a label, subtitle, and tone', () {
      for (final d in AtelierDomain.values) {
        expect(d.label, isNotEmpty);
        expect(d.subtitle, isNotEmpty);
        // ignore: deprecated_member_use
        expect(d.tone.alpha, 255); // opaque tone
      }
    });

    test('typography domain enumerates all 6 Os2Text variants', () {
      final typo = AtelierCatalog.all
          .where((c) => c.domain == AtelierDomain.typography)
          .toList();
      expect(typo, hasLength(6));
      final names = typo.map((c) => c.name).toSet();
      expect(names, containsAll(<String>[
        'Os2Text.display',
        'Os2Text.headline',
        'Os2Text.body',
        'Os2Text.monoCap',
        'Os2Text.credential',
        'Os2Text.watermark',
      ]));
    });

    test('live primitives domain enumerates the 7 alive widgets', () {
      final live = AtelierCatalog.all
          .where((c) => c.domain == AtelierDomain.live)
          .toList();
      expect(live, hasLength(7));
      final names = live.map((c) => c.name).toSet();
      expect(names, containsAll(<String>[
        'BreathingHalo',
        'HolographicFoil',
        'NfcPulse',
        'LiveStatusPill',
        'LiveDataPulse',
        'RollingDigits',
        'GlobeIdSignature',
      ]));
    });
  });
}
