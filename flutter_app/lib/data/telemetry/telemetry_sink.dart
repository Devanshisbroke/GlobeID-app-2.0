import 'telemetry_event.dart';

/// Contract every telemetry destination satisfies.
///
/// Sinks must be cheap to construct, idempotent on `flush`, and
/// non-throwing on `submit` — the service guarantees a best-effort
/// delivery and never lets a sink failure cascade to other sinks.
abstract class TelemetrySink {
  String get name;
  bool get enabled;

  Future<void> submit(TelemetryEvent event);

  /// Flush any buffered events. Default no-op for sinks that send
  /// per-event.
  Future<void> flush() async {}

  /// Release resources. Default no-op.
  Future<void> close() async {}
}

class TelemetrySinkException implements Exception {
  TelemetrySinkException(this.message);
  final String message;
  @override
  String toString() => 'TelemetrySinkException: $message';
}
