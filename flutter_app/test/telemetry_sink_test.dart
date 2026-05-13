import 'package:flutter_test/flutter_test.dart';

import 'package:globeid/data/telemetry/buffer_telemetry_sink.dart';
import 'package:globeid/data/telemetry/console_telemetry_sink.dart';
import 'package:globeid/data/telemetry/sentry_telemetry_sink.dart';
import 'package:globeid/data/telemetry/telemetry_event.dart';
import 'package:globeid/data/telemetry/telemetry_service.dart';
import 'package:globeid/data/telemetry/telemetry_sink.dart';

TelemetryEvent _ev({TelemetryLevel level = TelemetryLevel.info}) =>
    TelemetryEvent(
      kind: 'test.sample',
      message: 'hello',
      level: level,
      timestamp: DateTime(2025, 1, 1, 10),
      attributes: const {'k': 'v'},
      fingerprint: 'fp1',
    );

class _ExplodingSink extends TelemetrySink {
  @override
  String get name => 'exploding';
  @override
  bool get enabled => true;
  @override
  Future<void> submit(TelemetryEvent event) async {
    throw StateError('boom');
  }
}

class _RecordingSink extends TelemetrySink {
  final List<TelemetryEvent> recorded = [];
  @override
  String get name => 'recorder';
  @override
  bool get enabled => true;
  @override
  Future<void> submit(TelemetryEvent event) async {
    recorded.add(event);
  }
}

void main() {
  group('TelemetryEvent', () {
    test('toJson packs Sentry-compatible payload', () {
      final ev = _ev(level: TelemetryLevel.error);
      final j = ev.toJson();
      expect(j['level'], 'error');
      expect(j['logger'], 'app');
      expect((j['message'] as Map)['message'], 'hello');
      expect((j['tags'] as Map)['kind'], 'test.sample');
      expect((j['tags'] as Map)['k'], 'v');
      expect((j['fingerprint'] as List).first, 'fp1');
    });
  });

  group('BufferTelemetrySink', () {
    test('buffers up to capacity, newest first', () async {
      final sink = BufferTelemetrySink(capacity: 2);
      await sink.submit(_ev());
      await sink.submit(_ev());
      await sink.submit(_ev());
      expect(sink.events.length, 2);
    });

    test('clear empties the buffer', () async {
      final sink = BufferTelemetrySink();
      await sink.submit(_ev());
      sink.clear();
      expect(sink.events, isEmpty);
    });

    test('disabled sink ignores events', () async {
      final sink = BufferTelemetrySink(enabled: false);
      await sink.submit(_ev());
      expect(sink.events, isEmpty);
    });
  });

  group('ConsoleTelemetrySink', () {
    test('respects minLevel', () async {
      final sink = ConsoleTelemetrySink(minLevel: TelemetryLevel.warning);
      // No throw — just validating the level guard runs.
      await sink.submit(_ev(level: TelemetryLevel.debug));
      await sink.submit(_ev(level: TelemetryLevel.fatal));
    });
  });

  group('TelemetryService', () {
    test('fans out to every enabled sink', () async {
      final a = _RecordingSink();
      final b = _RecordingSink();
      final svc = TelemetryService(sinks: [a, b]);
      await svc.emit(_ev());
      expect(a.recorded.length, 1);
      expect(b.recorded.length, 1);
    });

    test('sink failure does not cascade', () async {
      final exploding = _ExplodingSink();
      final ok = _RecordingSink();
      final svc = TelemetryService(sinks: [exploding, ok]);
      await svc.emit(_ev());
      expect(ok.recorded.length, 1);
    });

    test('convenience helpers stamp the right level', () async {
      final rec = _RecordingSink();
      final svc = TelemetryService(sinks: [rec]);
      await svc.info('kind.a', 'hello');
      await svc.warning('kind.b', 'careful');
      await svc.error('kind.c', 'boom', stack: 'frame\nframe2');
      expect(rec.recorded.map((e) => e.level).toList(), [
        TelemetryLevel.info,
        TelemetryLevel.warning,
        TelemetryLevel.error,
      ]);
      expect(rec.recorded.last.stack, contains('frame'));
    });

    test('add/remove updates the roster', () {
      final a = _RecordingSink();
      final b = _RecordingSink();
      final svc = TelemetryService(sinks: [a]);
      expect(svc.sinks.length, 1);
      svc.add(b);
      expect(svc.sinks.length, 2);
      svc.remove(a);
      expect(svc.sinks.length, 1);
      expect(svc.sinks.first, same(b));
    });
  });

  group('SentryTelemetrySink', () {
    test('idle when no DSN provided', () {
      final sink = SentryTelemetrySink(dsn: '');
      expect(sink.enabled, isFalse);
      expect(sink.endpointForTest, isNull);
    });

    test('parses a valid DSN into endpoint + key', () {
      final sink = SentryTelemetrySink(
        dsn: 'https://abcd1234@sentry.example.com/42',
      );
      expect(sink.enabled, isTrue);
      expect(sink.endpointForTest,
          'https://sentry.example.com/api/42/store/');
      expect(sink.publicKeyForTest, 'abcd1234');
    });

    test('rejects garbage DSN', () {
      final sink = SentryTelemetrySink(dsn: 'not-a-dsn');
      expect(sink.enabled, isFalse);
    });
  });
}
