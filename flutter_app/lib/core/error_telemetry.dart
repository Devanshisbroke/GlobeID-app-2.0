import 'package:flutter/foundation.dart';

/// A captured runtime error event. Kept intentionally small so the
/// telemetry buffer can hold a few dozen events without ballooning
/// memory.
@immutable
class ErrorEvent {
  const ErrorEvent({
    required this.at,
    required this.summary,
    required this.library,
    required this.stack,
    required this.kind,
  });

  /// Wall-clock timestamp of the event (local time).
  final DateTime at;

  /// Single-line exception string (`details.exceptionAsString()` or the
  /// async error's `toString()`).
  final String summary;

  /// Originating framework library or 'async' for `PlatformDispatcher`
  /// errors. Free-form, not enumerated.
  final String library;

  /// Full stack trace text (or empty).
  final String stack;

  /// Either `framework` (Flutter widget tree throws) or `async`
  /// (unhandled `PlatformDispatcher` errors). Used to filter the
  /// debug viewer.
  final String kind;
}

/// App-level in-memory error log buffer.
///
/// Collects a rolling window of the most recent runtime errors so a
/// silent crash inside a sub-tree (caught by `SafeBoundary` /
/// `InlineErrorWidget`) doesn't disappear into the void. The debug
/// `/debug/errors` route renders this buffer for triage.
///
/// Capped at 64 events — old events fall off the head as new ones
/// arrive. No file I/O, no network, in-memory only. The buffer is
/// cleared when the process exits.
class ErrorTelemetry {
  ErrorTelemetry._();
  static final ErrorTelemetry instance = ErrorTelemetry._();

  static const int _capacity = 64;

  final List<ErrorEvent> _events = <ErrorEvent>[];
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  List<ErrorEvent> get events => List<ErrorEvent>.unmodifiable(_events);

  void record({
    required String summary,
    required String library,
    required String stack,
    required String kind,
  }) {
    _events.insert(
      0,
      ErrorEvent(
        at: DateTime.now(),
        summary: summary,
        library: library,
        stack: stack,
        kind: kind,
      ),
    );
    if (_events.length > _capacity) {
      _events.removeRange(_capacity, _events.length);
    }
    revision.value++;
  }

  void clear() {
    _events.clear();
    revision.value++;
  }
}
