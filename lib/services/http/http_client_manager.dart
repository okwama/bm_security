// File: services/http/http_client_manager.dart
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../../utils/auth_config.dart';
import 'auth_service.dart';

class HttpClientManager {
  static final HttpClientManager _instance = HttpClientManager._internal();
  Dio? _dio;
  final _authService = AuthService();
  bool _isInitialized = false;

  static HttpClientManager get instance {
    print('🔍 Getting HttpClientManager instance');
    return _instance;
  }

  factory HttpClientManager() {
    print('🏭 Creating new HttpClientManager instance');
    return _instance;
  }

  HttpClientManager._internal() {
    print('🌐 Initializing HTTP Manager');
    print('🔗 Base URL: ${ApiConfig.baseUrl}');
    _initializeDio();
  }

  void _initializeDio() {
    try {
      _dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ));

      print('📡 Dio instance created: ${_dio != null}');

      // Add interceptors
      _dio?.interceptors.add(InterceptorsWrapper(
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

      _isInitialized = true;
    } catch (e) {
      print('❌ Error initializing Dio: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  Dio get dioClient {
    print('🔍 Getting dioClient');
    if (!_isInitialized || _dio == null) {
      print('⚠️ Dio not initialized, attempting to reinitialize...');
      _initializeDio();
    }

    if (_dio == null) {
      throw Exception('Failed to initialize Dio client');
    }

    print('📡 Dio instance exists: ${_dio != null}');
    return _dio!;
  }

  http.Client? _client;
  final Set<String> _activeRequests = <String>{};
  bool _isDisposed = false;

  http.Client get client {
    if (_client == null || _isDisposed) {
      _client = http.Client();
      _isDisposed = false;
    }
    return _client!;
  }

  String addActiveRequest(String requestId) {
    _activeRequests.add(requestId);
    return requestId;
  }

  void removeActiveRequest(String requestId) {
    _activeRequests.remove(requestId);
  }

  void dispose() {
    if (_activeRequests.isNotEmpty) {
      print(
          'Warning: Disposing client with ${_activeRequests.length} active requests');
      return;
    }

    _client?.close();
    _client = null;
    _isDisposed = true;
  }

  void forceDispose() {
    _activeRequests.clear();
    _client?.close();
    _client = null;
    _isDisposed = true;
  }
}
