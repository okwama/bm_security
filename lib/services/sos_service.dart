import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bm_security/utils/auth_config.dart';
import 'package:bm_security/services/api_service.dart';
import '../core/constants/app_constants.dart';

class SosService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<String?> _getAuthtoken() async {
    final box = const FlutterSecureStorage();
    final token = await box.read(key: 'token');
    if (token == null) {
      print('No authentication token found');
    }
    return token;
  }

  static Future<Map<String, String>> _headers([String? additionalContentType]) async {
    final token = await _getAuthtoken();
    return {
      AppConstants.contentTypeHeader: additionalContentType ?? AppConstants.applicationJson,
      'Accept': AppConstants.applicationJson,
      if (token != null) AppConstants.authorizationHeader: AppConstants.getBearerToken(token),
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
