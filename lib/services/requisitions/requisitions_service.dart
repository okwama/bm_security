// File: services/requisitions/requisitions_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'request_fetcher.dart';
import 'request_updater.dart';
import '../http/http_client_manager.dart';
import '../http/auth_service.dart';
import '../../models/request.dart';
import '../../models/cash_count.dart';
import '../../core/constants/app_constants.dart';
import '../../utils/auth_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../location_service.dart';

class RequisitionsService {
  static final RequisitionsService _instance = RequisitionsService._internal();
  factory RequisitionsService() => _instance;
  RequisitionsService._internal() {
    print('🏭 Initializing RequisitionsService');
    print('📡 HTTP Manager instance: ${_httpManager != null}');
  }

  final RequestFetcher _fetcher = RequestFetcher();
  final RequestUpdater _updater = RequestUpdater();
  final HttpClientManager _httpManager = HttpClientManager.instance;
  final AuthService _authService = AuthService();
  final String _baseUrl = ApiConfig.baseUrl;

  // Fetching methods - delegate to RequestFetcher
  Future<List<Request>> getPendingRequests() async {
    try {
      return await _fetcher.getPendingRequests();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        // Check if we need to refresh the token
        final token = await _authService.gettoken();
        if (token != null) {
          // Try one more time with the current token
          return await _fetcher.getPendingRequests();
        }
      }
      rethrow;
    }
  }

  Future<Request> getRequestDetails(int requestId) async {
    try {
      // Validate request ID
      if (requestId <= 0) {
        throw Exception('Invalid request ID: ID must be a positive number');
      }

      return await _fetcher.getRequestDetails(requestId);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        // Check if we need to refresh the token
        final token = await _authService.gettoken();
        if (token != null) {
          // Try one more time with the current token
          return await _fetcher.getRequestDetails(requestId);
        }
      }
      rethrow;
    } catch (e) {
      print('Error getting request details: $e');
      throw Exception('Failed to get request details: ${e.toString()}');
    }
  }

  Future<List<Request>> getInProgressRequests() =>
      _fetcher.getInProgressRequests();
  Future<List<Request>> getMyAssignedRequests() =>
      _fetcher.getPendingRequests();
  Future<List<Request>> getCompletedRequests() =>
      _fetcher.getCompletedRequests();

  Future<Request> confirmDelivery(
    String requestId, {
    Map<String, dynamic>? bankDetails,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    try {
      print('=== Confirm Delivery Debug ===');
      print('Input requestId type: ${requestId.runtimeType}');
      print('Input requestId value: $requestId');

      // Validate request ID
      if (requestId.isEmpty) {
        throw Exception('Request ID is required');
      }

      // Convert string to int safely
      final parsedId = int.tryParse(requestId);
      if (parsedId == null) {
        throw Exception('Request ID must be a valid number');
      }

      if (parsedId <= 0) {
        throw Exception('Request ID must be a positive number');
      }

      print('Parsed ID type: ${parsedId.runtimeType}');
      print('Parsed ID value: $parsedId');

      final response = await _updater.confirmDelivery(
        parsedId,
        bankDetails: bankDetails,
        latitude: latitude,
        longitude: longitude,
        notes: notes,
      );
      return response;
    } catch (e, stackTrace) {
      print('=== Confirm Delivery Error ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Request> confirmPickup(
    int requestId, {
    CashCount? cashCount,
    String? imageUrl,
    required String sealNumber,
    double? latitude,
    double? longitude,
  }) async {
    print('=== RequisitionsService.confirmPickup Debug ===');
    print('RequestId: $requestId');
    print('SealNumber: $sealNumber');
    print('Location: $latitude, $longitude');

    final request = await _updater.confirmPickup(
      requestId,
      cashCount: cashCount,
      imageUrl: imageUrl,
      sealNumber: sealNumber,
      latitude: latitude,
      longitude: longitude,
    );

    print('=== Pickup Response Debug ===');
    print('Request JSON: ${request.toJson()}');

    // Centralized location tracking logic based on myStatus
    final myStatus = request.toJson()['myStatus'] as int?;
    print('MyStatus from response: $myStatus');

    // Start location tracking in background (non-blocking)
    if (myStatus == 2) {
      print('Starting location tracking for request: $requestId');
      // Start tracking with proper error handling
      try {
        final locationService = LocationService();
        final trackingResult = await locationService
            .startTracking(requestId.toString(), myStatus: myStatus);
        print('Location tracking started: $trackingResult');

        // Verify tracking is active
        if (trackingResult) {
          print('✅ Location tracking confirmed active for request: $requestId');
        } else {
          print('❌ Location tracking failed to start for request: $requestId');
        }
      } catch (error) {
        print('❌ Location tracking error: $error');
        // Don't fail the pickup if location tracking fails
      }
    } else if (myStatus == 3) {
      print('Stopping location tracking (myStatus = 3)');
      try {
        await LocationService().stopTracking();
        print('✅ Location tracking stopped');
      } catch (error) {
        print('❌ Error stopping location tracking: $error');
      }
    } else {
      print('No location tracking action needed (myStatus = $myStatus)');
    }

    return request;
  }

  Future<Request> assignToVaultOfficer(
          int requestId, int vaultOfficerId, String vaultOfficerName) =>
      _updater.assignToVaultOfficer(
          requestId, vaultOfficerId, vaultOfficerName);

  Future<String> uploadImage(XFile imageFile) async {
    print('📡 HTTP Manager instance: ${HttpClientManager.instance != null}');

    try {
      final dio = HttpClientManager.instance.dioClient;
      print('📡 Dio instance: ${dio != null}');

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.name,
        ),
      });

      // Get auth headers
      final headers = await _authService.getHeaders();
      print(
          '🔑 Token retrieval attempt: ${headers['Authorization'] != null ? 'Token found' : 'No token'}');
      if (headers['Authorization'] != null) {
        print(
            '📝 Token value: ${headers['Authorization']?.substring(0, 20)}...');
      }

      print('📤 Uploading image to: ${ApiConfig.baseUrl}/upload');
      final response = await dio.post(
        '/upload',
        data: formData,
        options: Options(
          headers: {
            ...headers,
            AppConstants.contentTypeHeader: 'multipart/form-data',
          },
          validateStatus: (status) =>
              status! < 500, // Allow 4xx responses to be handled
        ),
      );

      print('📥 Upload response: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic> &&
            responseData['success'] == true &&
            responseData['data'] != null &&
            responseData['data']['url'] != null) {
          return responseData['data']['url'];
        } else {
          throw Exception('Invalid response format: missing URL in response');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception('You do not have permission to upload images');
      } else {
        throw Exception(response.data['message'] ?? 'Failed to upload image');
      }
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  // Lifecycle methods
  void dispose() => _httpManager.dispose();
  void forceDispose() => _httpManager.forceDispose();
}

// Add missing ApiException class if it doesn't exist
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  factory ApiException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('Request timeout');
      case DioExceptionType.badResponse:
        return ApiException(
            'Server responded with ${error.response?.statusCode}');
      case DioExceptionType.cancel:
        return ApiException('Request cancelled');
      default:
        return ApiException('Network error occurred');
    }
  }

  @override
  String toString() => 'ApiException: $message';
}
