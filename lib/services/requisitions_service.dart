import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

import 'location_service.dart';

import '../models/request.dart';
import '../models/cash_count.dart';
import '../utils/auth_config.dart';

class RequisitionsService {
  static final RequisitionsService _instance = RequisitionsService._internal();
  factory RequisitionsService() => _instance;
  
  RequisitionsService._internal();

  http.Client? _client;
  final String _baseUrl = ApiConfig.baseUrl;
  final _storage = GetStorage();
  
  // Track active requests to prevent client closure during operations
  final Set<String> _activeRequests = <String>{};
  bool _isDisposed = false;

  http.Client get client {
    if (_client == null || _isDisposed) {
      _client = http.Client();
      _isDisposed = false;
    }
    return _client!;
  }

  String? _getAuthToken() {
    final token = _storage.read('token');
    if (token == null) {
      print('No authentication token found');
      throw Exception('Authentication required. Please login again.');
    }
    return token;
  }

  Map<String, String> _getHeaders() {
    try {
      final token = _getAuthToken();
      return {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } catch (e) {
      print('Error getting auth headers: $e');
      rethrow;
    }
  }

  Future<List<Request>> getPendingRequests() async {
    final requestId = 'getPendingRequests_${DateTime.now().millisecondsSinceEpoch}';
    _activeRequests.add(requestId);
    
    try {
      print('Fetching pending requests...');
      final response = await client.get(
        Uri.parse('$_baseUrl/requests/pending'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Fetched ${data.length} pending requests');

        return data.map((item) {
          try {
            final Map<String, dynamic> requestData =
                Map<String, dynamic>.from(item);

            requestData['ServiceType'] = requestData['ServiceType'];
            requestData['serviceTypeId'] = requestData['serviceTypeId'];
            requestData['priority'] ??= 'medium';

            return Request.fromJson(requestData);
          } catch (e, stackTrace) {
            print('Error parsing request item:');
            print('Item data: $item');
            print('Error: $e');
            print('Stack trace: $stackTrace');
            rethrow;
          }
        }).toList();
      } else {
        final error =
            'Failed to load pending requests: ${response.statusCode} - ${response.body}';
        print(error);
        throw Exception(error);
      }
    } catch (e, stackTrace) {
      print('Error in getPendingRequests:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Error fetching pending requests: $e');
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  Future<Request> getRequestDetails(int requestId) async {
    final reqId = 'getRequestDetails_${requestId}_${DateTime.now().millisecondsSinceEpoch}';
    _activeRequests.add(reqId);
    
    try {
      print('Fetching request details for ID: $requestId');
      final response = await client.get(
        Uri.parse('$_baseUrl/requests/$requestId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('Raw response data: $data');

        dynamic serviceTypeData = data['ServiceType'];
        print('Service type data: $serviceTypeData');

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
        print('Formatted request data: $formattedData');

        final request = Request.fromJson(formattedData);
        print(
            'Created request object. serviceType: ${request.serviceType}, serviceTypeId: ${request.serviceTypeId}');
        return request;
      } else {
        final error =
            'Failed to load request details: ${response.statusCode} - ${response.body}';
        print(error);
        throw Exception(error);
      }
    } catch (e, stackTrace) {
      print('Error in getRequestDetails:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Error fetching request details: $e');
    } finally {
      _activeRequests.remove(reqId);
    }
  }

  Future<Request> completeRequisition(int requestId) async {
    final reqId = 'completeRequisition_${requestId}_${DateTime.now().millisecondsSinceEpoch}';
    _activeRequests.add(reqId);
    
    try {
      print('Starting completeRequisition for requestId: $requestId');
      final headers = _getHeaders();
      
      // Stop location tracking for this request
      try {
        final locationService = LocationService();
        await locationService.stopTrackingForRequest(requestId.toString());
        print('Stopped location tracking for request: $requestId');
      } catch (e) {
        print('Error stopping location tracking: $e');
        // Continue with completion even if stopping tracking fails
      }
      
      final response = await client.put(
        Uri.parse('$_baseUrl/requests/$requestId/complete'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Request.fromJson(data);
      } else {
        throw Exception('Failed to complete requisition: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in completeRequisition: $e');
      rethrow;
    } finally {
      _activeRequests.remove(reqId);
    }
  }

  Future<Request> confirmPickup(
    int requestId, {
    CashCount? cashCount,
    String? imageUrl,
  }) async {
    final reqId = 'confirmPickup_${requestId}_${DateTime.now().millisecondsSinceEpoch}';
    _activeRequests.add(reqId);
    
    try {
      print('Starting confirmPickup for requestId: $requestId');
      final headers = _getHeaders();
      headers['Content-Type'] = 'application/json';

      final Map<String, dynamic> body = {};

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
        print('Cash count details: ${jsonEncode(body['cashCount'])}');
      }

      if (imageUrl != null) {
        body['imageUrl'] = imageUrl;
        print('Including image URL in request');
      }

      print('Sending confirm pickup request to: $_baseUrl/requests/$requestId/pickup');
      print('Request body: ${jsonEncode(body)}');

      final uri = Uri.parse('$_baseUrl/requests/$requestId/pickup');
      print('Full request URI: $uri');

      // Create a completer to handle the response properly
      final Completer<http.Response> completer = Completer<http.Response>();
      
      // Make the request with proper error handling
      client.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 60)).then((response) {
        if (!completer.isCompleted) {
          completer.complete(response);
        }
      }).catchError((error) {
        print('Request error: $error');
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      });

      // Wait for response or handle timeout gracefully
      http.Response response;
      try {
        response = await completer.future;
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      } catch (e) {
        print('Request failed with error: $e');
        
        // Check if operation succeeded despite client error
        await Future.delayed(Duration(seconds: 2)); // Give server time to complete
        
        try {
          final verifyResponse = await _verifyRequestStatus(requestId);
          if (verifyResponse != null) {
            print('Operation succeeded despite client error');
            return verifyResponse;
          }
        } catch (verifyError) {
          print('Could not verify request status: $verifyError');
        }
        
        // Re-throw original error if verification fails
        if (e.toString().contains('AbortError') || e.toString().contains('Client is already closed')) {
          throw Exception('Request was interrupted but may have completed successfully. Please refresh to check the status.');
        } else {
          rethrow;
        }
      }

      // Parse successful response
      if (response.body.isEmpty) {
        throw Exception('Empty response from server');
      }

      dynamic responseBody;
      try {
        responseBody = jsonDecode(response.body);
      } catch (e) {
        print('Failed to parse JSON response: ${response.body}');
        throw Exception('Invalid JSON response from server');
      }

      if (response.statusCode != 200) {
        final errorMessage = responseBody is Map
            ? (responseBody['message'] ?? 'Failed to confirm pickup')
            : 'Server returned status code ${response.statusCode}';
        print('Error response: $errorMessage');
        throw Exception(errorMessage);
      }

      if (responseBody is! Map<String, dynamic>) {
        throw Exception('Invalid server response format');
      }

      final requestData = responseBody['data'] ?? responseBody;
      
      if (requestData is! Map<String, dynamic>) {
        throw Exception('Invalid request data format in response');
      }

      if (!requestData.containsKey('id')) {
        throw Exception('Response missing required request ID');
      }

      return Request.fromJson(requestData);
      
    } catch (e, stackTrace) {
      print('Error in confirmPickup: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    } finally {
      _activeRequests.remove(reqId);
    }
  }

  // Helper method to verify request status
  Future<Request?> _verifyRequestStatus(int requestId) async {
    try {
      // Create a new client for verification to avoid closed client issues
      final verifyClient = http.Client();
      final response = await verifyClient.get(
        Uri.parse('$_baseUrl/requests/$requestId'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      verifyClient.close();
      
      if (response.statusCode == 200) {
        final requestData = jsonDecode(response.body);
        if (requestData['status'] == 'in_progress') {
          return Request.fromJson(requestData);
        }
      }
    } catch (e) {
      print('Verification request failed: $e');
    }
    return null;
  }

  Future<List<Request>> getAllStaffRequests() async {
    final requestId = 'getAllStaffRequests_${DateTime.now().millisecondsSinceEpoch}';
    _activeRequests.add(requestId);
    
    try {
      final response = await client.get(
        Uri.parse('$_baseUrl/requests/all'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Request.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load staff requests: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching staff requests: $e');
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  Future<List<Request>> getMyAssignedRequests() async {
    final requestId = 'getMyAssignedRequests_${DateTime.now().millisecondsSinceEpoch}';
    _activeRequests.add(requestId);
    
    try {
      final response = await client.get(
        Uri.parse('$_baseUrl/requests/pending'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Request.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else if (response.statusCode == 403) {
        throw Exception(
            'Forbidden: You do not have permission to view these requests');
      } else {
        throw Exception(
            'Failed to load assigned requests: ${response.statusCode}');
      }
    } on http.ClientException {
      throw Exception('Network error: Please check your internet connection');
    } catch (e) {
      throw Exception('Error fetching assigned requests: $e');
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  Future<List<Request>> getInProgressRequests() async {
    final requestId = 'getInProgressRequests_${DateTime.now().millisecondsSinceEpoch}';
    _activeRequests.add(requestId);
    
    try {
      final url = '$_baseUrl/requests/in-progress';
      print('Fetching in-progress requests from: $url');
      
      final response = await client.get(
        Uri.parse(url),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          return data.map((json) => Request.fromJson(json)).toList();
        } catch (e) {
          print('Error parsing response: $e');
          rethrow;
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else if (response.statusCode == 403) {
        throw Exception('Forbidden: You do not have permission to view these requests');
      } else {
        throw Exception('Failed to load in-progress requests: ${response.statusCode} - ${response.body}');
      }
    } on http.ClientException catch (e) {
      print('HTTP Client Exception: $e');
      throw Exception('Network error: ${e.message}');
    } on SocketException catch (e) {
      print('Socket Exception: $e');
      throw Exception('Cannot connect to server. Please check your internet connection and try again.');
    } on TimeoutException {
      print('Request timed out');
      throw Exception('Connection timed out. Please check your internet connection and try again.');
    } catch (e, stackTrace) {
      print('Error in getInProgressRequests: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  // Safe dispose method
  void dispose() {
    if (_activeRequests.isNotEmpty) {
      print('Warning: Disposing service with ${_activeRequests.length} active requests');
      print('Active requests: $_activeRequests');
      // Don't close client if there are active requests
      return;
    }
    
    _client?.close();
    _client = null;
    _isDisposed = true;
  }

  // Force dispose (use with caution)
  void forceDispose() {
    _activeRequests.clear();
    _client?.close();
    _client = null;
    _isDisposed = true;
  }
}