import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/data/fx/demo_fx_adapter.dart';
import 'package:globeid/data/fx/fx_adapter.dart';
import 'package:globeid/data/fx/fx_models.dart';
import 'package:globeid/data/fx/fx_service.dart';

class _ExplodingAdapter extends FxAdapter {
  @override
  String get source => 'exploding';
  @override
  Future<FxQuote> quote(FxPair pair) async {
    throw StateError('boom');
  }
}

void main() {
  group('DemoFxAdapter', () {
    test('returns a quote per known pair', () async {
      final adapter = DemoFxAdapter();
      final eur = await adapter.quote(const FxPair('USD', 'EUR'));
      expect(eur.pair.handle, 'USD/EUR');
      expect(eur.rate, greaterThan(0.85));
      expect(eur.rate, lessThan(1.0));
      expect(eur.source, 'demo');
    });

    test('keeps successive rates inside a ±2% envelope', () async {
      final adapter = DemoFxAdapter();
      const pair = FxPair('USD', 'EUR');
      final base = (await adapter.quote(pair)).rate;
      for (var i = 0; i < 30; i++) {
        final q = await adapter.quote(pair);
        expect(q.rate, greaterThanOrEqualTo(base * 0.97));
        expect(q.rate, lessThanOrEqualTo(base * 1.03));
      }
    });

    test('returns a snapshot containing every requested pair', () async {
      final adapter = DemoFxAdapter();
      final snap = await adapter.snapshot(const [
        FxPair('USD', 'EUR'),
        FxPair('USD', 'JPY'),
        FxPair('USD', 'GBP'),
      ]);
      expect(snap.quotes.length, 3);
      expect(snap.source, 'demo');
    });

    test('inverts pairs via USD when quote is USD', () async {
      final adapter = DemoFxAdapter();
      final q = await adapter.quote(const FxPair('EUR', 'USD'));
      expect(q.rate, greaterThan(1.0)); // 1 EUR > 1 USD inverse of 0.917
    });
  });

  group('FxQuote.isStale', () {
    test('returns true once the quote ages past the threshold', () {
      final past = DateTime.now().subtract(const Duration(minutes: 10));
      final q = FxQuote(
        pair: const FxPair('USD', 'EUR'),
        rate: 0.92,
        delta: 0,
        fetchedAt: past,
        source: 'demo',
      );
      expect(q.isStale(threshold: const Duration(minutes: 5)), isTrue);
    });

    test('returns false for fresh quotes', () {
      final q = FxQuote(
        pair: const FxPair('USD', 'EUR'),
        rate: 0.92,
        delta: 0,
        fetchedAt: DateTime.now(),
        source: 'demo',
      );
      expect(q.isStale(), isFalse);
    });
  });

  group('FxService', () {
    test('emits the snapshot through stream on track', () async {
      final service = FxService(
        adapter: DemoFxAdapter(),
        refreshInterval: const Duration(hours: 1),
      );
      addTearDown(service.dispose);
      final first = service.stream.first;
      final snap = await service.track([const FxPair('USD', 'EUR')]);
      final emitted = await first;
      expect(snap.quotes.length, 1);
      expect(emitted.quotes.length, 1);
    });

    test('falls back to demo when primary throws', () async {
      final service = FxService(
        adapter: _ExplodingAdapter(),
        fallback: DemoFxAdapter(),
        refreshInterval: const Duration(hours: 1),
      );
      addTearDown(service.dispose);
      final snap = await service.track([const FxPair('USD', 'EUR')]);
      expect(snap.source, 'demo+fallback');
      expect(snap.quotes.length, 1);
    });

    test('refresh without track throws', () async {
      final service = FxService(
        adapter: DemoFxAdapter(),
        refreshInterval: const Duration(hours: 1),
      );
      addTearDown(service.dispose);
      expect(() => service.refresh(), throwsStateError);
    });

    test('rethrows when both adapters fail', () async {
      final service = FxService(
        adapter: _ExplodingAdapter(),
        refreshInterval: const Duration(hours: 1),
      );
      addTearDown(service.dispose);
      await expectLater(
        service.track([const FxPair('USD', 'EUR')]),
        throwsA(isA<StateError>()),
      );
    });
  });
}
