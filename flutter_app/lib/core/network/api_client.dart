import 'package:dio/dio.dart';

import '../../data/api/demo_data.dart';
import '../storage/preferences.dart';

/// Dart port of `src/lib/apiClient.ts`.
///
/// - Reads the API base URL from `--dart-define=API_BASE_URL=...`
///   (defaults to `http://10.0.2.2:4000/api/v1` for Android emulator,
///   so the dev Hono server on the host is reachable).
/// - Issues a static demo token on first hit and caches it in
///   SharedPreferences under `globe-auth.token` (matches localStorage key).
/// - Unwraps the `{ ok, data | error }` envelope and throws [ApiError]
///   on failure.
/// - When the network is unavailable (Dio timeouts, DNS failures, 5xx,
///   missing host) and demo data is available for the requested path,
///   transparently falls back to [DemoData.respond] so the app remains
///   fully usable offline. This is the difference between an empty
///   error-screen UX and a fully populated, alive demo.
class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBase {
    _dio = Dio(BaseOptions(
      baseUrl: this.baseUrl,
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 6),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(_AuthInterceptor(this));
  }

  final String baseUrl;
  late final Dio _dio;

  static const String _defaultBase = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000/api/v1',
  );

  static const String _tokenKey = 'auth.token';

  String? get token => Preferences.instance.readString(_tokenKey);

  Future<void> setToken(String t) =>
      Preferences.instance.writeString(_tokenKey, t);

  Future<String> bootstrapToken() async {
    try {
      final res = await _dio.post('/auth/demo');
      final json = res.data as Map<String, dynamic>;
      if (json['ok'] != true) {
        throw _toApiError(json, res.statusCode ?? 500);
      }
      final data = json['data'] as Map<String, dynamic>;
      final t = data['token'] as String;
      await setToken(t);
      return t;
    } on DioException {
      // Offline fallback — synthesize a demo token so we can satisfy the
      // Authorization header and continue running fully on demo data.
      const t = 'demo-offline-token';
      await setToken(t);
      return t;
    }
  }

  Future<T> get<T>(String path) =>
      _request<T>('GET', path, () => _dio.get<dynamic>(path));

  Future<T> post<T>(String path, {Object? body}) =>
      _request<T>('POST', path, () => _dio.post<dynamic>(path, data: body));

  Future<T> patch<T>(String path, {Object? body}) =>
      _request<T>('PATCH', path, () => _dio.patch<dynamic>(path, data: body));

  Future<T> put<T>(String path, {Object? body}) =>
      _request<T>('PUT', path, () => _dio.put<dynamic>(path, data: body));

  Future<T> delete<T>(String path, {Object? body}) =>
      _request<T>('DELETE', path, () => _dio.delete<dynamic>(path, data: body));

  Future<T> _request<T>(
    String method,
    String path,
    Future<Response<dynamic>> Function() run,
  ) async {
    try {
      final res = await run();
      return _unwrap<T>(res);
    } on DioException catch (e) {
      // Network-level failure — try the offline demo fallback before
      // surfacing an error to the UI.
      if (_isNetworkFailure(e)) {
        final demo = DemoData.respond(method, path);
        if (demo != null) {
          return demo as T;
        }
      }
      throw _toApiError(
        e.response?.data is Map<String, dynamic>
            ? e.response!.data as Map<String, dynamic>
            : {
                'error': {
                  'code': 'NETWORK',
                  'message': e.message ?? 'Network error'
                }
              },
        e.response?.statusCode ?? 500,
      );
    }
  }

  bool _isNetworkFailure(DioException e) {
    if (e.response == null) return true;
    final code = e.response!.statusCode ?? 0;
    return code == 0 || code >= 500;
  }

  T _unwrap<T>(Response<dynamic> res) {
    final json = res.data;
    if (json is! Map<String, dynamic>) {
      throw ApiError(
          'PARSE', 'Unexpected response shape', res.statusCode ?? 500);
    }
    if (json['ok'] != true) {
      throw _toApiError(json, res.statusCode ?? 500);
    }
    return json['data'] as T;
  }

  ApiError _toApiError(Map<String, dynamic> json, int status) {
    final err = json['error'];
    if (err is Map<String, dynamic>) {
      return ApiError(
        (err['code'] as String?) ?? 'UNKNOWN',
        (err['message'] as String?) ?? 'Unknown error',
        status,
      );
    }
    return ApiError('UNKNOWN', 'Unknown error', status);
  }
}

class ApiError implements Exception {
  ApiError(this.code, this.message, this.status);
  final String code;
  final String message;
  final int status;

  @override
  String toString() => 'ApiError($status, $code): $message';
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._client);

  final ApiClient _client;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.path == '/auth/demo') {
      handler.next(options);
      return;
    }
    var token = _client.token;
    token ??= await _client.bootstrapToken();
    options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 &&
        err.requestOptions.path != '/auth/demo' &&
        err.requestOptions.extra['_retried'] != true) {
      try {
        final newToken = await _client.bootstrapToken();
        final retry = err.requestOptions.copyWith(extra: {'_retried': true});
        retry.headers['Authorization'] = 'Bearer $newToken';
        final clone = await Dio().fetch<dynamic>(retry);
        handler.resolve(clone);
        return;
      } catch (_) {/* fall through */}
    }
    handler.next(err);
  }
}
