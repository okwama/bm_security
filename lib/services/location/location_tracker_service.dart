import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_api_service.dart';

class LocationTrackerService {
  static final LocationTrackerService _instance = LocationTrackerService._internal();
  factory LocationTrackerService() => _instance;
  LocationTrackerService._internal();

  // State management
  bool _isTracking = false;
  String? _currentRequestId;
  Timer? _locationTimer;
  final LocationApiService _apiService = LocationApiService();
  
  // Tracking configuration
  static const Duration _updateInterval = Duration(seconds: 30);
  static const Duration _throttleInterval = Duration(seconds: 25);
  static const String _lastUpdateKey = 'last_location_update';

  // Getters
  bool get isTracking => _isTracking;
  String? get currentRequestId => _currentRequestId;
  bool get hasActiveTimer => _locationTimer?.isActive ?? false;

  /// Start tracking location for a specific request
  Future<bool> startTracking(String requestId) async {
    try {

      // Check if already tracking this request
      if (_isTracking && _currentRequestId == requestId) {
        return true;
      }

      // Stop any existing tracking
      if (_isTracking) {
        await stopTracking();
      }

      // Set tracking state
      _currentRequestId = requestId;
      _isTracking = true;

      // Save tracking info for persistence
      await _saveTrackingInfo(requestId);

      // Get initial position and send update
      await _sendInitialLocationUpdate(requestId);

      // Start periodic updates
      await _startPeriodicUpdates();

      return true;
    } catch (e) {
      await _resetTrackingState();
      return false;
    }
  }

  /// Stop tracking location
  Future<void> stopTracking() async {
    if (!_isTracking) {
      return;
    }

    final stoppedRequestId = _currentRequestId;

    // Cancel timer
    _locationTimer?.cancel();
    _locationTimer = null;

    // Clear state
    await _resetTrackingState();

    // Clear saved tracking info
    await _clearTrackingInfo();

  }

  /// Send initial location update
  Future<void> _sendInitialLocationUpdate(String requestId) async {
    try {
      
      final position = await _apiService.getCurrentPosition();
      if (position == null) {
        throw Exception('Failed to get initial position');
      }

      final result = await _apiService.sendLocationUpdate(
        requestId: requestId,
        position: position,
      );

      if (result['success'] == true) {
        
        // Check if request is completed
        final myStatus = result['myStatus'];
        if (myStatus == 3) {
          await stopTracking();
        }
      } else {
      }
    } catch (e) {
      throw e;
    }
  }

  /// Start periodic location updates
  Future<void> _startPeriodicUpdates() async {
    // Cancel existing timer
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(_updateInterval, (timer) async {
      if (!_isTracking || _currentRequestId == null) {
        timer.cancel();
        return;
      }

      try {
        await _sendPeriodicLocationUpdate();
      } catch (e) {
        
        // Stop tracking on critical errors
        if (e.toString().contains('permission') || e.toString().contains('authentication')) {
          timer.cancel();
          await stopTracking();
        }
      }
    });
  }

  /// Send periodic location update
  Future<void> _sendPeriodicLocationUpdate() async {
    try {
      // Check throttle
      if (await _isThrottled()) {
        return;
      }
      final position = await _apiService.getCurrentPosition();
      if (position == null) {
        return;
      }

      final result = await _apiService.sendLocationUpdate(
        requestId: _currentRequestId!,
        position: position,
      );

      if (result['success'] == true) {
        
        // Update last sent timestamp
        await _updateLastSentTimestamp();
        
        // Check if request is completed
        final myStatus = result['myStatus'];
        if (myStatus == 3) {
          await stopTracking();
        }
      } else {
      }
    } catch (e) {
      throw e;
    }
  }

  /// Check if location update should be throttled
  Future<bool> _isThrottled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSent = prefs.getInt(_lastUpdateKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      return (now - lastSent) < _throttleInterval.inMilliseconds;
    } catch (e) {
      return false;
    }
  }

  /// Update last sent timestamp
  Future<void> _updateLastSentTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
    }
  }

  /// Save tracking info for persistence
  Future<void> _saveTrackingInfo(String requestId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_tracking_request', requestId);
      await prefs.setBool('is_tracking', true);
    } catch (e) {
    }
  }

  /// Clear tracking info
  Future<void> _clearTrackingInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_tracking_request');
      await prefs.setBool('is_tracking', false);
    } catch (e) {
    }
  }

  /// Reset tracking state
  Future<void> _resetTrackingState() async {
    _isTracking = false;
    _currentRequestId = null;
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  /// Check if tracking specific request
  bool isTrackingRequest(String requestId) {
    return _isTracking && _currentRequestId == requestId;
  }

  /// Get tracking status
  Map<String, dynamic> getTrackingStatus() {
    return {
      'isTracking': _isTracking,
      'currentRequestId': _currentRequestId,
      'hasActiveTimer': hasActiveTimer,
      'timerTicks': _locationTimer?.tick ?? 0,
    };
  }

  /// Restore tracking state from persistence
  Future<bool> restoreTrackingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRequestId = prefs.getString('current_tracking_request');
      final wasTracking = prefs.getBool('is_tracking') ?? false;

      if (wasTracking && savedRequestId != null) {
        
        // Verify request is still active
        final isActive = await _apiService.isRequestActive(savedRequestId);
        if (isActive) {
          return await startTracking(savedRequestId);
        } else {
          await _clearTrackingInfo();
          return false;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}
