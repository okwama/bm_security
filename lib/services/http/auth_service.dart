// File: services/http/auth_service.dart
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bm_security/utils/auth_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storage = GetStorage();
  bool _isRefreshing = false;
  String? _refreshToken;

  String? getAuthToken() {
    final token = _storage.read('token');
    if (token == null) {
      print('No authentication token found');
      throw Exception('Authentication required. Please login again.');
    }
    return token;
  }

  Future<String> refreshToken() async {
    if (_isRefreshing) {
      // Wait for the ongoing refresh to complete
      while (_isRefreshing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return getAuthToken()!;
    }

    _isRefreshing = true;
    try {
      final refreshToken = _storage.read('refresh_token');
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['token'];
        final newRefreshToken = data['refresh_token'];

        await _storage.write('token', newToken);
        await _storage.write('refresh_token', newRefreshToken);

        return newToken;
      } else {
        throw Exception('Failed to refresh token');
      }
    } catch (e) {
      // If refresh fails, clear all auth data
      await logout();
      throw Exception('Session expired. Please login again.');
    } finally {
      _isRefreshing = false;
    }
  }

  Map<String, String> getHeaders() {
    try {
      final token = getAuthToken();
      return {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } catch (e) {
      print('Error getting auth headers: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.remove('token');
    await _storage.remove('refresh_token');
    await _storage.remove('user');
  }

  Future<bool> isTokenValid() async {
    try {
      final token = getAuthToken();
      if (token == null) return false;

      // Make a test request to validate token
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/validate'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<String> getValidToken() async {
    try {
      if (await isTokenValid()) {
        return getAuthToken()!;
      }
      return await refreshToken();
    } catch (e) {
      throw Exception('Authentication required. Please login again.');
    }
  }
}
