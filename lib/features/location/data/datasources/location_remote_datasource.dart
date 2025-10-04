import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../services/http/auth_service.dart';
import '../models/location_model.dart';

abstract class LocationRemoteDataSource {
  Future<void> updateLocation({
    required int requestId,
    required double latitude,
    required double longitude,
  });

  Future<List<LocationModel>> getLocationHistory({
    required int requestId,
  });
}

class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  final Dio dio;
  final AuthService _authService = AuthService();

  LocationRemoteDataSourceImpl({required this.dio});

  @override
  Future<void> updateLocation({
    required int requestId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await dio.post(
        '${AppConstants.baseUrl}/location/update',
        data: {
          'requestId': requestId,
          'latitude': latitude,
          'longitude': longitude,
        },
        options: Options(
          headers: {
            AppConstants.contentTypeHeader: AppConstants.applicationJson,
            AppConstants.authorizationHeader: AppConstants.getBearerToken(await _getTokenFromStorage()),
          },
        ),
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to update location',
          code: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw ServerException(
          message: e.response?.data['message'] ?? 'Network error occurred',
          code: e.response?.statusCode,
        );
      } else {
        throw ServerException(message: 'Network error occurred');
      }
    }
  }

  @override
  Future<List<LocationModel>> getLocationHistory({
    required int requestId,
  }) async {
    try {
      final response = await dio.get(
        '${AppConstants.baseUrl}/location/history/$requestId',
        options: Options(
          headers: {
            AppConstants.contentTypeHeader: AppConstants.applicationJson,
            AppConstants.authorizationHeader: AppConstants.getBearerToken(await _getTokenFromStorage()),
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = response.data;
        return jsonList.map((json) => LocationModel.fromJson(json)).toList();
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to fetch location history',
          code: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw ServerException(
          message: e.response?.data['message'] ?? 'Network error occurred',
          code: e.response?.statusCode,
        );
      } else {
        throw ServerException(message: 'Network error occurred');
      }
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
