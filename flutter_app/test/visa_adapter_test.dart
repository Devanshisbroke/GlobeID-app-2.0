import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/data/visa/demo_visa_adapter.dart';
import 'package:globeid/data/visa/passport_index_visa_adapter.dart';
import 'package:globeid/data/visa/visa_adapter.dart';
import 'package:globeid/data/visa/visa_models.dart';
import 'package:globeid/data/visa/visa_service.dart';

class _ExplodingVisaAdapter extends VisaAdapter {
  @override
  String get source => 'exploding';
  @override
  Future<VisaRule> rule(VisaCorridor corridor) async {
    throw StateError('boom');
  }

  @override
  Future<List<VisaRule>> rulesFor(String passport) async {
    throw StateError('boom');
  }
}

void main() {
  group('DemoVisaAdapter', () {
    test('returns a curated rule for IN→AE', () async {
      final adapter = DemoVisaAdapter();
      final r = await adapter
          .rule(const VisaCorridor(passport: 'IN', destination: 'AE'));
      expect(r.category, VisaCategory.visaOnArrival);
      expect(r.maxStayDays, 14);
      expect(r.source, 'demo');
    });

    test('falls back to visaRequired for unknown corridor', () async {
      final adapter = DemoVisaAdapter();
      final r = await adapter
          .rule(const VisaCorridor(passport: 'IN', destination: 'ZW'));
      expect(r.category, VisaCategory.visaRequired);
      expect(r.maxStayDays, 30);
    });

    test('rulesFor returns every curated row for a passport', () async {
      final adapter = DemoVisaAdapter();
      final rules = await adapter.rulesFor('IN');
      expect(rules.length, greaterThan(3));
      expect(rules.every((r) => r.corridor.passport == 'IN'), isTrue);
    });

    test('HOME category for same-country corridor', () async {
      final adapter = DemoVisaAdapter();
      final r = await adapter
          .rule(const VisaCorridor(passport: 'IN', destination: 'IN'));
      expect(r.category, VisaCategory.home);
    });
  });

  group('PassportIndexVisaAdapter.parseMatrix', () {
    test('parses a tiny matrix correctly', () {
      const csv = 'Passport,US,DE,IN\n'
          'US,-1,visa free,visa on arrival\n'
          'DE,90,-1,e-visa\n'
          'IN,visa required,visa required,-1\n';
      final matrix = PassportIndexVisaAdapter.parseMatrix(csv);
      expect(matrix['US']?['DE'], 'visa free');
      expect(matrix['DE']?['US'], '90');
      expect(matrix['IN']?['DE'], 'visa required');
    });

    test('mapCell maps every PassportIndex cell type', () {
      final adapter = PassportIndexVisaAdapter();
      const corridor = VisaCorridor(passport: 'US', destination: 'DE');
      expect(adapter.mapCell(corridor, 'visa free').category,
          VisaCategory.visaFree);
      expect(adapter.mapCell(corridor, 'visa on arrival').category,
          VisaCategory.visaOnArrival);
      expect(adapter.mapCell(corridor, 'e-visa').category,
          VisaCategory.eVisa);
      expect(adapter.mapCell(corridor, 'eta').category, VisaCategory.eta);
      expect(adapter.mapCell(corridor, 'no admission').category,
          VisaCategory.notAdmitted);
      expect(adapter.mapCell(corridor, '-1').category, VisaCategory.home);
      final days = adapter.mapCell(corridor, '90');
      expect(days.category, VisaCategory.visaFree);
      expect(days.maxStayDays, 90);
      expect(adapter.mapCell(corridor, 'visa required').category,
          VisaCategory.visaRequired);
    });
  });

  group('VisaService', () {
    test('caches the latest rule per corridor', () async {
      final svc = VisaService(adapter: DemoVisaAdapter());
      const corridor = VisaCorridor(passport: 'IN', destination: 'AE');
      expect(svc.cached(corridor), isNull);
      final r = await svc.resolve(corridor);
      expect(svc.cached(corridor)?.category, r.category);
    });

    test('falls back when primary throws', () async {
      final svc = VisaService(
        adapter: _ExplodingVisaAdapter(),
        fallback: DemoVisaAdapter(),
      );
      final r = await svc
          .resolve(const VisaCorridor(passport: 'IN', destination: 'AE'));
      expect(r.source, 'demo+fallback');
    });

    test('rulesFor falls back when primary throws', () async {
      final svc = VisaService(
        adapter: _ExplodingVisaAdapter(),
        fallback: DemoVisaAdapter(),
      );
      final rules = await svc.rulesFor('IN');
      expect(rules.length, greaterThan(3));
      expect(rules.every((r) => r.source == 'demo+fallback'), isTrue);
    });

    test('rethrows when both fail', () async {
      final svc = VisaService(adapter: _ExplodingVisaAdapter());
      await expectLater(
        svc.resolve(const VisaCorridor(passport: 'IN', destination: 'AE')),
        throwsA(isA<StateError>()),
      );
    });

    test('isStale flips after the threshold', () async {
      var t = DateTime(2025, 1, 1);
      final svc = VisaService(
        adapter: DemoVisaAdapter(now: () => t),
        staleThreshold: const Duration(days: 1),
        now: () => t,
      );
      const corridor = VisaCorridor(passport: 'IN', destination: 'AE');
      await svc.resolve(corridor);
      expect(svc.isStale(corridor), isFalse);
      t = t.add(const Duration(days: 2));
      expect(svc.isStale(corridor), isTrue);
    });
  });

  group('VisaCategory', () {
    test('handle strings are non-empty', () {
      for (final c in VisaCategory.values) {
        expect(c.handle, isNotEmpty);
      }
    });

    test('requiresAction is true for eVisa/eta/visaRequired', () {
      expect(VisaCategory.eVisa.requiresAction, isTrue);
      expect(VisaCategory.eta.requiresAction, isTrue);
      expect(VisaCategory.visaRequired.requiresAction, isTrue);
      expect(VisaCategory.visaFree.requiresAction, isFalse);
      expect(VisaCategory.home.requiresAction, isFalse);
    });
  });
}
