import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bm_security/utils/auth_config.dart';
import 'package:bm_security/services/http/auth_service.dart';

class ApiService {
  static const String baseUrl = ApiConfig.baseUrl;
  final _authService = AuthService();

  // Use AuthService for login instead of duplicating logic
  static Future<Map<String, dynamic>> login(
      String emplNo, String password) async {
    try {
      final authService = AuthService();
      final result = await authService.login(emplNo, password);
      return {'success': true, 'data': result};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Use AuthService for logout
  static Future<void> logout() async {
    await AuthService().logout();
  }

  // Helper method to make authenticated requests
  Future<http.Response> makeAuthenticatedRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? additionalHeaders,
  }) async {
    final headers = await _authService.getHeaders();
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    final uri = Uri.parse('$baseUrl$endpoint');

    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(uri, headers: headers);
      case 'POST':
        return await http.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PUT':
        return await http.put(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'DELETE':
        return await http.delete(uri, headers: headers);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }
}
