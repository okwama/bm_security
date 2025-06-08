import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:bm_security/utils/auth_config.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileService {
  static const String baseUrl = ApiConfig.baseUrl;

  static String? _getAuthToken() {
    final box = GetStorage();
    final token = box.read('token');
    if (token == null) {
      print('No authentication token found');
    }
    return token;
  }

  static Map<String, String> _headers([String? contentType]) {
    final token = _getAuthToken();
    return {
      'Content-Type': contentType ?? 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = _getAuthToken();
      print(
          'Making profile request with token: ${token != null ? 'Token exists' : 'No token'}');

      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: _headers(),
      );

      print('Profile API Response Status: ${response.statusCode}');
      print('Profile API Response Body: ${response.body}');

      if (response.statusCode == 401) {
        print('Authentication failed - Token may be invalid or expired');
        throw Exception('Session expired. Please login again.');
      }

      if (response.statusCode != 200) {
        print('Failed to fetch profile - Status code: ${response.statusCode}');
        throw Exception('Failed to fetch profile data');
      }

      try {
        final responseData = json.decode(response.body);
        print('Successfully decoded profile response: $responseData');
        return responseData;
      } catch (e) {
        print('Error parsing response: ${response.body}');
        throw Exception('Invalid response from server');
      }
    } catch (e) {
      print('Error fetching profile: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/auth/profile'),
        headers: _headers(),
        body: json.encode(data),
      );

      if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to update profile');
      }

      return json.decode(response.body);
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/profile/password'),
        headers: _headers(),
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      );

      if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to update password');
      }

      return json.decode(response.body);
    } catch (e) {
      print('Error updating password: $e');
      rethrow;
    }
  }

  Future<String> updateProfilePhoto(XFile imageFile) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/profile/photo'),
        headers: await _headers('multipart/form-data'),
        body: await http.MultipartFile.fromPath('photo', imageFile.path),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['photoUrl'] ?? '';
      } else {
        throw Exception('Failed to update profile photo');
      }
    } catch (e) {
      _handleNetworkError(e);
      rethrow;
    }
  }

  void _handleNetworkError(dynamic error) {
    print('Network Error: $error');
    if (error is http.ClientException) {
      print('Connection error: Unable to reach the server');
    } else {
      print('Error: ${error.toString()}');
    }
  }
}
