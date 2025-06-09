// File: services/requisitions/request_updater.dart
import 'dart:async';
import 'dart:convert';
import '../http/http_client_manager.dart';
import '../http/auth_service.dart';
import '../location_service.dart';
import '../../models/request.dart';
import '../../models/cash_count.dart';
import '../../utils/auth_config.dart';
import 'package:flutter/material.dart';

class RequestUpdater {
  final HttpClientManager _httpManager = HttpClientManager();
  final AuthService _authService = AuthService();
  final String _baseUrl = ApiConfig.baseUrl;
  final TextEditingController _sealNumberController = TextEditingController();
  final TextEditingController _bankDetailsController = TextEditingController();
  final TextEditingController _receivingOfficerNameController =
      TextEditingController();
  final TextEditingController _receivingOfficerIdController =
      TextEditingController();

  Future<Request> completeRequisition(
    String requestId, {
    bool isVaultDelivery = false,
    String? photoUrl,
    Map<String, dynamic>? bankDetails,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    final reqId = _generateRequestId('completeRequisition_$requestId');
    _httpManager.addActiveRequest(reqId);

    try {
      print('=== RequestUpdater: Complete Requisition Debug ===');
      print('Input requestId type: ${requestId.runtimeType}');
      print('Input requestId value: $requestId');
      print('isVaultDelivery: $isVaultDelivery');

      await _stopLocationTracking(requestId);

      final headers = _authService.getHeaders();
      final response = isVaultDelivery
          ? await _completeVaultDelivery(requestId, headers, photoUrl,
              bankDetails, latitude, longitude, notes)
          : await _completeStandardRequisition(requestId, headers);

      print('=== RequestUpdater: Response Debug ===');
      print('Response type: ${response.runtimeType}');
      print('Response data: $response');

      return _parseCompletionResponse(response, isVaultDelivery);
    } catch (e, stackTrace) {
      print('=== RequestUpdater: Complete Requisition Error ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    } finally {
      _httpManager.removeActiveRequest(reqId);
    }
  }

  Future<Request> confirmPickup(
    int requestId, {
    CashCount? cashCount,
    String? imageUrl,
  }) async {
    final reqId = _generateRequestId('confirmPickup_$requestId');
    _httpManager.addActiveRequest(reqId);

    try {
      print('Starting confirmPickup for requestId: $requestId');
      final headers = _authService.getHeaders();
      final body = _buildPickupRequestBody(cashCount, imageUrl);

      final response = await _executePickupRequest(requestId, headers, body);
      return _parsePickupResponse(response, requestId);
    } catch (e, stackTrace) {
      print('Error in confirmPickup: $e');
      print('Stack trace: $stackTrace');
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
      print('Assigning request $requestId to vault officer $vaultOfficerId');
      final response = await _httpManager.client.post(
        Uri.parse('$_baseUrl/requests/$requestId/assign-vault-officer'),
        headers: _authService.getHeaders(),
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
        print(error);
        throw Exception(error);
      }
    } catch (e, stackTrace) {
      _logError('assignToVaultOfficer', e, stackTrace);
      throw Exception('Error assigning vault officer: $e');
    } finally {
      _httpManager.removeActiveRequest(requestIdStr);
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
      print('Stopped location tracking for request: $requestId');
    } catch (e) {
      print('Error stopping location tracking: $e');
    }
  }

  // Complete a standard requisition (non-vault delivery)
  Future<dynamic> _completeStandardRequisition(
    String requestId,
    Map<String, String> headers,
  ) async {
    print('=== Standard Requisition Debug ===');
    print('Request ID type: ${requestId.runtimeType}');
    print('Request ID value: $requestId');

    final body = {
      'status': 'completed',
    };

    print('Request body: $body');

    final response = await _httpManager.client.post(
      Uri.parse('$_baseUrl/requests/$requestId/complete'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      print('=== Standard Requisition Error ===');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception(
          'Failed to complete requisition: ${response.statusCode} - ${response.body}');
    }

    final responseData = jsonDecode(response.body);
    print('Response data type: ${responseData.runtimeType}');
    print('Response data: $responseData');
    return responseData;
  }

  // Complete a vault delivery
  Future<dynamic> _completeVaultDelivery(
    String requestId,
    Map<String, String> headers,
    String? photoUrl,
    Map<String, dynamic>? bankDetails,
    double? latitude,
    double? longitude,
    String? notes,
  ) async {
    print('=== Vault Delivery Debug ===');
    print('Request ID type: ${requestId.runtimeType}');
    print('Request ID value: $requestId');
    print('Photo URL: $photoUrl');
    print('Bank Details: $bankDetails');
    print('Latitude: $latitude');
    print('Longitude: $longitude');
    print('Notes: $notes');

    if (photoUrl == null ||
        bankDetails == null ||
        latitude == null ||
        longitude == null) {
      throw Exception('Missing required parameters for vault delivery');
    }

    final body = {
      'status': 'completed',
      'photoUrl': photoUrl,
      'bankDetails': bankDetails,
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
    };

    print('Request body: $body');

    final response = await _httpManager.client.post(
      Uri.parse('$_baseUrl/requests/$requestId/complete-vault-delivery'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      print('=== Vault Delivery Error ===');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception(
          'Failed to complete vault delivery: ${response.statusCode} - ${response.body}');
    }

    return jsonDecode(response.body);
  }

  // Parse the completion response
  Request _parseCompletionResponse(dynamic response, bool isVaultDelivery) {
    try {
      print('=== Parse Completion Response Debug ===');
      print('Response type: ${response.runtimeType}');
      print('Response data: $response');

      if (response is Map<String, dynamic>) {
        return Request.fromJson(response);
      } else if (response is String) {
        return Request.fromJson(jsonDecode(response));
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e, stackTrace) {
      print('=== Parse Completion Response Error ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      throw Exception(
          'Failed to parse ${isVaultDelivery ? 'vault delivery' : 'requisition'} completion response');
    }
  }

  // Log errors consistently
  void _logError(String operation, dynamic error, StackTrace stackTrace) {
    print('Error in $operation: $error');
    print('Stack trace: $stackTrace');
  }

  // Build request body for pickup confirmation
  Map<String, dynamic> _buildPickupRequestBody(
      CashCount? cashCount, String? imageUrl) {
    final body = <String, dynamic>{};

    if (cashCount != null) {
      body['cashCount'] = cashCount.toJson();
    }

    if (imageUrl != null) {
      body['imageUrl'] = imageUrl;
    }

    return body;
  }

  // Execute pickup request
  Future<dynamic> _executePickupRequest(int requestId,
      Map<String, String> headers, Map<String, dynamic> body) async {
    final response = await _httpManager.client.post(
      Uri.parse('$_baseUrl/requests/$requestId/confirm-pickup'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to confirm pickup: ${response.statusCode} - ${response.body}');
    }

    return jsonDecode(response.body);
  }

  // Parse pickup response
  Request _parsePickupResponse(dynamic response, int requestId) {
    try {
      return Request.fromJson(response);
    } catch (e, stackTrace) {
      _logError('parsePickupResponse', e, stackTrace);
      throw Exception(
          'Failed to parse pickup confirmation response for request $requestId');
    }
  }
}
