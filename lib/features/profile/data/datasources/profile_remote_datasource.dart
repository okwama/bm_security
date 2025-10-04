import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../services/http/auth_service.dart';
import '../../../auth/data/models/user_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserModel> getProfile();
  Future<UserModel> updateProfile({
    String? name,
    String? phone,
    String? photoUrl,
  });
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<String> uploadPhoto(String imagePath);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final http.Client client;
  final String baseUrl;
  final AuthService _authService = AuthService();

  ProfileRemoteDataSourceImpl({
    required this.client,
    String? baseUrl,
  }) : baseUrl = baseUrl ?? AppConstants.baseUrl;

  @override
  Future<UserModel> getProfile() async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/profile'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserModel.fromJson(data as Map<String, dynamic>);
      } else {
        throw ServerException(message: 'Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Network error: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> updateProfile({
    String? name,
    String? phone,
    String? photoUrl,
  }) async {
    try {
      final response = await client.put(
        Uri.parse('$baseUrl/profile'),
        headers: await _getHeaders(),
        body: json.encode({
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (photoUrl != null) 'photo_url': photoUrl,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserModel.fromJson(data as Map<String, dynamic>);
      } else {
        throw ServerException(message: 'Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Network error: ${e.toString()}');
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await client.put(
        Uri.parse('$baseUrl/profile/password'),
        headers: await _getHeaders(),
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode != 200) {
        throw ServerException(message: 'Failed to change password: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Network error: ${e.toString()}');
    }
  }

  @override
  Future<String> uploadPhoto(String imagePath) async {
    try {
      // TODO: Implement file upload to server
      // This would typically use multipart/form-data
      await Future.delayed(const Duration(seconds: 2)); // Simulate upload
      return 'https://example.com/uploaded-photo.jpg';
    } catch (e) {
      throw ServerException(message: 'Failed to upload photo: ${e.toString()}');
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    // Get token from secure storage instead of static AppConstants
    final token = await _getTokenFromStorage();
    return {
      AppConstants.contentTypeHeader: AppConstants.applicationJson,
      AppConstants.authorizationHeader: AppConstants.getBearerToken(token),
    };
  }

  Future<String> _getTokenFromStorage() async {
    try {
      final token = await _authService.accessToken;
      if (token != null && token.isNotEmpty) {
        return token;
      }
      throw Exception('No authentication token available');
    } catch (e) {
      throw Exception('Authentication token retrieval failed: $e');
    }
  }
}
