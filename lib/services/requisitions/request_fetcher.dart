
// File: services/requisitions/request_fetcher.dart
import 'dart:convert';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/response/response.dart';
import 'package:http/http.dart' as http_lib;

import '../http/http_client_manager.dart';
import '../http/auth_service.dart';
import '../../models/request.dart';
import '../../utils/auth_config.dart';

class RequestFetcher {
  final HttpClientManager _httpManager = HttpClientManager();
  final AuthService _authService = AuthService();
  final String _baseUrl = ApiConfig.baseUrl;

  Future<List<Request>> getPendingRequests() async {
    final requestId = _generateRequestId('getPendingRequests');
    _httpManager.addActiveRequest(requestId);
    
    try {
      print('Fetching pending requests...');
      final response = await _httpManager.client.get(
        Uri.parse('$_baseUrl/requests/pending'),
        headers: _authService.getHeaders(),
      );

      return _parseRequestListResponse(response, 'pending requests');
    } catch (e, stackTrace) {
      _logError('getPendingRequests', e, stackTrace);
      throw Exception('Error fetching pending requests: $e');
    } finally {
      _httpManager.removeActiveRequest(requestId);
    }
  }

  Future<Request> getRequestDetails(int requestId) async {
    final reqId = _generateRequestId('getRequestDetails_$requestId');
    _httpManager.addActiveRequest(reqId);
    
    try {
      print('Fetching request details for ID: $requestId');
      final response = await _httpManager.client.get(
        Uri.parse('$_baseUrl/requests/$requestId'),
        headers: _authService.getHeaders(),
      );

      return _parseRequestResponse(response, 'request details');
    } catch (e, stackTrace) {
      _logError('getRequestDetails', e, stackTrace);
      throw Exception('Error fetching request details: $e');
    } finally {
      _httpManager.removeActiveRequest(reqId);
    }
  }

  Future<List<Request>> getInProgressRequests() async {
    final requestId = _generateRequestId('getInProgressRequests');
    _httpManager.addActiveRequest(requestId);
    
    try {
      final url = '$_baseUrl/requests/in-progress';
      print('Fetching in-progress requests from: $url');
      
      final response = await _httpManager.client.get(
        Uri.parse(url),
        headers: _authService.getHeaders(),
      ).timeout(const Duration(seconds: 10));

      return _parseRequestListResponse(response, 'in-progress requests');
    } catch (e, stackTrace) {
      _logError('getInProgressRequests', e, stackTrace);
      rethrow;
    } finally {
      _httpManager.removeActiveRequest(requestId);
    }
  }

  Future<List<Request>> getAllStaffRequests() async {
    final requestId = _generateRequestId('getAllStaffRequests');
    _httpManager.addActiveRequest(requestId);
    
    try {
      final response = await _httpManager.client.get(
        Uri.parse('$_baseUrl/requests/all'),
        headers: _authService.getHeaders(),
      );

      return _parseRequestListResponse(response, 'staff requests');
    } catch (e) {
      throw Exception('Error fetching staff requests: $e');
    } finally {
      _httpManager.removeActiveRequest(requestId);
    }
  }

  // Helper methods
  String _generateRequestId(String operation) {
    return '${operation}_${DateTime.now().millisecondsSinceEpoch}';
  }

  List<Request> _parseRequestListResponse(http_lib.Response response, String operation) {
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print('Fetched ${data.length} $operation');

      return data.map((item) {
        try {
          final Map<String, dynamic> requestData = Map<String, dynamic>.from(item);
          requestData['priority'] ??= 'medium';
          return Request.fromJson(requestData);
        } catch (e, stackTrace) {
          print('Error parsing request item: $item');
          print('Error: $e');
          print('Stack trace: $stackTrace');
          rethrow;
        }
      }).toList();
    } else {
      throw _handleHttpError(response, operation);
    }
  }

  Request _parseRequestResponse(http_lib.Response response, String operation) {
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      
      // Handle service type data normalization
      dynamic serviceTypeData = data['ServiceType'];
      if (serviceTypeData == null && data['serviceTypeId'] != null) {
        serviceTypeData = {
          'id': data['serviceTypeId'],
          'name': data['serviceType'] ?? 'Unknown',
        };
      }

      final formattedData = Map<String, dynamic>.from(data);
      if (serviceTypeData != null) {
        formattedData['ServiceType'] = serviceTypeData;
      }
      formattedData['priority'] ??= 'medium';

      return Request.fromJson(formattedData);
    } else {
      throw _handleHttpError(response, operation);
    }
  }

  Exception _handleHttpError(http_lib.Response response, String operation) {
    final error = 'Failed to load $operation: ${response.statusCode} - ${response.body}';
    print(error);
    return Exception(error);
  }

  void _logError(String operation, dynamic error, StackTrace stackTrace) {
    print('Error in $operation:');
    print('Error: $error');
    print('Stack trace: $stackTrace');
  }
}
