// File: services/http/auth_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import '../../utils/auth_config.dart';
import '../../utils/navigation.dart';
import 'package:get/get.dart';

class AuthService extends GetxService {
  static final AuthService _instance = AuthService._internal();
  final GetStorage _storage = GetStorage();
  final String _baseUrl = ApiConfig.baseUrl;
  Timer? _refreshTimer;
  bool _isRefreshing = false;

  // token refresh interval (15 minutes)
  static const _refreshInterval = Duration(minutes: 15);

  // Token keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  // Get stored access token
  String? get accessToken => _storage.read(_accessTokenKey);

  // Get stored refresh token
  String? get refreshToken => _storage.read(_refreshTokenKey);

  // Get stored user data
  Map<String, dynamic>? get userData => _storage.read(_userKey);

  // Check if user is logged in
  bool get isLoggedIn => accessToken != null;

  factory AuthService() {
    return _instance;
  }

  AuthService._internal() {
    print('🔐 AuthService initialized');
    print('🌐 Using base URL: $_baseUrl');
  }

  Future<String?> gettoken() async {
    try {
      final token = _storage.read(_accessTokenKey);
      if (token != null) {
        print('🔑 Token retrieval attempt: Token found');
        print('📝 Token value: ${token.substring(0, 10)}...');
        return token;
      } else {
        print('🔑 Token retrieval attempt: No token found');
        return null;
      }
    } catch (e) {
      print('❌ Error retrieving token: $e');
      return null;
    }
  }

  Future<void> settoken(String token) async {
    try {
      print('💾 Storing token: ${token.substring(0, 10)}...');
      await _storage.write(_accessTokenKey, token);
      // Also store under 'token' key for backward compatibility
      await _storage.write('token', token);
      print('✅ Token stored successfully');
      _startRefreshTimer();
    } catch (e) {
      print('❌ Error storing token: $e');
      throw Exception('Failed to store token');
    }
  }

  Future<void> cleartoken() async {
    try {
      await _storage.remove(_accessTokenKey);
      // Also clear 'token' key for backward compatibility
      await _storage.remove('token');
      print('🗑️ Token cleared successfully');
    } catch (e) {
      print('❌ Error clearing token: $e');
    }
  }

  Future<Map<String, String>> getHeaders() async {
    final token = accessToken;
    if (token == null) {
      print('! No token available for request');
      return {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> saveAuthData(Map<String, dynamic> data) async {
    try {
      if (data['accessToken'] != null) {
        await _storage.write(_accessTokenKey, data['accessToken']);
      }
      if (data['refreshToken'] != null) {
        await _storage.write(_refreshTokenKey, data['refreshToken']);
      }
      if (data['user'] != null) {
        await _storage.write(_userKey, data['user']);
      }

      // Store device info and IP if available
      if (data['deviceInfo'] != null) {
        await _storage.write('device_info', data['deviceInfo']);
      }
      if (data['ipAddress'] != null) {
        await _storage.write('ip_address', data['ipAddress']);
      }

      await settoken(data['accessToken'] ?? '');
      _startRefreshTimer();
    } catch (e) {
      print('❌ Error saving auth data: $e');
      throw Exception('Failed to save authentication data');
    }
  }

  Future<void> _clearAuthData() async {
    try {
      await _storage.remove(_accessTokenKey);
      await _storage.remove(_refreshTokenKey);
      await _storage.remove(_userKey);
      // Also clear 'token' key for backward compatibility
      await _storage.remove('token');
      await cleartoken();
      _stopRefreshTimer();
      print('🗑️ Auth data cleared successfully');
    } catch (e) {
      print('❌ Error clearing auth data: $e');
    }
  }

  Future<void> refreshAccessToken() async {
    if (_isRefreshing) {
      print('🔄 Token refresh already in progress');
      return;
    }
    _isRefreshing = true;
    print('🔄 Starting token refresh');

    try {
      final currentRefreshToken = refreshToken;
      if (currentRefreshToken == null) {
        print('❌ No refresh token available');
        throw Exception('No refresh token available');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'refreshToken': currentRefreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        await saveAuthData(data);
        print('✅ Token refreshed successfully');
      } else {
        print('❌ Token refresh failed with status: ${response.statusCode}');
        await _clearAuthData();
        _navigateToLogin();
        throw Exception('Session expired. Please login again.');
      }
    } catch (e) {
      print('❌ Error refreshing token: $e');
      await _clearAuthData();
      _navigateToLogin();
      throw Exception('Session expired. Please login again.');
    } finally {
      _isRefreshing = false;
    }
  }

  void _startRefreshTimer() {
    _stopRefreshTimer();
    _refreshTimer =
        Timer.periodic(_refreshInterval, (_) => refreshAccessToken());
    print('⏰ Token refresh timer started (interval: $_refreshInterval)');
  }

  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    print('⏰ Token refresh timer stopped');
  }

  void _navigateToLogin() {
    print('🔄 Navigating to login page');
    final context = NavigationService.navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Future<bool> isAuthenticated() async {
    try {
      final token = accessToken;
      if (token == null) {
        print('❌ No token found for authentication check');
        return false;
      }

      print('🔍 Checking token structure...');

      // Only verify token structure locally
      try {
        final parts = token.split('.');
        if (parts.length != 3) {
          print('❌ Invalid token format');
          await _clearAuthData();
          return false;
        }

        // Basic JWT structure validation
        try {
          // Check if header and payload are valid base64
          base64Url.decode(parts[0]);
          base64Url.decode(parts[1]);
          print('✅ Token structure is valid');
          return true;
        } catch (e) {
          print('❌ Invalid token encoding');
          await _clearAuthData();
          return false;
        }
      } catch (e) {
        print('❌ Error validating token structure: $e');
        await _clearAuthData();
        return false;
      }
    } catch (e) {
      print('❌ Error in isAuthenticated: $e');
      return false;
    }
  }

  Future<String> getValidtoken() async {
    final token = await gettoken();
    if (token == null) {
      print('❌ No valid token found');
      _navigateToLogin();
      throw Exception('Authentication required. Please login again.');
    }
    print('✅ Valid token found: ${token.substring(0, 10)}...');
    return token;
  }

  // Login
  Future<Map<String, dynamic>> login(String emplNo, String password) async {
    try {
      print('🔑 Attempting login for user: $emplNo');
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'emplNo': emplNo,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          await saveAuthData({
            'accessToken': data['accessToken'],
            'refreshToken': data['refreshToken'],
            'user': data['user'],
          });
          return data;
        } else {
          throw Exception(data['message'] ?? 'Login failed');
        }
      } else {
        throw Exception(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Register
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await saveAuthData(data);
        return data;
      } else {
        throw Exception(
            jsonDecode(response.body)['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      print('🚪 Logging out...');
      final token = await gettoken();
      if (token != null) {
        try {
          await http.post(
            Uri.parse('$_baseUrl/auth/logout'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
        } catch (e) {
          print('⚠️ Error during logout request: $e');
        }
      }
      await cleartoken();
      _stopRefreshTimer();
      _navigateToLogin();
      print('✅ Logout completed');
    } catch (e) {
      print('❌ Error during logout: $e');
      _navigateToLogin();
    }
  }

  Future<bool> verifyToken() async {
    try {
      final token = accessToken;
      if (token == null) return false;

      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/verify'),
        headers: headers,
      );

      if (response.statusCode == 401) {
        // Try to refresh token
        await refreshAccessToken();
        return true;
      }

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error verifying token: $e');
      return false;
    }
  }
}
