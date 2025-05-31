  import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:bm_security/utils/auth_config.dart';

class SosService {
  static const String baseUrl = '${ApiConfig.baseUrl}/api';

    static String? _getAuthToken() {
    final box = GetStorage();
    final token = box.read('token');
    if (token == null) {
      print('No authentication token found');
    }
    return token;
  }
    
  static Map<String, String> _headers([String? additionalContentType]) {
    final token = _getAuthToken();
    return {
      'Content-Type': additionalContentType ?? 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  
  static Future<void> sendSOS({
    required int userId,
    required String userName,
    required String userPhone,
    required String distressType,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      final token = _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }




      // Create the SOS data to match server expectations
      final Map<String, dynamic> sosData = {
        'userId': userId,
        'userName': userName,
        'userPhone': userPhone,
        'distressType': distressType,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'status': 'active',
      };

      print('Sending SOS alert to: $baseUrl/sos');
      print('SOS data: ${jsonEncode(sosData)}');

      // The API route is mounted at /api/sos in the server
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/sos'),
        headers: _headers(), // Use the standard headers method for consistency
        body: jsonEncode(sosData),
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
