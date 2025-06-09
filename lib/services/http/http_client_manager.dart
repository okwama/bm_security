// File: services/http/http_client_manager.dart
import 'dart:async';
import 'package:http/http.dart' as http;

class HttpClientManager {
  static final HttpClientManager _instance = HttpClientManager._internal();
  factory HttpClientManager() => _instance;
  HttpClientManager._internal();

  http.Client? _client;
  final Set<String> _activeRequests = <String>{};
  bool _isDisposed = false;

  http.Client get client {
    if (_client == null || _isDisposed) {
      _client = http.Client();
      _isDisposed = false;
    }
    return _client!;
  }

  String addActiveRequest(String requestId) {
    _activeRequests.add(requestId);
    return requestId;
  }

  void removeActiveRequest(String requestId) {
    _activeRequests.remove(requestId);
  }

  void dispose() {
    if (_activeRequests.isNotEmpty) {
      print('Warning: Disposing client with ${_activeRequests.length} active requests');
      return;
    }
    
    _client?.close();
    _client = null;
    _isDisposed = true;
  }

  void forceDispose() {
    _activeRequests.clear();
    _client?.close();
    _client = null;
    _isDisposed = true;
  }
}
 