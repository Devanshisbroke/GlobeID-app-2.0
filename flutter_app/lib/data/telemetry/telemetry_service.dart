import 'dart:async';

import 'telemetry_event.dart';
import 'telemetry_sink.dart';

/// `TelemetryService` — fan-out hub for [TelemetrySink]s.
///
/// One emit() per surface, the service forwards to every enabled
/// sink. Sink failures never propagate; the service guarantees a
/// best-effort delivery to every other sink.
///
/// Two convenience helpers wrap the raw [emit]:
///   • `info(kind, message)` — TelemetryLevel.info
///   • `error(kind, message, stack)` — TelemetryLevel.error
class TelemetryService {
  TelemetryService({List<TelemetrySink> sinks = const []})
      : _sinks = List.of(sinks);

  final List<TelemetrySink> _sinks;

  List<TelemetrySink> get sinks => List.unmodifiable(_sinks);

  void add(TelemetrySink sink) => _sinks.add(sink);

  void remove(TelemetrySink sink) => _sinks.remove(sink);

  Future<void> emit(TelemetryEvent event) async {
    final futures = <Future<void>>[];
    for (final sink in _sinks) {
      if (!sink.enabled) continue;
      futures.add(_safeSubmit(sink, event));
    }
    await Future.wait(futures);
  }

  Future<void> _safeSubmit(TelemetrySink sink, TelemetryEvent event) async {
    try {
      await sink.submit(event);
    } catch (_) {
      // swallow — sink failure never cascades
    }
  }

  Future<void> info(
    String kind,
    String message, {
    Map<String, Object?> attributes = const {},
    String? fingerprint,
  }) =>
      emit(TelemetryEvent(
        kind: kind,
        message: message,
        level: TelemetryLevel.info,
        timestamp: DateTime.now(),
        attributes: attributes,
        fingerprint: fingerprint,
      ));

  Future<void> warning(
    String kind,
    String message, {
    Map<String, Object?> attributes = const {},
    String? fingerprint,
  }) =>
      emit(TelemetryEvent(
        kind: kind,
        message: message,
        level: TelemetryLevel.warning,
        timestamp: DateTime.now(),
        attributes: attributes,
        fingerprint: fingerprint,
      ));

  Future<void> error(
    String kind,
    String message, {
    String stack = '',
    Map<String, Object?> attributes = const {},
    String? fingerprint,
    String library = 'app',
  }) =>
      emit(TelemetryEvent(
        kind: kind,
        message: message,
        level: TelemetryLevel.error,
        timestamp: DateTime.now(),
        stack: stack,
        library: library,
        attributes: attributes,
        fingerprint: fingerprint,
      ));

  Future<void> flush() async {
    await Future.wait([
      for (final sink in _sinks) sink.flush().catchError((Object _) {}),
    ]);
  }

  Future<void> close() async {
    await Future.wait([
      for (final sink in _sinks) sink.close().catchError((Object _) {}),
    ]);
  }
}
