// File: services/requisitions/request_updater.dart
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../http/http_client_manager.dart';
import '../http/auth_service.dart';
import '../location_service.dart';
import '../../models/request.dart';
import '../../models/cash_count.dart';
import '../../utils/auth_config.dart';
import 'package:flutter/material.dart';

class RequestUpdater {
  final HttpClientManager _httpManager = HttpClientManager.instance;
  final AuthService _authService = AuthService();
  final String _baseUrl = ApiConfig.baseUrl;
  final TextEditingController _sealNumberController = TextEditingController();
  final TextEditingController _bankDetailsController = TextEditingController();
  final TextEditingController _receivingOfficerNameController =
      TextEditingController();
  final TextEditingController _receivingOfficerIdController =
      TextEditingController();

  Future<Request> confirmPickup(
    int requestId, {
    CashCount? cashCount,
    String? imageUrl,
    required String sealNumber,
    double? latitude,
    double? longitude,
  }) async {
    final reqId = _generateRequestId('confirmPickup_$requestId');
    _httpManager.addActiveRequest(reqId);

    // Prepare request body outside try block for retry access
    final body = {
      'cashCount': cashCount?.toJson(),
      'imageUrl': imageUrl,
      'sealNumber': sealNumber,
      'latitude': latitude,
      'longitude': longitude,
    };

    try {

      final headers = await _authService.getHeaders();
      // Get Dio instance safely
      final dio = _httpManager.dioClient;

      // Single attempt with optimized timeout
      final response = await dio.post(
        '/requests/$requestId/pickup',
        data: body,
        options: Options(
          headers: headers,
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      return _parsePickupResponse(response.data, requestId);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Single retry with token refresh
        await _authService.refreshAccessToken();
        final newHeaders = await _authService.getHeaders();
        final dio = _httpManager.dioClient;

        final retryResponse = await dio.post(
          '/requests/$requestId/pickup',
          data: body,
          options: Options(
            headers: newHeaders,
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          ),
        );

        return _parsePickupResponse(retryResponse.data, requestId);
      }
      rethrow;
    } catch (e, stackTrace) {
      if (e is DioException) {
      }
      rethrow;
    } finally {
      _httpManager.removeActiveRequest(reqId);
    }
  }

  Future<Request> assignToVaultOfficer(
      int requestId, int vaultOfficerId, String vaultOfficerName) async {
    final requestIdStr = _generateRequestId('assignToVaultOfficer_$requestId');
    _httpManager.addActiveRequest(requestIdStr);

    try {
      final headers = await _authService.getHeaders();
      final response = await _httpManager.client.post(
        Uri.parse('$_baseUrl/requests/$requestId/assign-vault-officer'),
        headers: headers,
        body: jsonEncode({
          'vaultOfficerId': vaultOfficerId,
          'vaultOfficerName': vaultOfficerName,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return Request.fromJson(responseData);
      } else {
        final error =
            'Failed to assign vault officer: ${response.statusCode} - ${response.body}';
        throw Exception(error);
      }
    } catch (e, stackTrace) {
      _logError('assignToVaultOfficer', e, stackTrace);
      throw Exception('Error assigning vault officer: $e');
    } finally {
      _httpManager.removeActiveRequest(requestIdStr);
    }
  }

  Future<Request> confirmDelivery(
    int requestId, {
    Map<String, dynamic>? bankDetails,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    final reqId = _generateRequestId('confirmDelivery_$requestId');
    _httpManager.addActiveRequest(reqId);

    try {

      final headers = await _authService.getHeaders();
      final body = {
        'bankDetails': bankDetails,
        'latitude': latitude,
        'longitude': longitude,
        'notes': notes,
      };
      // Get Dio instance safely
      final dio = _httpManager.dioClient;

      try {
        final response = await dio.post(
          '/requests/$requestId/delivery',
          data: body,
          options: Options(headers: headers),
        );

            'Delivery confirmation response received: ${response.statusCode}');

        if (response.statusCode != 200) {
          throw Exception(
              'Failed to confirm delivery: ${response.statusCode} - ${response.data}');
        }

        // Parse the response
        final responseData = response.data;
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('data')) {
          return Request.fromJson(responseData['data']);
        } else {
          return Request.fromJson(responseData);
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          // Try to refresh token and retry
          await _authService.refreshAccessToken();
          final newHeaders = await _authService.getHeaders();

          final retryResponse = await dio.post(
            '/requests/$requestId/delivery',
            data: body,
            options: Options(headers: newHeaders),
          );

          if (retryResponse.statusCode != 200) {
            throw Exception(
                'Failed to confirm delivery: ${retryResponse.statusCode} - ${retryResponse.data}');
          }

          final responseData = retryResponse.data;
          if (responseData is Map<String, dynamic> &&
              responseData.containsKey('data')) {
            return Request.fromJson(responseData['data']);
          } else {
            return Request.fromJson(responseData);
          }
        }
        rethrow;
      }
    } catch (e, stackTrace) {
      if (e is DioException) {
      }
      rethrow;
    } finally {
      _httpManager.removeActiveRequest(reqId);
    }
  }

  // Helper methods
  String _generateRequestId(String operation) {
    return '${operation}_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _stopLocationTracking(String requestId) async {
    try {
      final locationService = LocationService();
      await locationService.stopTrackingForRequest(requestId);
    } catch (e) {
    }
  }

  // Parse the completion response
  Request _parseCompletionResponse(dynamic response, bool isVaultDelivery) {
    try {

      if (response is Map<String, dynamic>) {
        return Request.fromJson(response);
      } else if (response is String) {
        return Request.fromJson(jsonDecode(response));
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e, stackTrace) {
      throw Exception(
          'Failed to parse ${isVaultDelivery ? 'vault delivery' : 'requisition'} completion response');
    }
  }

  // Build the pickup request body
  Map<String, dynamic> _buildPickupRequestBody(
      CashCount? cashCount, String? imageUrl) {
    final body = <String, dynamic>{};

    if (cashCount != null) {
      body['cashCount'] = {
        'ones': cashCount.ones,
        'fives': cashCount.fives,
        'tens': cashCount.tens,
        'twenties': cashCount.twenties,
        'forties': cashCount.forties,
        'fifties': cashCount.fifties,
        'hundreds': cashCount.hundreds,
        'twoHundreds': cashCount.twoHundreds,
        'fiveHundreds': cashCount.fiveHundreds,
        'thousands': cashCount.thousands,
        'sealNumber': cashCount.sealNumber,
      };
    }

    if (imageUrl != null) {
      body['imageUrl'] = imageUrl;
    }

    return body;
  }

  // Parse the pickup response
  Request _parsePickupResponse(dynamic response, int requestId) {
    try {

      if (response is Map<String, dynamic>) {
        if (response.containsKey('data')) {
          return Request.fromJson(response['data']);
        } else {
          return Request.fromJson(response);
        }
      } else if (response is String) {
        final decoded = jsonDecode(response);
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          return Request.fromJson(decoded['data']);
        } else {
          return Request.fromJson(decoded);
        }
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e, stackTrace) {
      throw Exception('Failed to parse pickup response');
    }
  }

  void _logError(String operation, dynamic error, StackTrace stackTrace) {
  }
}
