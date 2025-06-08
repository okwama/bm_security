import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:bm_security/utils/auth_config.dart';

class ApiService {
  static const String baseUrl = ApiConfig.baseUrl;
  final storage = GetStorage();

  static Future<Map<String, dynamic>> login(
      String emplNo, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'emplNo': emplNo,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Store token and user data
        final storage = GetStorage();
        storage.write('token', data['token']);
        storage.write('user', data['user']);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<void> logout() async {
    final storage = GetStorage();
    await storage.remove('token');
    await storage.remove('user');
  }
}
