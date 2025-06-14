// File: services/requisitions/request_fetcher.dart
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import '../../models/request.dart';
import '../../utils/auth_config.dart';
import '../http/http_client_manager.dart';
import '../http/auth_service.dart';

class RequestFetcher {
  static final RequestFetcher _instance = RequestFetcher._internal();
  factory RequestFetcher() => _instance;
  RequestFetcher._internal() {
    print('🏭 Initializing RequestFetcher');
    print('📡 HTTP Manager instance: ${_httpManager != null}');
  }

  final GetStorage _storage = GetStorage();
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
      print('Fetching request details for ID: $requestId');
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
      print('Fetching pending requests');
      final headers = await _authService.getHeaders();
      final userData = _authService.userData;
      print('👤 Current user role: ${userData?['role']}');
      print('👤 Current user ID: ${userData?['id']}');

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
      print('Fetching in-progress requests');
      final headers = await _authService.getHeaders();
      final userData = _authService.userData;
      print('👤 Current user role: ${userData?['role']}');
      print('👤 Current user ID: ${userData?['id']}');

      final response = await _httpManager.dioClient.get(
        '/requests/in-progress',
        options: Options(
          headers: headers,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Request.fromJson(json)).toList();
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

  Future<List<Request>> getCompletedRequests() async {
    try {
      print('Fetching completed requests');
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
    print('Error in $operation: $error');
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> startPolling() async {
    print('🔄 Starting request polling...');
    if (_isPolling) {
      print('⚠️ Polling already in progress');
      return;
    }

    _isPolling = true;
    print('📡 Initial fetch...');
    await _fetchRequests();

    print('⏰ Setting up polling timer...');
    _pollingTimer = Timer.periodic(_pollingInterval, (timer) async {
      print('⏰ Polling timer triggered');
      await _fetchRequests();
    });
  }

  Future<void> _fetchRequests() async {
    print('📥 Fetching requests...');

    // Check if we're trying to fetch too frequently
    if (_lastFetchTime != null) {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
      if (timeSinceLastFetch < _minFetchInterval) {
        print(
            '⏰ Fetch too soon, skipping. Time since last fetch: $timeSinceLastFetch');
        return;
      }
    }

    try {
      print('🔑 Getting headers...');
      final headers = await _authService.getHeaders();

      print('📡 Making API request...');
      final response = await _httpManager.dioClient.get(
        '/requests/pending',
        options: Options(headers: headers),
      );

      print('📦 Processing response...');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        print('📊 Received ${data.length} requests');

        _cachedRequests = data.map((json) => Request.fromJson(json)).toList();
        _lastFetchTime = DateTime.now();

        print('📤 Emitting ${_cachedRequests.length} requests to stream');
        _requestController.add(_cachedRequests);
      } else if (response.statusCode == 401) {
        print('🔒 Unauthorized access');
        throw Exception('Session expired. Please login again.');
      } else {
        print('⚠️ Invalid response format: ${response.statusCode}');
        throw Exception('Failed to fetch requests: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching requests: $e');
      if (e.toString().contains('SocketException')) {
        print('🌐 Network error detected');
        throw Exception('Network error. Please check your connection.');
      }
      print('❌ Unexpected error: $e');
      throw Exception('Failed to fetch requests: ${e.toString()}');
    }
  }

  Future<void> stopPolling() async {
    print('🛑 Stopping request polling...');
    _pollingTimer?.cancel();
    _isPolling = false;
    print('✅ Polling stopped');
  }

  void dispose() {
    print('🗑️ Disposing RequestFetcher...');
    stopPolling();
    _requestController.close();
    print('✅ RequestFetcher disposed');
  }

  List<Request> getCachedRequests() {
    print('📋 Getting cached requests: ${_cachedRequests.length} items');
    return _cachedRequests;
  }
}
