import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import 'telemetry_event.dart';
import 'telemetry_sink.dart';

/// `SentryTelemetrySink` — submits Sentry-compatible envelopes to a
/// configured DSN endpoint. Compatible with Sentry SaaS, GlitchTip,
/// and any self-hosted Sentry-compatible API.
///
/// The DSN is supplied via `--dart-define=SENTRY_DSN=…` and parsed
/// into:
///   • `endpoint`     — `https://<host>/api/<project>/store/`
///   • `publicKey`    — used in the `X-Sentry-Auth` header
///
/// Events that fail to send are silently buffered up to [bufferCap]
/// and retried on the next successful submit. On critical pipeline
/// failure (e.g. DNS), `submit` swallows the error so the rest of
/// the sink fan-out keeps working.
class SentryTelemetrySink extends TelemetrySink {
  SentryTelemetrySink({
    String? dsn,
    Dio? dio,
    this.bufferCap = 32,
    this.environment = 'production',
    this.release = 'globeid@dev',
  })  : _dsn = dsn ?? const String.fromEnvironment('SENTRY_DSN'),
        _dio = dio ?? _defaultDio() {
    _parsed = _parseDsn(_dsn);
  }

  static Dio _defaultDio() => Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 4),
        headers: {'Content-Type': 'application/json'},
      ));

  final String _dsn;
  final Dio _dio;
  final int bufferCap;
  final String environment;
  final String release;

  _Dsn? _parsed;

  final List<TelemetryEvent> _pending = [];

  @override
  String get name => 'sentry';

  @override
  bool get enabled => _parsed != null;

  @override
  Future<void> submit(TelemetryEvent event) async {
    final parsed = _parsed;
    if (parsed == null) return;
    _pending.add(event);
    if (_pending.length > bufferCap) {
      _pending.removeRange(0, _pending.length - bufferCap);
    }
    final inflight = List<TelemetryEvent>.from(_pending);
    _pending.clear();
    for (final e in inflight) {
      try {
        await _send(parsed, e);
      } catch (_) {
        _pending.add(e);
      }
    }
  }

  Future<void> _send(_Dsn dsn, TelemetryEvent event) async {
    final payload = {
      ...event.toJson(),
      'environment': environment,
      'release': release,
      'platform': 'dart',
    };
    await _dio.post(
      dsn.endpoint,
      data: payload,
      options: Options(headers: {
        'X-Sentry-Auth':
            'Sentry sentry_version=7, sentry_key=${dsn.publicKey}, '
                'sentry_client=globeid-telemetry/1.0',
      }),
    );
  }

  /// Public for tests so the parser is unit-testable.
  static _Dsn? _parseDsn(String dsn) {
    if (dsn.isEmpty) return null;
    final uri = Uri.tryParse(dsn);
    if (uri == null || uri.userInfo.isEmpty || uri.pathSegments.isEmpty) {
      return null;
    }
    final publicKey = uri.userInfo.split(':').first;
    final project = uri.pathSegments.last;
    final host = uri.host;
    final scheme = uri.scheme.isEmpty ? 'https' : uri.scheme;
    return _Dsn(
      publicKey: publicKey,
      endpoint: '$scheme://$host/api/$project/store/',
    );
  }

  @visibleForTesting
  String? get endpointForTest => _parsed?.endpoint;
  @visibleForTesting
  String? get publicKeyForTest => _parsed?.publicKey;
  @visibleForTesting
  List<TelemetryEvent> get pendingForTest => List.unmodifiable(_pending);
}

class _Dsn {
  const _Dsn({required this.publicKey, required this.endpoint});
  final String publicKey;
  final String endpoint;
}
