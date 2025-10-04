// File: services/http/http_client_manager.dart
// Unified HTTP client manager for all API communications
// Handles authentication, token refresh, and error management
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../utils/auth_config.dart';
import '../../utils/navigation.dart';
import '../../core/constants/app_constants.dart';
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
        connectTimeout: const Duration(seconds: 10), // Reduced from 30s
        receiveTimeout: const Duration(seconds: 15), // Reduced from 30s
        sendTimeout: const Duration(seconds: 10), // Reduced from 30s
        headers: {
          AppConstants.contentTypeHeader: AppConstants.applicationJson,
          'Accept': AppConstants.applicationJson,
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
              options.headers[AppConstants.authorizationHeader] = AppConstants.getBearerToken(token);
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

          // Handle 401 responses with silent refresh
          if (e.response?.statusCode == 401) {
            print(
                '🔒 Unauthorized access detected - attempting silent refresh');

            // Try silent token refresh first
            final refreshSuccess = await _authService.silentRefreshToken();

            if (refreshSuccess) {
              print('✅ Silent refresh successful - retrying original request');
              // Retry the original request with new token
              final newToken = await _authService.accessToken;
              if (newToken != null) {
                e.requestOptions.headers[AppConstants.authorizationHeader] = AppConstants.getBearerToken(newToken);
                return handler.resolve(await _dio!.fetch(e.requestOptions));
              }
            } else {
              print('❌ Silent refresh failed - clearing token and notifying user');
              await _authService.cleartoken();
              
              // Show user-friendly message
              _showSessionExpiredDialog();
              
              return handler.reject(
                DioException(
                  requestOptions: e.requestOptions,
                  error: 'Session expired. Please login again.',
                  type: DioExceptionType.badResponse,
                ),
              );
            }
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

  void _showSessionExpiredDialog() {
    final context = NavigationService.navigatorKey.currentContext;
    if (context != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Session Expired'),
            content: const Text(
              'Your session has expired. Please log in again to continue.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
}
