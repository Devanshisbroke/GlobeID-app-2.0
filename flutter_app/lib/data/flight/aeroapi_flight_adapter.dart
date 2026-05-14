import 'package:dio/dio.dart';

import 'flight_adapter.dart';
import 'flight_models.dart';

/// `AeroapiFlightAdapter` — production adapter against the
/// FlightAware AeroAPI v4 endpoint.
///
/// Endpoint: `GET https://aeroapi.flightaware.com/aeroapi/flights/{ident}`
/// Auth:     `x-apikey: <AEROAPI_KEY>`
/// Response: `{ flights: [{ ident, fa_flight_id, origin: { code }, ... }] }`
///
/// This adapter is the shape every future production flight source
/// (AeroAPI, OpenSky, Cirium) implements. The API key is supplied
/// via `--dart-define=AEROAPI_KEY=...` so it never lands in the
/// source tree.
class AeroapiFlightAdapter extends FlightAdapter {
  AeroapiFlightAdapter({
    String? apiKey,
    Dio? dio,
  })  : _apiKey =
            apiKey ?? const String.fromEnvironment('AEROAPI_KEY'),
        _dio = dio ?? _defaultDio();

  static Dio _defaultDio() => Dio(BaseOptions(
        baseUrl: 'https://aeroapi.flightaware.com/aeroapi',
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 6),
        headers: {'Accept': 'application/json'},
      ));

  final Dio _dio;
  final String _apiKey;

  @override
  String get source => 'aeroapi';

  @override
  Future<FlightQuote> quote(FlightHandle handle) async {
    if (_apiKey.isEmpty) {
      throw FlightAdapterException(
        'AEROAPI_KEY missing — pass via --dart-define',
      );
    }
    final res = await _dio.get(
      '/flights/${handle.handle}',
      options: Options(headers: {'x-apikey': _apiKey}),
    );
    final data = res.data;
    if (data is! Map || data['flights'] is! List || (data['flights'] as List).isEmpty) {
      throw FlightAdapterException(
        'AeroAPI returned no flight rows for ${handle.display}',
      );
    }
    final row = (data['flights'] as List).first as Map;
    return parse(row, handle);
  }

  /// Public so the test suite can verify the parser without a live
  /// network call.
  FlightQuote parse(Map row, FlightHandle handle) {
    final phase = _phase(row);
    final scheduledOut = _ts(row['scheduled_out']) ?? DateTime.now();
    final estimatedOut = _ts(row['estimated_out']);
    final actualOut = _ts(row['actual_out']);
    final delay = _delayMinutes(scheduledOut, estimatedOut ?? actualOut);
    return FlightQuote(
      handle: handle,
      phase: phase,
      origin: _code(row['origin']),
      destination: _code(row['destination']),
      scheduledOut: scheduledOut,
      estimatedOut: estimatedOut ?? actualOut,
      delayMinutes: delay,
      gate: row['gate_origin']?.toString(),
      terminal: row['terminal_origin']?.toString(),
      fetchedAt: DateTime.now(),
      source: source,
    );
  }

  static String _code(dynamic v) {
    if (v is Map) return v['code']?.toString() ?? '???';
    return '???';
  }

  static DateTime? _ts(dynamic v) {
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }

  static int _delayMinutes(DateTime sched, DateTime? actualOrEst) {
    if (actualOrEst == null) return 0;
    return actualOrEst.difference(sched).inMinutes;
  }

  static FlightPhase _phase(Map row) {
    if (row['cancelled'] == true) return FlightPhase.cancelled;
    if (row['actual_in'] != null) return FlightPhase.landed;
    if (row['actual_off'] != null && row['actual_on'] == null) {
      return FlightPhase.inAir;
    }
    if (row['actual_on'] != null) return FlightPhase.approach;
    if (row['actual_out'] != null) return FlightPhase.pushback;
    if (row['gate_closed'] == true) return FlightPhase.closed;
    if (row['boarding'] == true) return FlightPhase.boarding;
    if (row['check_in_open'] == true) return FlightPhase.checkIn;
    return FlightPhase.scheduled;
  }
}
