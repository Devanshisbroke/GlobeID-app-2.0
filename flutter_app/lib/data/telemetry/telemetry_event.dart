/// Severity of a telemetry event. Maps onto Sentry levels.
enum TelemetryLevel { debug, info, warning, error, fatal }

extension TelemetryLevelX on TelemetryLevel {
  String get handle => switch (this) {
        TelemetryLevel.debug => 'DEBUG',
        TelemetryLevel.info => 'INFO',
        TelemetryLevel.warning => 'WARNING',
        TelemetryLevel.error => 'ERROR',
        TelemetryLevel.fatal => 'FATAL',
      };

  int get tone => switch (this) {
        TelemetryLevel.debug => 0xFF8B96A6,
        TelemetryLevel.info => 0xFF6CC4FF,
        TelemetryLevel.warning => 0xFFFFB347,
        TelemetryLevel.error => 0xFFFF8A8A,
        TelemetryLevel.fatal => 0xFFFF6A6A,
      };
}

/// A single event submitted to the telemetry pipeline.
class TelemetryEvent {
  TelemetryEvent({
    required this.kind,
    required this.message,
    required this.level,
    required this.timestamp,
    this.attributes = const {},
    this.fingerprint,
    this.library = 'app',
    this.stack = '',
  });

  /// Free-form taxonomy tag (e.g. `nav.route_change`, `auth.failed`,
  /// `error.framework`). The first segment is the category.
  final String kind;

  /// Human-readable single-line summary.
  final String message;

  final TelemetryLevel level;
  final DateTime timestamp;

  /// Structured attributes — keys are flat strings, values are
  /// primitives (strings, numbers, booleans).
  final Map<String, Object?> attributes;

  /// Optional grouping key. Two events with the same fingerprint
  /// collapse into one issue at the sink.
  final String? fingerprint;

  /// Originating library / module — drives the issue-owner mapping
  /// in the upstream sink.
  final String library;

  /// Stack trace (optional). Sent only for `error` / `fatal` level
  /// events.
  final String stack;

  /// Sentry-style JSON event payload.
  Map<String, Object?> toJson() => {
        'event_id': '${timestamp.microsecondsSinceEpoch}',
        'timestamp': timestamp.toUtc().toIso8601String(),
        'level': level.handle.toLowerCase(),
        'logger': library,
        'message': {'message': message},
        'tags': {
          'kind': kind,
          ...{
            for (final entry in attributes.entries) entry.key: entry.value,
          }
        },
        if (fingerprint != null) 'fingerprint': [fingerprint!],
        if (stack.isNotEmpty)
          'exception': {
            'values': [
              {
                'type': kind,
                'value': message,
                'stacktrace': {'frames': _frames(stack)},
              }
            ],
          },
      };

  static List<Map<String, Object?>> _frames(String stack) {
    final lines =
        stack.split('\n').where((l) => l.trim().isNotEmpty).toList();
    return lines.reversed.map((l) => {'filename': l.trim()}).toList();
  }

  @override
  String toString() =>
      'TelemetryEvent($kind/${level.handle}: $message @ $timestamp)';
}
