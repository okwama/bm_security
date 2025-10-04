import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../services/http/auth_service.dart';
import '../models/request_model.dart';

abstract class RequestsRemoteDataSource {
  Future<List<RequestModel>> getRequests({
    int? status,
    int? teamId,
    int? staffId,
  });

  Future<bool> updateRequestStatus({
    required int requestId,
    required int newStatus,
    int? staffId,
    double? latitude,
    double? longitude,
  });
}

class RequestsRemoteDataSourceImpl implements RequestsRemoteDataSource {
  final http.Client client;
  final AuthService _authService = AuthService();

  RequestsRemoteDataSourceImpl({required this.client});

  @override
  Future<List<RequestModel>> getRequests({
    int? status,
    int? teamId,
    int? staffId,
  }) async {
    try {
      // Determine the endpoint based on status
      String endpoint = AppConstants.requestsEndpoint;
      if (status == 1) {
        endpoint = AppConstants.requestsPendingEndpoint;
      } else if (status == 2) {
        endpoint = AppConstants.requestsInProgressEndpoint;
      } else if (status == 3) {
        endpoint = AppConstants.requestsCompletedEndpoint;
      }

          final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');

          final token = await _getTokenFromStorage();
          final bearerToken = AppConstants.getBearerToken(token);
      
      final response = await client.get(
        uri,
        headers: {
          AppConstants.contentTypeHeader: AppConstants.applicationJson,
          AppConstants.authorizationHeader: bearerToken,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => RequestModel.fromJson(json)).toList();
      } else {
        throw ServerException(message: 'Failed to load requests: ${response.statusCode}');
      }
    } catch (e) {
      throw ServerException(message: 'Network error: $e');
    }
  }

  @override
  Future<bool> updateRequestStatus({
    required int requestId,
    required int newStatus,
    int? staffId,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await client.put(
        Uri.parse('${AppConstants.baseUrl}/requests/$requestId/status'),
        headers: {
          AppConstants.contentTypeHeader: AppConstants.applicationJson,
          AppConstants.authorizationHeader: AppConstants.getBearerToken(await _getTokenFromStorage()),
        },
        body: json.encode({
          'newStatus': newStatus,
          'staffId': staffId,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw ServerException(message: 'Failed to update request status: ${response.statusCode}');
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

