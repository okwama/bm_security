import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bm_security/utils/auth_config.dart';
import '../core/constants/app_constants.dart';

class StaffService {
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

  static Future<Map<String, dynamic>> addStaff({
    required String name,
    required String phone,
    required String employeeNumber,
    required String idNumber,
    required String role,
    File? photoFile,
  }) async {
    try {
      final token = await _getAuthtoken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/teams/add-staff'),
      );

      // Add headers (no authentication required for add-staff)
      request.headers.addAll({
        'Accept': AppConstants.applicationJson,
      });

      // Add text fields
      request.fields['name'] = name;
      request.fields['phone'] = phone;
      request.fields['employeeNumber'] = employeeNumber;
      request.fields['idNumber'] = idNumber; // Send as string
      request.fields['role'] = role;

      // Add photo file if provided
      if (photoFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'photo',
            photoFile.path,
            filename: 'staff_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      }

      print('Adding staff to: $baseUrl/teams/add-staff');
      print('Staff data: name=$name, phone=$phone, employeeNumber=$employeeNumber, role=$role');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Staff response status: ${response.statusCode}');
      print('Staff response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorMessage = response.body.isNotEmpty
            ? 'Failed to add staff: ${response.body}'
            : 'Failed to add staff: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error adding staff: $e');
      rethrow;
    }
  }
}