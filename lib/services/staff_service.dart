import 'dart:convert';
import 'package:bm_security/models/staff.dart';
import 'package:http/http.dart' as http;
import 'http/http_client_manager.dart';
import 'package:bm_security/services/http/auth_service.dart';
import 'package:bm_security/utils/auth_config.dart';

class StaffService {
  final String _baseUrl = ApiConfig.baseUrl;
  final HttpClientManager _httpClient = HttpClientManager();
  final AuthService _authService = AuthService();

  Future<List<Staff>> getVaultOfficers() async {
    try {
      final response = await _httpClient.client.get(
        Uri.parse('$_baseUrl/staff/vault-officers'),
        headers: await _authService.getHeaders(),
      );

      print('Vault officers response: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> data = responseData['data'];
          return data.map((json) => Staff.fromJson(json)).toList();
        } else {
          print('Invalid response format: $responseData');
          throw Exception('Invalid response format from server');
        }
      } else {
        print(
            'Vault officers API response: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Failed to load vault officers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getVaultOfficers: $e');
      throw Exception('Error fetching vault officers: $e');
    }
  }
}
