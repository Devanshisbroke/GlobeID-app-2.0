import 'telemetry_event.dart';
import 'telemetry_sink.dart';

/// A purely in-memory sink — keeps the last [capacity] events for
/// the operator screen and the existing /debug/errors viewer.
class BufferTelemetrySink extends TelemetrySink {
  BufferTelemetrySink({this.capacity = 128, this.enabled = true});

  final int capacity;
  @override
  final bool enabled;

  final List<TelemetryEvent> _events = [];

  List<TelemetryEvent> get events => List.unmodifiable(_events);

  @override
  String get name => 'buffer';

  @override
  Future<void> submit(TelemetryEvent event) async {
    if (!enabled) return;
    _events.insert(0, event);
    if (_events.length > capacity) {
      _events.removeRange(capacity, _events.length);
    }
  }

  void clear() => _events.clear();
}
