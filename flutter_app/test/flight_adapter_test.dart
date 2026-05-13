import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/data/flight/aeroapi_flight_adapter.dart';
import 'package:globeid/data/flight/demo_flight_adapter.dart';
import 'package:globeid/data/flight/flight_adapter.dart';
import 'package:globeid/data/flight/flight_models.dart';
import 'package:globeid/data/flight/flight_service.dart';

class _ExplodingAdapter extends FlightAdapter {
  @override
  String get source => 'exploding';
  @override
  Future<FlightQuote> quote(FlightHandle handle) async {
    throw StateError('boom');
  }
}

void main() {
  group('DemoFlightAdapter', () {
    test('returns a SCHEDULED quote at the start of a cycle', () async {
      final now = DateTime(2025, 1, 1, 10);
      final adapter = DemoFlightAdapter(now: () => now);
      final q = await adapter.quote(const FlightHandle('LH', '401'));
      expect(q.phase, FlightPhase.scheduled);
      expect(q.origin, 'MUC');
      expect(q.destination, 'JFK');
      expect(q.gate, 'B27');
      expect(q.source, 'demo');
    });

    test('walks through phases as wall-clock advances', () async {
      const handle = FlightHandle('LH', '401');
      final start = DateTime(2025, 1, 1, 10);
      final boardingAdapter = DemoFlightAdapter(
        now: () => start.add(const Duration(minutes: 5)),
      );
      final airborneAdapter = DemoFlightAdapter(
        now: () => start.add(const Duration(minutes: 11)),
      );
      final boarding = await boardingAdapter.quote(handle);
      final airborne = await airborneAdapter.quote(handle);
      expect(boarding.phase, FlightPhase.boarding);
      expect(airborne.phase, FlightPhase.inAir);
    });

    test('returns a stub for unknown handles', () async {
      final adapter = DemoFlightAdapter();
      final q = await adapter.quote(const FlightHandle('XX', '0000'));
      expect(q.phase, FlightPhase.scheduled);
      expect(q.origin, '???');
    });
  });

  group('FlightService', () {
    test('caches the latest quote', () async {
      final svc = FlightService(adapter: DemoFlightAdapter());
      addTearDown(svc.dispose);
      const handle = FlightHandle('LH', '401');
      expect(svc.cached(handle), isNull);
      final q = await svc.refresh(handle);
      expect(svc.cached(handle), same(q));
    });

    test('watch stream emits on refresh', () async {
      final svc = FlightService(adapter: DemoFlightAdapter());
      addTearDown(svc.dispose);
      const handle = FlightHandle('LH', '401');
      final next = svc.watch(handle).first;
      await svc.refresh(handle);
      final q = await next;
      expect(q.handle, handle);
    });

    test('falls back when primary throws', () async {
      final svc = FlightService(
        adapter: _ExplodingAdapter(),
        fallback: DemoFlightAdapter(),
      );
      addTearDown(svc.dispose);
      final q = await svc.refresh(const FlightHandle('LH', '401'));
      expect(q.source, 'demo+fallback');
    });

    test('rethrows when both adapters fail', () async {
      final svc = FlightService(adapter: _ExplodingAdapter());
      addTearDown(svc.dispose);
      await expectLater(
        svc.refresh(const FlightHandle('LH', '401')),
        throwsA(isA<StateError>()),
      );
    });

    test('isStale returns true past threshold', () async {
      var t = DateTime(2025, 1, 1, 10);
      final svc = FlightService(
        adapter: DemoFlightAdapter(now: () => t),
        staleThreshold: const Duration(minutes: 1),
        now: () => t,
      );
      addTearDown(svc.dispose);
      const handle = FlightHandle('LH', '401');
      await svc.refresh(handle);
      expect(svc.isStale(handle), isFalse);
      t = t.add(const Duration(minutes: 5));
      expect(svc.isStale(handle), isTrue);
    });
  });

  group('AeroapiFlightAdapter.parse', () {
    test('maps an AeroAPI row into a FlightQuote', () {
      final adapter = AeroapiFlightAdapter(apiKey: 'demo');
      final row = {
        'origin': {'code': 'MUC'},
        'destination': {'code': 'JFK'},
        'scheduled_out': '2025-01-01T10:00:00Z',
        'estimated_out': '2025-01-01T10:12:00Z',
        'gate_origin': 'B27',
        'terminal_origin': 'T2',
        'boarding': true,
      };
      final q = adapter.parse(row, const FlightHandle('LH', '401'));
      expect(q.phase, FlightPhase.boarding);
      expect(q.delayMinutes, 12);
      expect(q.gate, 'B27');
      expect(q.terminal, 'T2');
      expect(q.source, 'aeroapi');
    });

    test('maps cancelled flag to CANCELLED phase', () {
      final adapter = AeroapiFlightAdapter(apiKey: 'demo');
      final row = {
        'origin': {'code': 'MUC'},
        'destination': {'code': 'JFK'},
        'scheduled_out': '2025-01-01T10:00:00Z',
        'cancelled': true,
      };
      final q = adapter.parse(row, const FlightHandle('LH', '401'));
      expect(q.phase, FlightPhase.cancelled);
    });

    test('throws when API key missing', () async {
      final adapter = AeroapiFlightAdapter(apiKey: '');
      await expectLater(
        adapter.quote(const FlightHandle('LH', '401')),
        throwsA(isA<FlightAdapterException>()),
      );
    });
  });
}
