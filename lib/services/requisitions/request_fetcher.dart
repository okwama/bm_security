// File: services/requisitions/request_fetcher.dart
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/request.dart';
import '../../utils/auth_config.dart';
import '../http/http_client_manager.dart';
import '../http/auth_service.dart';
import '../location_service.dart';

class RequestFetcher {
  static final RequestFetcher _instance = RequestFetcher._internal();
  factory RequestFetcher() => _instance;
  RequestFetcher._internal() {
  }

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String _tokenKey = 'token';
  final HttpClientManager _httpManager = HttpClientManager.instance;
  final AuthService _authService = AuthService();
  Timer? _pollingTimer;
  final Duration _pollingInterval = const Duration(seconds: 30);
  bool _isPolling = false;
  final _requestController = StreamController<List<Request>>.broadcast();
  List<Request> _cachedRequests = [];
  DateTime? _lastFetchTime;
  static const Duration _minFetchInterval = Duration(seconds: 5);

  Stream<List<Request>> get requestStream => _requestController.stream;

  Future<Request> getRequestDetails(int requestId) async {
    try {
      final headers = await _authService.getHeaders();

      final response = await _httpManager.dioClient.get(
        '/requests/$requestId',
        options: Options(headers: headers),
      );

      if (response.statusCode == 403) {
        throw Exception('You are not authorized to access this request');
      }

      return _parseRequestResponse(response.data, 'request details');
    } catch (e) {
      _logError('getRequestDetails', e, null);
      rethrow;
    }
  }

  Future<List<Request>> getPendingRequests() async {
    try {
      final headers = await _authService.getHeaders();
      final userData = _authService.userData;

      final response = await _httpManager.dioClient.get(
        '/requests/pending',
        options: Options(
          headers: headers,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Request.fromJson(json)).toList();
      } else if (response.statusCode == 403) {
        throw Exception('You do not have permission to view pending requests');
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception(
            'Failed to fetch pending requests: ${response.statusCode}');
      }
    } catch (e) {
      _logError('getPendingRequests', e, null);
      if (e is DioException) {
        if (e.response?.statusCode == 403) {
          throw Exception(
              'You do not have permission to view pending requests');
        } else if (e.response?.statusCode == 401) {
          throw Exception('Session expired. Please login again.');
        }
      }
      rethrow;
    }
  }

  Future<List<Request>> getInProgressRequests() async {
    try {
      final headers = await _authService.getHeaders();
      final userData = _authService.userData;

      final response = await _httpManager.dioClient.get(
        '/requests/in-progress',
        options: Options(
          headers: headers,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final requests = data.map((json) => Request.fromJson(json)).toList();

        for (final request in requests) {
        }

        // Auto-start location tracking for in-progress requests
        await _autoStartLocationTracking(requests);

        return requests;
      } else if (response.statusCode == 403) {
        throw Exception(
            'You do not have permission to view in-progress requests');
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception(
            'Failed to fetch in-progress requests: ${response.statusCode}');
      }
    } catch (e) {
      _logError('getInProgressRequests', e, null);
      if (e is DioException) {
        if (e.response?.statusCode == 403) {
          throw Exception(
              'You do not have permission to view in-progress requests');
        } else if (e.response?.statusCode == 401) {
          throw Exception('Session expired. Please login again.');
        }
      }
      rethrow;
    }
  }

  Future<void> _autoStartLocationTracking(List<Request> requests) async {
        '🔍 _autoStartLocationTracking called with ${requests.length} requests');

    if (requests.isEmpty) {
      return;
    }

    try {
      final locationService = LocationService();

      for (final request in requests) {
            '🔍 Checking request ${request.id}: myStatus = ${request.myStatus}');

        // Check if this request needs location tracking (myStatus = 2)
        if (request.myStatus == 2) {
              '🎯 Auto-starting location tracking for request: ${request.id}');

          // Check if already tracking this request
          if (!locationService.isTrackingRequest(request.id.toString())) {
            final trackingResult = await locationService.startTracking(
              request.id.toString(),
              myStatus: 2,
            );

            if (trackingResult) {
            } else {
                  '❌ Failed to start location tracking for request: ${request.id}');
            }
          } else {
          }
        } else {
              '⏭️ Skipping request ${request.id}: myStatus = ${request.myStatus} (not 2)');
        }
      }
    } catch (e) {
    }
  }

  Future<List<Request>> getCompletedRequests() async {
    try {
      final headers = await _authService.getHeaders();

      final response = await _httpManager.dioClient.get(
        '/requests/completed',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Request.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch completed requests');
      }
    } catch (e) {
      _logError('getCompletedRequests', e, null);
      rethrow;
    }
  }

  Request _parseRequestResponse(dynamic response, String context) {
    try {
      if (response is Map<String, dynamic>) {
        return Request.fromJson(response);
      } else {
        throw Exception('Invalid response format for $context');
      }
    } catch (e) {
      _logError('_parseRequestResponse', e, null);
      throw Exception('Error parsing $context: $e');
    }
  }

  void _logError(String operation, dynamic error, StackTrace? stackTrace) {
    if (stackTrace != null) {
    }
  }

  Future<void> startPolling() async {
    if (_isPolling) {
      return;
    }

    _isPolling = true;
    await _fetchRequests();

    _pollingTimer = Timer.periodic(_pollingInterval, (timer) async {
      await _fetchRequests();
    });
  }

  Future<void> _fetchRequests() async {

    // Check if we're trying to fetch too frequently
    if (_lastFetchTime != null) {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
      if (timeSinceLastFetch < _minFetchInterval) {
            '⏰ Fetch too soon, skipping. Time since last fetch: $timeSinceLastFetch');
        return;
      }
    }

    try {
      final headers = await _authService.getHeaders();

      final response = await _httpManager.dioClient.get(
        '/requests/pending',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        _cachedRequests = data.map((json) => Request.fromJson(json)).toList();
        _lastFetchTime = DateTime.now();

        _requestController.add(_cachedRequests);
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to fetch requests: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw Exception('Network error. Please check your connection.');
      }
      throw Exception('Failed to fetch requests: ${e.toString()}');
    }
  }

  Future<void> stopPolling() async {
    _pollingTimer?.cancel();
    _isPolling = false;
  }

  void dispose() {
    stopPolling();
    _requestController.close();
  }

  List<Request> getCachedRequests() {
    return _cachedRequests;
  }
}
