import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'location_permission_service.dart';
import 'location_tracker_service.dart';
import 'location_api_service.dart';

class LocationManager {
  static final LocationManager _instance = LocationManager._internal();
  factory LocationManager() => _instance;
  LocationManager._internal();

  // Services
  final LocationPermissionService _permissionService =
      LocationPermissionService();
  final LocationTrackerService _trackerService = LocationTrackerService();
  final LocationApiService _apiService = LocationApiService();

  // State
  bool _isInitialized = false;
  bool _isPermissionDenied = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isPermissionDenied => _isPermissionDenied;
  bool get isTracking => _trackerService.isTracking;
  String? get currentRequestId => _trackerService.currentRequestId;

  /// Initialize location services with smart permission handling
  Future<bool> initialize() async {
    try {

      // Check if already initialized
      if (_isInitialized) {
        return true;
      }

      // Check if permissions are already granted
      final permissionsGranted =
          await _permissionService.arePermissionsGranted();

      if (permissionsGranted) {
      } else {
        // Check detailed permission status for handling
        final permissionStatus =
            await _permissionService.checkPermissionStatus();

        // If permanently denied, show settings dialog
        if (permissionStatus == PermissionStatus.permanentlyDenied) {
          _isPermissionDenied = true;
          await _showPermissionDeniedDialog();
          return false;
        }
        // If denied but not permanently, request permissions
        else if (permissionStatus == PermissionStatus.denied) {
          final granted = await _permissionService.requestPermissions();

          if (!granted) {
            _isPermissionDenied = true;
            return false;
          }
        }
      }

      // Check location services
      final servicesEnabled = await _permissionService.checkLocationServices();
      if (!servicesEnabled) {
        await _showLocationServicesDialog();
        return false;
      }

      // Restore tracking state if app was restarted
      await _restoreTrackingState();

      _isInitialized = true;
      _isPermissionDenied = false;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Start tracking with smart error handling
  Future<bool> startTracking(String requestId) async {
    try {
          '🎯 Location manager: Starting tracking for request: $requestId');

      // Check if already tracking this request
      if (_trackerService.isTrackingRequest(requestId)) {
        return true;
      }

      // Ensure location services are ready
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          return false;
        }
      }

      // Start tracking
      final success = await _trackerService.startTracking(requestId);

      if (success) {
        _showTrackingStartedDialog(requestId);
      } else {
        await _handleTrackingError();
      }

      return success;
    } catch (e) {
      await _handleTrackingError();
      return false;
    }
  }

  /// Stop all tracking
  Future<void> stopTracking() async {
    try {
      await _trackerService.stopTracking();
    } catch (e) {
    }
  }

  /// Stop tracking for specific request
  Future<void> stopTrackingForRequest(String requestId) async {
    try {
      if (_trackerService.isTrackingRequest(requestId)) {
            '🛑 Location manager: Stopping tracking for request: $requestId');
        await _trackerService.stopTracking();
            '✅ Location manager: Tracking stopped for request: $requestId');
      }
    } catch (e) {
    }
  }

  /// Check if tracking specific request
  bool isTrackingRequest(String requestId) {
    return _trackerService.isTrackingRequest(requestId);
  }

  /// Get tracking status
  Map<String, dynamic> getTrackingStatus() {
    return _trackerService.getTrackingStatus();
  }

  /// Restore tracking state from persistence
  Future<void> _restoreTrackingState() async {
    try {
      final restored = await _trackerService.restoreTrackingState();
      if (restored) {
      } else {
      }
    } catch (e) {
    }
  }

  /// Handle tracking errors with user feedback
  Future<void> _handleTrackingError() async {
    try {
      // Check if it's a permission issue
      final permissionStatus = await _permissionService.checkPermissionStatus();

      if (permissionStatus == PermissionStatus.permanentlyDenied) {
        await _showPermissionDeniedDialog();
      } else if (permissionStatus != PermissionStatus.granted) {
        await _showPermissionRequestDialog();
      } else {
        await _showGeneralErrorDialog();
      }
    } catch (e) {
    }
  }

  /// Show permission denied dialog
  Future<void> _showPermissionDeniedDialog() async {
    await Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.location_off, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Location Access Required'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location tracking is essential for security operations. Please enable location access in your device settings.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'Without location access, you cannot:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Track your position during operations'),
            Text('• Send location updates to headquarters'),
            Text('• Receive emergency assistance'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _permissionService.requestPermissions();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(Get.context!).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  /// Show permission request dialog
  Future<void> _showPermissionRequestDialog() async {
    await Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.location_on, color: Theme.of(Get.context!).primaryColor),
            const SizedBox(width: 8),
            const Text('Enable Location Access'),
          ],
        ),
        content: const Text(
          'This app needs location access to track your position during security operations. Please grant location permission.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _permissionService.requestPermissions();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(Get.context!).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Grant Permission'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  /// Show location services dialog
  Future<void> _showLocationServicesDialog() async {
    await Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.gps_off, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Location Services Disabled'),
          ],
        ),
        content: const Text(
          'Please enable location services in your device settings to use location tracking features.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Open location settings
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(Get.context!).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  /// Show general error dialog
  Future<void> _showGeneralErrorDialog() async {
    await Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Location Error'),
          ],
        ),
        content: const Text(
          'Unable to start location tracking. Please check your GPS signal and try again.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(Get.context!).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  /// Show tracking started dialog
  void _showTrackingStartedDialog(String requestId) {
    Get.snackbar(
      'Location Tracking Started',
      'Your position is now being tracked for request #$requestId',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.withValues(alpha: 0.1),
      colorText: Colors.green,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.location_on, color: Colors.green),
    );
  }

  /// Reset manager state (for logout)
  void reset() {
    _isInitialized = false;
    _isPermissionDenied = false;
    _permissionService.resetDialogState();
  }
}
