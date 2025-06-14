import 'package:dio/dio.dart';
import 'package:bm_security/services/http/auth_service.dart';
import 'package:bm_security/utils/auth_config.dart';

class HttpManager {
  static final HttpManager _instance = HttpManager._internal();
  late final Dio dio;
  final _authService = AuthService();

  factory HttpManager() {
    return _instance;
  }

  HttpManager._internal() {
    print('🌐 Initializing HTTP Manager');
    print('🔗 Base URL: ${ApiConfig.baseUrl}');

    dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        print('📤 Making request to: ${options.uri}');

        // Add token for non-auth endpoints
        if (!options.path.contains('/auth/')) {
          final token = await _authService.gettoken();
          if (token != null) {
            print('🔑 Adding token to request');
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            print('⚠️ No token available for request');
          }
        }

        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('📥 Response received: ${response.statusCode}');
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        print('❌ Request failed: ${e.type}');
        print('Error message: ${e.message}');
        print('Response status: ${e.response?.statusCode}');

        // Only clear token for actual 401 responses
        if (e.response?.statusCode == 401) {
          print('🔒 Unauthorized access detected');
          await _authService.cleartoken();
          return handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              error: 'Session expired. Please login again.',
              type: DioExceptionType.badResponse,
            ),
          );
        }

        // Handle 403 Forbidden errors
        if (e.response?.statusCode == 403) {
          print('🚫 Forbidden access detected');
          return handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              error: 'You do not have permission to access this resource.',
              type: DioExceptionType.badResponse,
            ),
          );
        }

        // Handle network errors without clearing token
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.unknown) {
          print('🌐 Network error detected');
          return handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              error: 'Network error. Please check your connection.',
              type: e.type,
            ),
          );
        }

        return handler.next(e);
      },
    ));
  }
}
