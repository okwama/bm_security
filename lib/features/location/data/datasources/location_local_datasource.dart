import '../../../../core/errors/exceptions.dart';
import '../models/location_model.dart';

abstract class LocationLocalDataSource {
  Future<List<LocationModel>> getCachedLocationHistory({
    required int requestId,
  });

  Future<void> cacheLocationHistory({
    required int requestId,
    required List<LocationModel> locations,
  });
}

class LocationLocalDataSourceImpl implements LocationLocalDataSource {
  // In a real app, you would use SharedPreferences, Hive, or SQLite
  // For now, we'll use a simple in-memory cache
  static final Map<int, List<LocationModel>> _cache = {};

  @override
  Future<List<LocationModel>> getCachedLocationHistory({
    required int requestId,
  }) async {
    try {
      final cached = _cache[requestId];
      if (cached != null) {
        return cached;
      } else {
        throw CacheException(message: 'No cached data found');
      }
    } catch (e) {
      throw CacheException(message: 'Failed to get cached location history');
    }
  }

  @override
  Future<void> cacheLocationHistory({
    required int requestId,
    required List<LocationModel> locations,
  }) async {
    try {
      _cache[requestId] = locations;
    } catch (e) {
      throw CacheException(message: 'Failed to cache location history');
    }
  }
}
