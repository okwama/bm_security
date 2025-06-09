// File: services/requisitions/requisitions_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'request_fetcher.dart';
import 'request_updater.dart';
import '../http/http_client_manager.dart';
import '../http/auth_service.dart';
import '../../models/request.dart';
import '../../models/cash_count.dart';
import '../../utils/auth_config.dart';

class RequisitionsService {
  static final RequisitionsService _instance = RequisitionsService._internal();
  factory RequisitionsService() => _instance;
  RequisitionsService._internal();

  final RequestFetcher _fetcher = RequestFetcher();
  final RequestUpdater _updater = RequestUpdater();
  final HttpClientManager _httpManager = HttpClientManager();
  final AuthService _authService = AuthService();

  // Fetching methods - delegate to RequestFetcher
  Future<List<Request>> getPendingRequests() => _fetcher.getPendingRequests();
  Future<Request> getRequestDetails(int requestId) =>
      _fetcher.getRequestDetails(requestId);
  Future<List<Request>> getInProgressRequests() =>
      _fetcher.getInProgressRequests();
  Future<List<Request>> getAllStaffRequests() => _fetcher.getAllStaffRequests();
  Future<List<Request>> getMyAssignedRequests() =>
      _fetcher.getPendingRequests();

  Future<Request> completeRequisition(
    String requestId, {
    String? photoUrl,
    Map<String, dynamic>? bankDetails,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    try {
      print('=== Complete Requisition Debug ===');
      print('Input requestId type: ${requestId.runtimeType}');
      print('Input requestId value: $requestId');

      // Convert string to int safely
      final parsedId = int.tryParse(requestId);
      if (parsedId == null) {
        throw Exception('Invalid request ID format');
      }

      print('Parsed ID type: ${parsedId.runtimeType}');
      print('Parsed ID value: $parsedId');

      final response = await _updater.completeRequisition(
        parsedId.toString(),
        photoUrl: photoUrl,
        bankDetails: bankDetails,
        latitude: latitude,
        longitude: longitude,
        notes: notes,
      );
      return response;
    } catch (e, stackTrace) {
      print('=== Complete Requisition Error ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Request> completeVaultDelivery(
    String requestId, {
    bool isVaultDelivery = false,
    String? photoUrl,
    Map<String, dynamic>? bankDetails,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    try {
      print('=== Complete Vault Delivery Debug ===');
      print('Input requestId type: ${requestId.runtimeType}');
      print('Input requestId value: $requestId');

      // Convert string to int safely
      final parsedId = int.tryParse(requestId);
      if (parsedId == null) {
        throw Exception('Invalid request ID format');
      }

      print('Parsed ID type: ${parsedId.runtimeType}');
      print('Parsed ID value: $parsedId');

      final response = await _updater.completeRequisition(
        parsedId.toString(),
        isVaultDelivery: isVaultDelivery,
        photoUrl: photoUrl,
        bankDetails: bankDetails,
        latitude: latitude,
        longitude: longitude,
        notes: notes,
      );
      return response;
    } catch (e, stackTrace) {
      print('=== Complete Vault Delivery Error ===');
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
  }) =>
      _updater.confirmPickup(requestId,
          cashCount: cashCount, imageUrl: imageUrl);

  Future<Request> assignToVaultOfficer(
          int requestId, int vaultOfficerId, String vaultOfficerName) =>
      _updater.assignToVaultOfficer(
          requestId, vaultOfficerId, vaultOfficerName);

  // Lifecycle methods
  void dispose() => _httpManager.dispose();
  void forceDispose() => _httpManager.forceDispose();
}

// Add missing ApiException class if it doesn't exist
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  factory ApiException.fromDioError(DioError error) {
    switch (error.type) {
      case DioErrorType.connectionTimeout:
      case DioErrorType.sendTimeout:
      case DioErrorType.receiveTimeout:
        return ApiException('Request timeout');
      case DioErrorType.badResponse:
        return ApiException(
            'Server responded with ${error.response?.statusCode}');
      case DioErrorType.cancel:
        return ApiException('Request cancelled');
      default:
        return ApiException('Network error occurred');
    }
  }

  @override
  String toString() => 'ApiException: $message';
}
