import 'package:dio/dio.dart';

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
class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBase {
    _dio = Dio(BaseOptions(
      baseUrl: this.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
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
    final res = await _dio.post('/auth/demo');
    final json = res.data as Map<String, dynamic>;
    if (json['ok'] != true) {
      throw _toApiError(json, res.statusCode ?? 500);
    }
    final data = json['data'] as Map<String, dynamic>;
    final t = data['token'] as String;
    await setToken(t);
    return t;
  }

  Future<T> get<T>(String path) => _request<T>(() => _dio.get<dynamic>(path));

  Future<T> post<T>(String path, {Object? body}) =>
      _request<T>(() => _dio.post<dynamic>(path, data: body));

  Future<T> patch<T>(String path, {Object? body}) =>
      _request<T>(() => _dio.patch<dynamic>(path, data: body));

  Future<T> put<T>(String path, {Object? body}) =>
      _request<T>(() => _dio.put<dynamic>(path, data: body));

  Future<T> delete<T>(String path, {Object? body}) =>
      _request<T>(() => _dio.delete<dynamic>(path, data: body));

  Future<T> _request<T>(Future<Response<dynamic>> Function() run) async {
    try {
      final res = await run();
      return _unwrap<T>(res);
    } on DioException catch (e) {
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
