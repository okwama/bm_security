import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart' show MethodChannel, PlatformException;
import 'package:bm_security/utils/auth_config.dart';

class LocationService {
  static const String _baseUrl = ApiConfig.baseUrl;
  static const String _locationKey = 'last_sent_location';
  static const Duration _minUpdateInterval = Duration(minutes: 1);
  bool _isTracking = false;
  String? _currentRequestId;
  String? _authToken;

  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Add getters for tracking state
  bool get isTracking => _isTracking;
  String? get currentRequestId => _currentRequestId;

  // Add method to check if tracking specific request
  bool isTrackingRequest(String requestId) {
    return _isTracking && _currentRequestId == requestId;
  }

  // Add method to transfer tracking to new request
  Future<void> transferTracking(String newRequestId) async {
    if (_isTracking) {
      await stopTracking();
    }
    await startTracking(newRequestId);
  }

  // Initialize the service
  Future<bool> initialize({required String authToken}) async {
    _authToken = authToken;

    // Request necessary permissions
    final status = await Permission.locationAlways.request();
    if (!status.isGranted) {
      return false;
    }

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // On Android, open location settings
      if (Platform.isAndroid) {
        try {
          // Use platform channel to open settings
          const platform = MethodChannel('com.bmsecurity.bm/location');
          await platform.invokeMethod('openLocationSettings');
        } on PlatformException catch (e) {
          debugPrint('Error opening location settings: ${e.message}');
        } catch (e) {
          debugPrint('Unexpected error: $e');
        }
      }
      return false;
    }

    // Configure location settings
    await _configureLocationSettings();

    return true;
  }

  // Configure location settings
  Future<void> _configureLocationSettings() async {
    // Nothing to configure for basic implementation
  }

  // Start tracking location for a specific request
  Future<bool> startTracking(String requestId) async {
    if (_isTracking) {
      if (_currentRequestId == requestId) {
        // Already tracking this request
        return true;
      }
      // Stop tracking previous request
      await stopTracking();
    }

    _currentRequestId = requestId;
    _isTracking = true;

    try {
      // Save tracking info for background service
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_tracking_request', requestId);
      if (_authToken != null) {
        await prefs.setString('auth_token', _authToken!);
      }

      // Get initial position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _sendLocationUpdate(position);

      // Start foreground service
      await _startForegroundService();

      return true;
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
      _isTracking = false;
      _currentRequestId = null;
      return false;
    }
  }

  // Start foreground service for Android
  Future<void> _startForegroundService() async {
    if (Platform.isAndroid) {
      // Start WorkManager for periodic tasks
      await Workmanager().initialize(
        _backgroundTaskCallback,
        isInDebugMode: kDebugMode,
      );

      await Workmanager().registerPeriodicTask(
        'location_update_task',
        'location_update',
        frequency: _minUpdateInterval,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );
    }
  }

  // Stop tracking location
  Future<void> stopTracking() async {
    if (!_isTracking) return;

    debugPrint('Stopping location tracking for request: $_currentRequestId');

    _isTracking = false;
    final stoppedRequestId = _currentRequestId;
    _currentRequestId = null;

    try {
      // Cancel background tasks
      if (Platform.isAndroid) {
        await Workmanager().cancelAll();
      }

      // Clear saved tracking info
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_tracking_request');
      await prefs.remove('auth_token');

      debugPrint(
          'Successfully stopped tracking for request: $stoppedRequestId');
    } catch (e) {
      debugPrint('Error stopping location tracking: $e');
      rethrow;
    }
  }

  // Stop tracking for a specific request
  Future<void> stopTrackingForRequest(String requestId) async {
    if (_currentRequestId == requestId) {
      await stopTracking();
    }
  }

  // Send location update to the server
  Future<void> _sendLocationUpdate(Position position) async {
    if (_currentRequestId == null || _authToken == null) return;

    final prefs = await SharedPreferences.getInstance();
    final lastSent = prefs.getInt(_locationKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Throttle updates
    if ((now - lastSent) < _minUpdateInterval.inMilliseconds) {
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/locations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'requestId': _currentRequestId,
          'latitude': position.latitude,
          'longitude': position.longitude,
        }),
      );

      if (response.statusCode == 201) {
        await prefs.setInt(_locationKey, now);
      } else {
        debugPrint('Failed to send location: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error sending location: $e');
    }
  }

  // Background task callback for WorkManager
  @pragma('vm:entry-point')
  static Future<void> _backgroundTaskCallback() {
    Workmanager().executeTask((task, inputData) async {
      if (task == 'location_update') {
        try {
          final prefs = await SharedPreferences.getInstance();
          final requestId = prefs.getString('current_tracking_request');
          final authToken = prefs.getString('auth_token');

          if (requestId != null && authToken != null) {
            // Get current position
            final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );

            // Send to server
            final response = await http.post(
              Uri.parse('$_baseUrl/locations'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $authToken',
              },
              body: jsonEncode({
                'requestId': requestId,
                'latitude': position.latitude,
                'longitude': position.longitude,
              }),
            );

            if (response.statusCode != 201) {
              debugPrint(
                  'Failed to send background location: ${response.body}');
            }
          }
          return Future.value(true);
        } catch (e) {
          debugPrint('Background location update error: $e');
          return Future.error(e);
        }
      }
      return Future.value(true);
    });
    return Future.value();
  }
}

// Global instance
final locationService = LocationService();
