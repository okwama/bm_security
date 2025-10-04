import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/request_model.dart';

abstract class RequestsLocalDataSource {
  Future<List<RequestModel>> getCachedRequests();
  Future<void> cacheRequests(List<RequestModel> requests);
  Future<void> clearCache();
}

class RequestsLocalDataSourceImpl implements RequestsLocalDataSource {
  final FlutterSecureStorage storage;
  static const String _cacheKey = 'cached_requests';

  RequestsLocalDataSourceImpl({required this.storage});

  @override
  Future<List<RequestModel>> getCachedRequests() async {
    try {
      final cachedData = await storage.read(key: _cacheKey);
      if (cachedData != null) {
        final List<dynamic> jsonList = json.decode(cachedData);
        return jsonList.map((json) => RequestModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheRequests(List<RequestModel> requests) async {
    try {
      final jsonList = requests.map((request) => request.toJson()).toList();
      await storage.write(key: _cacheKey, value: json.encode(jsonList));
    } catch (e) {
      // Handle cache error silently
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await storage.delete(key: _cacheKey);
    } catch (e) {
      // Handle cache error silently
    }
  }
}
