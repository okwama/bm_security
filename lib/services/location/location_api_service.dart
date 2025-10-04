import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../../utils/auth_config.dart';
import '../http/auth_service.dart';
import '../../core/constants/app_constants.dart';

class LocationApiService {
  static final LocationApiService _instance = LocationApiService._internal();
  factory LocationApiService() => _instance;
  LocationApiService._internal();

  final String _baseUrl = ApiConfig.baseUrl;
  final AuthService _authService = AuthService();

  /// Send location update to server
  Future<Map<String, dynamic>> sendLocationUpdate({
    required String requestId,
    required Position position,
  }) async {
    try {
      debugPrint('🚀 Sending location update for request: $requestId');
      debugPrint('📍 Position: ${position.latitude}, ${position.longitude}');

      // Get auth token
      final authToken = await _authService.gettoken();
      if (authToken == null) {
        throw Exception('No authentication token available');
      }

      final requestBody = {
        'requestId': requestId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      };

      debugPrint('📤 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/locations'),
        headers: {
          AppConstants.contentTypeHeader: AppConstants.applicationJson,
          AppConstants.authorizationHeader: AppConstants.getBearerToken(authToken),
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15));

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Location update sent successfully');
        return {
          'success': true,
          'data': data,
          'myStatus': data['myStatus'],
        };
      } else if (response.statusCode == 401) {
        debugPrint('❌ Authentication failed');
        throw Exception('Authentication failed - please login again');
      } else if (response.statusCode == 404) {
        debugPrint('❌ Request not found');
        throw Exception('Request not found or no longer active');
      } else {
        debugPrint('❌ Server error: ${response.statusCode}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('💥 Error sending location update: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get current position with timeout and error handling
  Future<Position?> getCurrentPosition({
    Duration timeout = const Duration(seconds: 10),
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    try {
      debugPrint('📍 Getting current position...');
      
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: timeout,
      );

      debugPrint('📍 Position obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('❌ Error getting current position: $e');
      
      if (e.toString().contains('timeout')) {
        debugPrint('⏰ Position request timed out');
        throw Exception('Location request timed out. Please check your GPS signal.');
      } else if (e.toString().contains('permission')) {
        debugPrint('🔒 Permission error getting position');
        throw Exception('Location permission required to get position.');
      } else {
        debugPrint('💥 Unexpected error getting position: $e');
        throw Exception('Failed to get current position. Please try again.');
      }
    }
  }

  /// Check if request is still active
  Future<bool> isRequestActive(String requestId) async {
    try {
      final authToken = await _authService.gettoken();
      if (authToken == null) {
        return false;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/requests/$requestId'),
        headers: {
          AppConstants.contentTypeHeader: AppConstants.applicationJson,
          AppConstants.authorizationHeader: AppConstants.getBearerToken(authToken),
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final myStatus = data['myStatus'] as int?;
        return myStatus == 2; // Active if myStatus is 2
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error checking request status: $e');
      return false;
    }
  }

  /// Get request details
  Future<Map<String, dynamic>?> getRequestDetails(String requestId) async {
    try {
      final authToken = await _authService.gettoken();
      if (authToken == null) {
        return null;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/requests/$requestId'),
        headers: {
          AppConstants.contentTypeHeader: AppConstants.applicationJson,
          AppConstants.authorizationHeader: AppConstants.getBearerToken(authToken),
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting request details: $e');
      return null;
    }
  }
}
