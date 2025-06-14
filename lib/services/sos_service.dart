import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:bm_security/utils/auth_config.dart';
import 'package:bm_security/services/api_service.dart';

class SosService {
  static const String baseUrl = '${ApiConfig.baseUrl}/api';

  static String? _getAuthtoken() {
    final box = GetStorage();
    final token = box.read('token');
    if (token == null) {
      print('No authentication token found');
    }
    return token;
  }

  static Map<String, String> _headers([String? additionalContentType]) {
    final token = _getAuthtoken();
    return {
      'Content-Type': additionalContentType ?? 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<void> sendSOS({
    required double latitude,
    required double longitude,
    required String distressType,
  }) async {
    try {
      final apiService = ApiService();
      final Map<String, dynamic> sosData = {
        'latitude': latitude,
        'longitude': longitude,
        'sos_type': distressType,
      };

      print('Sending SOS alert to: $baseUrl/sos');
      print('SOS data: ${jsonEncode(sosData)}');

      final response = await apiService.makeAuthenticatedRequest(
        'POST',
        '/sos',
        body: sosData,
      );

      print('SOS response status: ${response.statusCode}');
      print('SOS response body: ${response.body}');

      if (response.statusCode != 201) {
        final errorMessage = response.body.isNotEmpty
            ? 'Failed to send SOS alert: ${response.body}'
            : 'Failed to send SOS alert: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error sending SOS alert: $e');
      rethrow;
    }
  }
}
