import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:logger/logger.dart';

import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../local/storage_service.dart';

class ApiClient {
  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: AppConstants.apiTimeout,
      receiveTimeout: AppConstants.apiTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.addAll([
      _AuthInterceptor(_dio),
      LogInterceptor(
        request: false,
        responseBody: true,
        requestBody: true,
        error: true,
        logPrint: (o) => _log.d(o),
      ),
    ]);
  }

  static final ApiClient instance = ApiClient._();
  late final Dio _dio;
  final _log = Logger(printer: PrettyPrinter(methodCount: 0));

  Dio get dio => _dio;

  // ─── Generic request helpers ──────────────────────────────────────────────

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.get(path, queryParameters: queryParameters, options: options);

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.post(path, data: data, queryParameters: queryParameters, options: options);

  Future<Response> put(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _dio.put(path, data: data, options: options);

  Future<Response> patch(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _dio.patch(path, data: data, options: options);

  Future<Response> delete(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _dio.delete(path, data: data, options: options);

  // ─── Error helper ─────────────────────────────────────────────────────────

  static String parseError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        return (data['message'] as Object?)?.toString() ??
            error.message ??
            'An error occurred';
      }
      return error.message ?? 'Network error';
    }
    return error.toString();
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio);
  final Dio _dio;

  // Completer shared by all concurrent 401s so only one refresh fires.
  Future<String>? _refreshFuture;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await StorageService.instance.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // Never retry auth endpoints — just clear and redirect.
    if (err.requestOptions.path.contains('/auth/')) {
      await _clearAndRedirect();
      handler.next(err);
      return;
    }

    try {
      final newToken = await (_refreshFuture ??= _doRefresh());
      err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
      final retried = await _dio.fetch(err.requestOptions);
      handler.resolve(retried);
    } catch (_) {
      await _clearAndRedirect();
      handler.next(err);
    } finally {
      _refreshFuture = null;
    }
  }

  Future<String> _doRefresh() async {
    final stored = await StorageService.instance.getRefreshToken();
    if (stored == null || stored.isEmpty) throw Exception('no refresh token');

    final refreshDio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));
    final res = await refreshDio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'token': stored},
    );
    final body = res.data!;
    final access  = body['accessToken']  as String? ?? body['access_token']  as String? ?? '';
    final refresh = body['refreshToken'] as String? ?? body['refresh_token'] as String? ?? stored;
    if (access.isEmpty) throw Exception('empty access token in refresh response');

    await StorageService.instance.saveTokens(
      accessToken: access,
      refreshToken: refresh,
    );
    return access;
  }

  Future<void> _clearAndRedirect() async {
    await StorageService.instance.clearAll();
    Get.offAllNamed(Routes.login);
  }
}
