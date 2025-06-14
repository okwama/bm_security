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
import 'package:bm_security/services/http/auth_service.dart';

class LocationService {
  static const String _baseUrl = ApiConfig.baseUrl;
  static const String _locationKey = 'last_sent_location';
  static const Duration _minUpdateInterval = Duration(seconds: 30);
  bool _isTracking = false;
  String? _currentRequestId;
  final AuthService _authService = AuthService();
  Timer? _locationTimer; // Add Timer for frequent updates
  Timer? _backupCheckTimer; // Add Timer for backup checks
  bool _isBackupRunning = false;

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

  // Test method to manually trigger location update (for debugging)
  Future<void> testLocationUpdate(String requestId) async {
    debugPrint('🧪 Testing location update for request: $requestId');

    try {
      // Get auth token
      final authtoken = await _authService.gettoken();
      if (authtoken == null) {
        debugPrint('❌ No auth token available for test');
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      debugPrint(
          '📍 Test position: ${position.latitude}, ${position.longitude}');

      // Set current request ID temporarily
      final originalRequestId = _currentRequestId;
      _currentRequestId = requestId;

      // Send location update
      await _sendLocationUpdate(position, authtoken);

      // Restore original request ID
      _currentRequestId = originalRequestId;

      debugPrint('✅ Test location update completed');
    } catch (e) {
      debugPrint('💥 Test location update failed: $e');
    }
  }

  // Initialize the service
  Future<bool> initialize() async {
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

  // Initialize the service with auto backup enabled
  Future<bool> initializeWithAutoBackup() async {
    debugPrint('🚀 Initializing location service with auto backup...');

    final initialized = await initialize();
    if (!initialized) {
      debugPrint('❌ Failed to initialize location service');
      return false;
    }

    // Save base URL to SharedPreferences for background service
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('base_url', _baseUrl);
    debugPrint('💾 Saved base URL to SharedPreferences: $_baseUrl');

    // Start auto backup system
    await startAutoBackupSystem();
    debugPrint('✅ Location service initialized with auto backup');

    return true;
  }

  // Configure location settings
  Future<void> _configureLocationSettings() async {
    // Nothing to configure for basic implementation
  }

  // Start tracking location for a specific request
  Future<bool> startTracking(String requestId, {int? myStatus}) async {
    debugPrint(
        '🎯 Starting location tracking for request: $requestId (myStatus: $myStatus)');

    // Only track if myStatus is 2 (picked up/in progress)
    if (myStatus != null && myStatus != 2) {
      debugPrint(
          '❌ Not starting tracking: myStatus is not 2 (current: $myStatus)');
      return false;
    }

    if (_isTracking) {
      if (_currentRequestId == requestId) {
        // Already tracking this request
        debugPrint('ℹ️ Already tracking request: $requestId');
        return true;
      }
      // Stop tracking previous request
      debugPrint(
          '🔄 Stopping tracking for previous request: $_currentRequestId');
      await stopTracking();
    }

    _currentRequestId = requestId;
    _isTracking = true;

    try {
      // Get auth token from AuthService
      final authtoken = await _authService.gettoken();
      if (authtoken == null) {
        debugPrint('❌ No authentication token available');
        _isTracking = false;
        _currentRequestId = null;
        return false;
      }

      // Save tracking info for background service
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_tracking_request', requestId);
      await prefs.setString('auth_token', authtoken);
      debugPrint('💾 Saved tracking info to SharedPreferences');

      // Get initial position
      debugPrint('📍 Getting initial position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      debugPrint(
          '📍 Initial position: ${position.latitude}, ${position.longitude}');

      await _sendLocationUpdate(position, authtoken);
      debugPrint('✅ Initial location update sent');

      // Start Timer-based periodic updates (every 30 seconds)
      await _startPeriodicLocationUpdates();
      debugPrint('⏰ Started periodic location updates');

      // Also start background service as backup
      await _startForegroundService();
      debugPrint('🔄 Started foreground service');

      debugPrint('✅ Successfully started tracking for request: $requestId');
      return true;
    } catch (e) {
      debugPrint('💥 Error starting location tracking: $e');
      _isTracking = false;
      _currentRequestId = null;
      return false;
    }
  }

  // Start periodic location updates using Timer
  Future<void> _startPeriodicLocationUpdates() async {
    // Cancel existing timer if any
    _locationTimer?.cancel();

    debugPrint('🕐 Starting 30-second location timer');

    _locationTimer = Timer.periodic(_minUpdateInterval, (timer) async {
      if (!_isTracking || _currentRequestId == null) {
        debugPrint(
            '🛑 Stopping location timer - tracking stopped or no request ID');
        timer.cancel();
        return;
      }

      try {
        debugPrint('🔄 Timer triggered - getting location update');

        // Get auth token
        final authtoken = await _authService.gettoken();
        if (authtoken == null) {
          debugPrint('❌ No auth token for periodic update');
          return;
        }

        // Get current position
        debugPrint('📍 Getting current position...');
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );

        debugPrint(
            '📍 Timer-based location update: ${position.latitude}, ${position.longitude}');

        // Send location update
        await _sendLocationUpdate(position, authtoken);
        debugPrint('✅ Timer-based location update sent successfully');
      } catch (e) {
        debugPrint('⚠️ Timer location update error: $e');
        if (e.toString().contains('timeout')) {
          debugPrint(
              '⏰ Location request timed out - will retry on next interval');
        } else if (e.toString().contains('permission')) {
          debugPrint('🔒 Location permission issue - stopping timer');
          timer.cancel();
        }
      }
    });
  }

  // Start foreground service for Android
  Future<void> _startForegroundService() async {
    if (Platform.isAndroid) {
      // Start WorkManager for periodic tasks
      await Workmanager().initialize(
        _backgroundTaskCallback,
        isInDebugMode: kDebugMode,
      );

      // For frequent updates (30 seconds), use one-time tasks that reschedule themselves
      // WorkManager minimum periodic interval is 15 minutes, so we use a different approach
      await Workmanager().registerOneOffTask(
        'location_update_task',
        'location_update',
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
      // Cancel location timer
      _locationTimer?.cancel();
      _locationTimer = null;
      debugPrint('🕐 Location timer cancelled');

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
  Future<void> _sendLocationUpdate(Position position, String authtoken) async {
    if (_currentRequestId == null || authtoken == null) {
      debugPrint(
          '❌ Cannot send location: requestId=$_currentRequestId, token=${authtoken != null ? 'present' : 'null'}');
      return;
    }

    debugPrint('📍 Preparing location update:');
    debugPrint('  - RequestId: $_currentRequestId');
    debugPrint('  - Latitude: ${position.latitude}');
    debugPrint('  - Longitude: ${position.longitude}');
    debugPrint('  - Token: ${authtoken.substring(0, 20)}...');

    final prefs = await SharedPreferences.getInstance();
    final lastSent = prefs.getInt(_locationKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Throttle updates to prevent spam (allow updates every 25 seconds to account for processing time)
    const throttleInterval = Duration(seconds: 25);
    if ((now - lastSent) < throttleInterval.inMilliseconds) {
      debugPrint(
          '⏰ Location update throttled. Last sent: ${DateTime.fromMillisecondsSinceEpoch(lastSent)}, Now: ${DateTime.fromMillisecondsSinceEpoch(now)}');
      return;
    }

    debugPrint('🚀 Sending location update to: $_baseUrl/locations');

    try {
      final requestBody = {
        'requestId': _currentRequestId,
        'latitude': position.latitude,
        'longitude': position.longitude,
      };

      debugPrint('📤 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/locations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authtoken',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('📥 Location update response:');
      debugPrint('  - Status: ${response.statusCode}');
      debugPrint('  - Body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final myStatus = data['myStatus'];
        debugPrint('✅ Location sent successfully. MyStatus: $myStatus');

        if (myStatus == 3) {
          debugPrint('🛑 MyStatus is 3 (completed). Stopping tracking.');
          await stopTracking();
        }
        await prefs.setInt(_locationKey, now);
      } else {
        debugPrint(
            '❌ Failed to send location: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 Error sending location: $e');
    }
  }

  // Background task callback for WorkManager
  @pragma('vm:entry-point')
  static void _backgroundTaskCallback() {
    Workmanager().executeTask((task, inputData) async {
      debugPrint('🔄 Background location task started: $task');

      if (task == 'location_update') {
        try {
          final prefs = await SharedPreferences.getInstance();
          final requestId = prefs.getString('current_tracking_request');
          final authtoken = prefs.getString('auth_token');

          debugPrint('📋 Background task data:');
          debugPrint('  - RequestId: $requestId');
          debugPrint(
              '  - Token: ${authtoken != null ? 'present (${authtoken!.length} chars)' : 'null'}');

          if (requestId == null || authtoken == null) {
            debugPrint('⚠️ Background task missing data - stopping');
            return Future.value(false);
          }

          // Check if we have location permissions
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever) {
            debugPrint('❌ Location permission denied in background');
            return Future.value(false);
          }

          // Check if location services are enabled
          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) {
            debugPrint('❌ Location services disabled in background');
            return Future.value(false);
          }

          debugPrint('📍 Getting current position for background update...');

          // Get current position with timeout
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 30),
          );

          debugPrint(
              '📍 Background position: ${position.latitude}, ${position.longitude}');

          final requestBody = {
            'requestId': requestId,
            'latitude': position.latitude,
            'longitude': position.longitude,
          };

          debugPrint('📤 Background request body: ${jsonEncode(requestBody)}');
          debugPrint('🚀 Sending to: ${ApiConfig.baseUrl}/locations');

          // Send to server with timeout
          final response = await http
              .post(
                Uri.parse('${ApiConfig.baseUrl}/locations'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $authtoken',
                },
                body: jsonEncode(requestBody),
              )
              .timeout(const Duration(seconds: 30));

          debugPrint('📥 Background location response:');
          debugPrint('  - Status: ${response.statusCode}');
          debugPrint('  - Body: ${response.body}');

          if (response.statusCode == 201) {
            debugPrint('✅ Background location sent successfully');

            // Check if request is completed
            try {
              final data = jsonDecode(response.body);
              final myStatus = data['myStatus'];
              debugPrint('📊 Background response myStatus: $myStatus');

              if (myStatus == 3) {
                debugPrint(
                    '🛑 Request completed (myStatus=3). Clearing background task data.');
                await prefs.remove('current_tracking_request');
                await prefs.remove('auth_token');
                return Future.value(false); // Stop the task
              }
            } catch (e) {
              debugPrint('⚠️ Could not parse myStatus from response: $e');
            }

            return Future.value(true);
          } else {
            debugPrint(
                '❌ Failed to send background location: ${response.statusCode} - ${response.body}');

            // If unauthorized, clear tokens
            if (response.statusCode == 401) {
              debugPrint('🔑 Auth failed - clearing tokens');
              await prefs.remove('current_tracking_request');
              await prefs.remove('auth_token');
              return Future.value(false);
            }

            return Future.value(false);
          }
        } catch (e) {
          debugPrint('💥 Background location update error: $e');

          // If it's a timeout or network error, keep trying
          if (e.toString().contains('timeout') ||
              e.toString().contains('network')) {
            return Future.value(true); // Continue trying
          }

          return Future.value(false);
        }
      }

      return Future.value(true);
    });
  }

  // Add comprehensive debug method
  Future<Map<String, dynamic>> debugLocationTracking() async {
    debugPrint('🔍 === LOCATION TRACKING DEBUG ===');

    final result = <String, dynamic>{};

    try {
      // Check tracking state
      result['isTracking'] = _isTracking;
      result['currentRequestId'] = _currentRequestId;
      result['hasActiveTimer'] = _locationTimer?.isActive ?? false;
      result['updateInterval'] = '${_minUpdateInterval.inSeconds} seconds';
      result['isBackupRunning'] = _isBackupRunning;
      result['hasBackupTimer'] = _backupCheckTimer?.isActive ?? false;
      debugPrint(
          '📊 Tracking State: $_isTracking, Request: $_currentRequestId');
      debugPrint('🕐 Timer Active: ${_locationTimer?.isActive ?? false}');
      debugPrint('⏱️ Update Interval: ${_minUpdateInterval.inSeconds} seconds');
      debugPrint('🔄 Auto Backup Running: $_isBackupRunning');
      debugPrint(
          '⏰ Backup Timer Active: ${_backupCheckTimer?.isActive ?? false}');

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      result['locationPermission'] = permission.toString();
      debugPrint('🔐 Location Permission: $permission');

      // Check location services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      result['locationServiceEnabled'] = serviceEnabled;
      debugPrint('📍 Location Services: $serviceEnabled');

      // Check auth token
      final authToken = await _authService.gettoken();
      result['hasAuthToken'] = authToken != null;
      result['tokenLength'] = authToken?.length ?? 0;
      debugPrint(
          '🔑 Auth Token: ${authToken != null ? 'present (${authToken.length} chars)' : 'missing'}');

      // Check SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final storedRequestId = prefs.getString('current_tracking_request');
      final storedToken = prefs.getString('auth_token');
      result['storedRequestId'] = storedRequestId;
      result['hasStoredToken'] = storedToken != null;
      debugPrint('💾 Stored Request ID: $storedRequestId');
      debugPrint(
          '💾 Stored Token: ${storedToken != null ? 'present (${storedToken.length} chars)' : 'missing'}');

      // Test location access
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        result['canGetLocation'] = true;
        result['currentLocation'] = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
        };
        debugPrint(
            '📍 Current Location: ${position.latitude}, ${position.longitude} (accuracy: ${position.accuracy})');
      } catch (e) {
        result['canGetLocation'] = false;
        result['locationError'] = e.toString();
        debugPrint('❌ Location Error: $e');
      }

      // Test API connectivity
      if (authToken != null) {
        try {
          final testResponse = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/auth/profile'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
          ).timeout(const Duration(seconds: 10));

          result['apiConnectivity'] = {
            'canConnect': true,
            'statusCode': testResponse.statusCode,
            'authValid': testResponse.statusCode == 200,
          };
          debugPrint(
              '🌐 API Test: ${testResponse.statusCode} ${testResponse.statusCode == 200 ? '✅' : '❌'}');
        } catch (e) {
          result['apiConnectivity'] = {
            'canConnect': false,
            'error': e.toString(),
          };
          debugPrint('🌐 API Test Failed: $e');
        }
      }

      // Check WorkManager status (Android only)
      if (Platform.isAndroid) {
        result['platform'] = 'Android';
        result['workManagerSupported'] = true;
        debugPrint('🤖 Platform: Android (WorkManager supported)');
      } else {
        result['platform'] = Platform.operatingSystem;
        result['workManagerSupported'] = false;
        debugPrint(
            '📱 Platform: ${Platform.operatingSystem} (WorkManager not supported)');
      }

      debugPrint('🔍 === DEBUG COMPLETE ===');
      return result;
    } catch (e) {
      debugPrint('💥 Debug Error: $e');
      result['debugError'] = e.toString();
      return result;
    }
  }

  // Start automatic backup system to monitor for untracked requests
  Future<void> startAutoBackupSystem() async {
    if (_isBackupRunning) {
      debugPrint('🔄 Auto backup system already running');
      return;
    }

    _isBackupRunning = true;
    debugPrint('🚀 Starting auto backup system for location tracking');

    // Check immediately
    await _checkForUntrackedRequests();

    // Set up periodic check every 2 minutes
    _backupCheckTimer?.cancel();
    _backupCheckTimer =
        Timer.periodic(const Duration(minutes: 2), (timer) async {
      if (!_isBackupRunning) {
        timer.cancel();
        return;
      }
      await _checkForUntrackedRequests();
    });
  }

  // Stop automatic backup system
  Future<void> stopAutoBackupSystem() async {
    debugPrint('🛑 Stopping auto backup system');
    _isBackupRunning = false;
    _backupCheckTimer?.cancel();
    _backupCheckTimer = null;
  }

  // Check for requests with myStatus = 2 that aren't being tracked
  Future<void> _checkForUntrackedRequests() async {
    try {
      debugPrint('🔍 Checking for untracked requests with myStatus = 2...');

      // Get auth token
      final authToken = await _authService.gettoken();
      if (authToken == null) {
        debugPrint('❌ No auth token for backup check');
        return;
      }

      // Fetch requests with myStatus = 2 from the server
      final response = await http.get(
        Uri.parse('$_baseUrl/requests/in-progress'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint(
            '❌ Failed to fetch in-progress requests: ${response.statusCode}');
        return;
      }

      final List<dynamic> requests = jsonDecode(response.body);
      debugPrint('📋 Found ${requests.length} in-progress requests');

      // Filter requests with myStatus = 2
      final untrackedRequests = requests.where((request) {
        final myStatus = request['myStatus'] as int?;
        final requestId = request['id'].toString();
        final isTracked = isTrackingRequest(requestId);

        debugPrint(
            '📊 Request $requestId: myStatus=$myStatus, isTracked=$isTracked');

        return myStatus == 2 && !isTracked;
      }).toList();

      if (untrackedRequests.isEmpty) {
        debugPrint('✅ All myStatus=2 requests are being tracked');
        return;
      }

      debugPrint(
          '🚨 Found ${untrackedRequests.length} untracked requests with myStatus=2');

      // If we're not currently tracking anything, start tracking the first untracked request
      if (!_isTracking) {
        final firstRequest = untrackedRequests.first;
        final requestId = firstRequest['id'].toString();

        debugPrint(
            '🎯 Auto-starting location tracking for request: $requestId');
        final success = await startTracking(requestId, myStatus: 2);
        debugPrint(success
            ? '✅ Successfully started tracking'
            : '❌ Failed to start tracking');
      } else {
        // If we're already tracking, check if the current request is still myStatus = 2
        final currentRequest = requests.firstWhere(
          (req) => req['id'].toString() == _currentRequestId,
          orElse: () => null,
        );

        if (currentRequest != null) {
          final currentMyStatus = currentRequest['myStatus'] as int?;
          debugPrint(
              '📊 Current request $_currentRequestId: myStatus=$currentMyStatus');

          if (currentMyStatus != 2) {
            debugPrint(
                '🔄 Current request myStatus changed from 2 to $currentMyStatus');

            // Stop current tracking and start new one
            await stopTracking();

            if (untrackedRequests.isNotEmpty) {
              final nextRequest = untrackedRequests.first;
              final nextRequestId = nextRequest['id'].toString();

              debugPrint('🎯 Switching to new request: $nextRequestId');
              final success = await startTracking(nextRequestId, myStatus: 2);
              debugPrint(success
                  ? '✅ Successfully switched tracking'
                  : '❌ Failed to switch tracking');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('💥 Error in backup request check: $e');
    }
  }

  // Manual method to check and start tracking untracked requests
  Future<List<Map<String, dynamic>>> checkAndStartUntrackedRequests() async {
    debugPrint('🔍 Manual check for untracked requests...');

    try {
      // Get auth token
      final authToken = await _authService.gettoken();
      if (authToken == null) {
        throw Exception('No auth token available');
      }

      // Fetch requests with myStatus = 2
      final response = await http.get(
        Uri.parse('$_baseUrl/requests/in-progress'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch requests: ${response.statusCode}');
      }

      final List<dynamic> requests = jsonDecode(response.body);

      // Filter untracked requests with myStatus = 2
      final untrackedRequests = requests
          .where((request) {
            final myStatus = request['myStatus'] as int?;
            final requestId = request['id'].toString();

            return myStatus == 2 && !isTrackingRequest(requestId);
          })
          .map((req) => {
                'id': req['id'],
                'userName': req['userName'],
                'myStatus': req['myStatus'],
                'pickupLocation': req['pickupLocation'],
                'deliveryLocation': req['deliveryLocation'],
              })
          .toList()
          .cast<Map<String, dynamic>>();

      debugPrint('📋 Found ${untrackedRequests.length} untracked requests');

      // Auto-start tracking for the first untracked request if not currently tracking
      if (untrackedRequests.isNotEmpty && !_isTracking) {
        final firstRequest = untrackedRequests.first;
        final requestId = firstRequest['id'].toString();

        debugPrint('🎯 Auto-starting tracking for request: $requestId');
        await startTracking(requestId, myStatus: 2);
      }

      return untrackedRequests;
    } catch (e) {
      debugPrint('💥 Error checking untracked requests: $e');
      return [];
    }
  }

  // Stop all location services including backup system
  Future<void> stopAllLocationServices() async {
    await stopTracking();
    await stopAutoBackupSystem();
    debugPrint('🛑 All location services stopped');
  }
}

// Global instance
final locationService = LocationService();
