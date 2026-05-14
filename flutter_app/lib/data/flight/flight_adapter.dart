import 'flight_models.dart';

/// Contract every flight data source must satisfy.
///
/// Two adapters ship with GlobeID:
///   • `AeroapiFlightAdapter` — calls FlightAware AeroAPI v4
///     (needs API key)
///   • `DemoFlightAdapter`    — deterministic state machine that
///     drives a known LH 401 trip through every FlightPhase
abstract class FlightAdapter {
  String get source;
  Future<FlightQuote> quote(FlightHandle handle);
}

class FlightAdapterException implements Exception {
  FlightAdapterException(this.message);
  final String message;
  @override
  String toString() => 'FlightAdapterException: $message';
}
