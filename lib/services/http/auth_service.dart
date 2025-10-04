// File: services/http/auth_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'dart:async';
import '../../core/constants/app_constants.dart';
import '../../utils/navigation.dart';
import 'package:get/get.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import 'http_client_manager.dart';

class AuthService extends GetxService {
  static final AuthService _instance = AuthService._internal();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String _baseUrl = AppConstants.baseUrl;
  Timer? _refreshTimer;
  bool _isRefreshing = false;

  // token refresh interval (15 minutes)
  static const _refreshInterval = Duration(minutes: 15);

  // Token keys - using consolidated constants
  static const String _accessTokenKey = AppConstants.accessTokenKey;
  static const String _refreshTokenKey = AppConstants.refreshTokenKey;
  static const String _userKey = AppConstants.userKey;

  // Get stored access token
  Future<String?> get accessToken async => await _storage.read(key: _accessTokenKey);

  // Get stored refresh token
  Future<String?> get refreshToken async => await _storage.read(key: _refreshTokenKey);

  // Get stored user data
  Future<Map<String, dynamic>?> get userData async {
    final userJson = await _storage.read(key: _userKey);
    if (userJson != null) {
      return jsonDecode(userJson);
    }
    return null;
  }

  // Check if user is logged in
  Future<bool> get isLoggedIn async {
    final token = await accessToken;
    return token != null;
  }

  factory AuthService() {
    return _instance;
  }

  AuthService._internal() {
    _initializeAuthState();
  }

  // Initialize auth state on app startup
  Future<void> _initializeAuthState() async {
    try {
      // Check if we have any stored tokens
      final token = await accessToken;
      if (token != null) {
        // Don't validate token on startup - let it be validated on first API call
        // This prevents unnecessary clearing of valid tokens
      }
    } catch (e) {
      // Only clear auth data if there's a critical error
      await _clearAuthData();
    }
  }

  Future<String?> gettoken() async {
    try {
      final token = await _storage.read(key: _accessTokenKey);
      if (token != null) {
        return token;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> settoken(String token) async {
    try {
      await _storage.write(key: _accessTokenKey, value: token);
      // Also store under 'token' key for backward compatibility
      await _storage.write(key: 'token', value: token);
      _startRefreshTimer();
    } catch (e) {
      throw Exception('Failed to store token');
    }
  }

  Future<void> cleartoken() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      // Also clear 'token' key for backward compatibility
      await _storage.delete(key: 'token');
    } catch (e) {
      // Silent error handling
    }
  }

  Future<Map<String, String>> getHeaders() async {
    final token = await accessToken;
    if (token == null) {
      return {
        AppConstants.contentTypeHeader: AppConstants.applicationJson,
        'Accept': AppConstants.applicationJson,
      };
    }
    return {
      AppConstants.contentTypeHeader: AppConstants.applicationJson,
      'Accept': AppConstants.applicationJson,
      AppConstants.authorizationHeader: AppConstants.getBearerToken(token),
    };
  }

  Future<void> saveAuthData(Map<String, dynamic> data) async {
    try {
      if (data['accessToken'] != null) {
        await _storage.write(key: _accessTokenKey, value: data['accessToken']);
      }
      if (data['refreshToken'] != null) {
        await _storage.write(key: _refreshTokenKey, value: data['refreshToken']);
      }
      if (data['user'] != null) {
        await _storage.write(key: _userKey, value: jsonEncode(data['user']));
      }

      // Store device info and IP if available
      if (data['deviceInfo'] != null) {
        await _storage.write(key: 'device_info', value: jsonEncode(data['deviceInfo']));
      }
      if (data['ipAddress'] != null) {
        await _storage.write(key: 'ip_address', value: data['ipAddress']);
      }

      await settoken(data['accessToken'] ?? '');
      _startRefreshTimer();
    } catch (e) {
      throw Exception('Failed to save authentication data');
    }
  }

  Future<void> _clearAuthData() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _userKey);
      // Also clear 'token' key for backward compatibility
      await _storage.delete(key: 'token');
      await cleartoken();
      _stopRefreshTimer();
    } catch (e) {
      // Silent error handling
    }
  }

  Future<bool> refreshAccessToken() async {
    if (_isRefreshing) {
      return false;
    }
    _isRefreshing = true;

    try {
      final currentRefreshToken = await refreshToken;
      if (currentRefreshToken == null) {
        return false;
      }

      // Use HttpClientManager for consistent timeout handling
      final httpManager = HttpClientManager.instance;
      final dio = httpManager.dioClient;

      final response = await dio.post(
        AppConstants.authRefreshEndpoint,
        data: {
          'refreshToken': currentRefreshToken,
        },
        options: Options(
          headers: {
            AppConstants.contentTypeHeader: AppConstants.applicationJson,
            'Accept': AppConstants.applicationJson,
          },
          validateStatus: (status) => status! < 500, // Allow 4xx responses
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        await saveAuthData(data);
        return true;
      } else {
        await _clearAuthData();
        _navigateToLogin();
        return false;
      }
    } catch (e) {
      await _clearAuthData();
      _navigateToLogin();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Silent token refresh - doesn't show dialogs or navigate
  Future<bool> silentRefreshToken() async {
    if (_isRefreshing) {
      return false;
    }
    _isRefreshing = true;

    try {
      final currentRefreshToken = await refreshToken;
      if (currentRefreshToken == null) {
        return false;
      }

      // Use HttpClientManager for consistent timeout handling
      final httpManager = HttpClientManager.instance;
      final dio = httpManager.dioClient;

      final response = await dio.post(
        AppConstants.authRefreshEndpoint,
        data: {
          'refreshToken': currentRefreshToken,
        },
        options: Options(
          headers: {
            AppConstants.contentTypeHeader: AppConstants.applicationJson,
            'Accept': AppConstants.applicationJson,
          },
          validateStatus: (status) => status! < 500, // Allow 4xx responses
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        await saveAuthData(data);
        return true;
      } else {
        await _clearAuthData();
        return false;
      }
    } catch (e) {
      await _clearAuthData();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  void _startRefreshTimer() {
    _stopRefreshTimer();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) async {
      await refreshAccessToken();
    });
  }

  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void _navigateToLogin() {
    final context = NavigationService.navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  void _notifyTokenExpired(String message) {
    // This would be called from HTTP interceptors when token refresh fails
    // The actual implementation would depend on how you want to handle this
    // For now, we'll just log it and let the HTTP interceptors handle navigation
  }

  // Method to check if token needs refresh
  Future<bool> shouldRefreshToken() async {
    try {
      final token = await accessToken;
      if (token == null) return false;

      final parts = token.split('.');
      if (parts.length != 3) return false;

      final payload = base64Url.decode(parts[1]);
      final payloadJson = jsonDecode(utf8.decode(payload));
      final exp = payloadJson['exp'];
      
      if (exp != null) {
        final expirationTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        final now = DateTime.now();
        final timeUntilExpiry = expirationTime.difference(now);
        
        // Refresh if token expires within 5 minutes
        return timeUntilExpiry.inMinutes < 5;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Method to handle token refresh
  Future<bool> refreshTokenIfNeeded() async {
    try {
      if (await shouldRefreshToken()) {
        final refreshToken = await this.refreshToken;
        
        if (refreshToken != null) {
          // Attempt to refresh the token
          final success = await refreshAccessToken();
          if (success) {
            return true;
          }
        }
        
        await _clearAuthData();
        return false;
      }
      
      return true; // Token doesn't need refresh
    } catch (e) {
      await _clearAuthData();
      return false;
    }
  }

  Future<bool> isAuthenticated() async {
    try {
      final token = await accessToken;
      if (token == null) {
        return false;
      }

      // Verify token structure and expiration
      try {
        final parts = token.split('.');
        if (parts.length != 3) {
          await _clearAuthData();
          return false;
        }

        // Decode and validate JWT payload
        try {
          final header = base64Url.decode(parts[0]);
          final payload = base64Url.decode(parts[1]);
          
          // Parse payload to check expiration
          final payloadJson = jsonDecode(utf8.decode(payload));
          final exp = payloadJson['exp'];
          
          if (exp != null) {
            final expirationTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
            final now = DateTime.now();
            
            if (now.isAfter(expirationTime)) {
              await _clearAuthData();
              return false;
            }
          }
          
          return true;
        } catch (e) {
          await _clearAuthData();
          return false;
        }
      } catch (e) {
        await _clearAuthData();
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<String> getValidtoken() async {
    final token = await gettoken();
    if (token == null) {
      _navigateToLogin();
      throw Exception('Authentication required. Please login again.');
    }
    return token;
  }

  // Login
  Future<Map<String, dynamic>> login(String emplNo, String password) async {
    try {
      // Use HttpClientManager for consistent timeout handling
      final httpManager = HttpClientManager.instance;
      final dio = httpManager.dioClient;
      
      final response = await dio.post(
        AppConstants.authLoginEndpoint,
        data: {
          'employeeNumber': emplNo,
          'password': password,
        },
        options: Options(
          headers: {
            AppConstants.contentTypeHeader: AppConstants.applicationJson,
            'Accept': AppConstants.applicationJson,
          },
          validateStatus: (status) => status! < 500, // Allow 4xx responses
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        // Handle the actual backend response structure
        await saveAuthData({
          'accessToken': data['accessToken'],
          'refreshToken': data['refreshToken'],
          'user': data['user'],
        });
        return data;
      } else {
        final errorMessage = response.data?['message'] ?? 'Login failed';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout) {
          throw Exception('Connection timeout. Please check your network.');
        } else if (e.type == DioExceptionType.receiveTimeout) {
          throw Exception('Server response timeout. Please try again.');
        } else if (e.type == DioExceptionType.sendTimeout) {
          throw Exception('Request timeout. Please try again.');
        }
      }
      throw Exception('Login failed: $e');
    }
  }

  // Register
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      // Use HttpClientManager for consistent timeout handling
      final httpManager = HttpClientManager.instance;
      final dio = httpManager.dioClient;
      
      final response = await dio.post(
        '/auth/register',
        data: userData,
        options: Options(
          headers: {
            AppConstants.contentTypeHeader: AppConstants.applicationJson,
            'Accept': AppConstants.applicationJson,
          },
          validateStatus: (status) => status! < 500, // Allow 4xx responses
        ),
      );

      if (response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        await saveAuthData(data);
        return data;
      } else {
        final errorMessage = response.data?['message'] ?? 'Registration failed';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout) {
          throw Exception('Connection timeout. Please check your network.');
        } else if (e.type == DioExceptionType.receiveTimeout) {
          throw Exception('Server response timeout. Please try again.');
        } else if (e.type == DioExceptionType.sendTimeout) {
          throw Exception('Request timeout. Please try again.');
        }
      }
      throw Exception('Registration failed: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      final refreshToken = await this.refreshToken;
      
      if (refreshToken != null) {
        try {
          // Use HttpClientManager for consistent timeout handling
          final httpManager = HttpClientManager.instance;
          final dio = httpManager.dioClient;

          await dio.post(
            AppConstants.authLogoutEndpoint,
            data: {
              'refreshToken': refreshToken,
            },
            options: Options(
              headers: {
                AppConstants.contentTypeHeader: AppConstants.applicationJson,
                'Accept': AppConstants.applicationJson,
                AppConstants.authorizationHeader: AppConstants.getBearerToken(await gettoken() ?? ''),
              },
              validateStatus: (status) => status! < 500, // Allow 4xx responses
            ),
          );
        } catch (e) {
          // Silent error handling
        }
      }
      
      await _clearAuthData();
      _stopRefreshTimer();
      _navigateToLogin();
    } catch (e) {
      _navigateToLogin();
    }
  }

  Future<bool> verifyToken() async {
    try {
      final token = await accessToken;
      if (token == null) return false;

      // Use HttpClientManager for consistent timeout handling
      final httpManager = HttpClientManager.instance;
      final dio = httpManager.dioClient;

      final response = await dio.get(
        AppConstants.authVerifyEndpoint,
        options: Options(
          headers: await getHeaders(),
          validateStatus: (status) => status! < 500, // Allow 4xx responses
        ),
      );

      if (response.statusCode == 401) {
        // Try to refresh token
        return await refreshAccessToken();
      }

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
