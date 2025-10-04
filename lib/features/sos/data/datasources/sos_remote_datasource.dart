import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../services/http/auth_service.dart';

abstract class SOSRemoteDataSource {
  Future<bool> sendSOS({
    required double latitude,
    required double longitude,
    required String distressType,
  });
}

class SOSRemoteDataSourceImpl implements SOSRemoteDataSource {
  final http.Client client;
  final AuthService _authService = AuthService();

  SOSRemoteDataSourceImpl({required this.client}); // Fixed auth token issue

  @override
  Future<bool> sendSOS({
    required double latitude,
    required double longitude,
    required String distressType,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('${AppConstants.baseUrl}/sos'),
        headers: {
          AppConstants.contentTypeHeader: AppConstants.applicationJson,
          AppConstants.authorizationHeader: AppConstants.getBearerToken(await _getTokenFromStorage()),
        },
        body: json.encode({
          'latitude': latitude,
          'longitude': longitude,
          'sos_type': distressType,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw ServerException(message: 'Failed to send SOS: ${response.statusCode}');
      }
    } catch (e) {
      throw ServerException(message: 'Network error: $e');
    }
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

