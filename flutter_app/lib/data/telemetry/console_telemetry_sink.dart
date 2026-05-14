import 'package:flutter/foundation.dart';

import 'telemetry_event.dart';
import 'telemetry_sink.dart';

/// Prints every event to the debug console with a mono-cap prefix.
/// Useful in development; cheap, no I/O outside `debugPrint`.
class ConsoleTelemetrySink extends TelemetrySink {
  ConsoleTelemetrySink({this.enabled = true, this.minLevel = TelemetryLevel.debug});

  @override
  final bool enabled;
  final TelemetryLevel minLevel;

  @override
  String get name => 'console';

  @override
  Future<void> submit(TelemetryEvent event) async {
    if (!enabled) return;
    if (event.level.index < minLevel.index) return;
    final ts = event.timestamp.toIso8601String();
    debugPrint(
      '[${event.level.handle.padRight(7)}] $ts · ${event.library} · '
      '${event.kind} → ${event.message}',
    );
  }
}
