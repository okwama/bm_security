import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';

class LocationPermissionService {
  static final LocationPermissionService _instance =
      LocationPermissionService._internal();
  factory LocationPermissionService() => _instance;
  LocationPermissionService._internal();

  // Permission status tracking
  PermissionStatus? _lastKnownStatus;
  bool _hasShownSettingsDialog = false;

  // Getters for current state
  bool get isPermanentlyDenied =>
      _lastKnownStatus == PermissionStatus.permanentlyDenied;
  bool get isGranted => _lastKnownStatus == PermissionStatus.granted;
  bool get isDenied => _lastKnownStatus == PermissionStatus.denied;

  /// Check if permissions are already granted (without triggering prompts)
  Future<bool> arePermissionsGranted() async {
    try {
      final status = await checkPermissionStatus();
      return status == PermissionStatus.granted ||
          status == PermissionStatus.limited;
    } catch (e) {
      return false;
    }
  }

  /// Check current permission status
  Future<PermissionStatus> checkPermissionStatus() async {
    try {
      _lastKnownStatus = await Permission.location.status;
      return _lastKnownStatus!;
    } catch (e) {
      return PermissionStatus.denied;
    }
  }

  /// Request location permissions with smart handling
  Future<bool> requestPermissions() async {
    try {

      // Check current status first
      final currentStatus = await checkPermissionStatus();

      // If already granted, return true immediately
      if (currentStatus == PermissionStatus.granted) {
        return true;
      }

      // If locationWhenInUse is granted, return true
      if (currentStatus == PermissionStatus.limited) {
        return true;
      }

      // If permanently denied, show settings dialog
      if (currentStatus == PermissionStatus.permanentlyDenied) {
        return await _showSettingsDialog();
      }

      // If denied but not permanently, show explanation first
      if (currentStatus == PermissionStatus.denied) {
        final shouldRequest = await _showPermissionExplanationDialog();
        if (!shouldRequest) {
          return false;
        }
      }

      // Now request permission (this triggers native prompt)
      final status = await Permission.location.request();
      _lastKnownStatus = status;
      if (status == PermissionStatus.granted) {
        return true;
      }

      // If location permission denied, try locationWhenInUse
      if (status == PermissionStatus.denied) {
        final whenInUseStatus = await Permission.locationWhenInUse.request();
        _lastKnownStatus = whenInUseStatus;

        if (whenInUseStatus == PermissionStatus.granted) {
          return true;
        }
      }

      // If still denied after native prompts, show final dialog
      if (status == PermissionStatus.denied ||
          status == PermissionStatus.permanentlyDenied) {
        return false;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check if location services are enabled
  Future<bool> checkLocationServices() async {
    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      return isEnabled;
    } catch (e) {
      return false;
    }
  }

  /// Show permission explanation dialog
  Future<bool> _showPermissionExplanationDialog() async {
    if (_hasShownSettingsDialog) {
      return false; // Don't show again in this session
    }

    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.location_on, color: Theme.of(Get.context!).primaryColor),
            const SizedBox(width: 8),
            const Text('Location Permission Required'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This app needs location access to track your position during security operations.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'Location tracking is essential for:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Real-time position monitoring'),
            Text('• Emergency response coordination'),
            Text('• Route optimization'),
            Text('• Security compliance'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
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

    if (result == true) {
      return await requestPermissions();
    }

    return false;
  }

  /// Show settings dialog for permanently denied permissions
  Future<bool> _showSettingsDialog() async {
    if (_hasShownSettingsDialog) {
      return false; // Don't show again in this session
    }

    _hasShownSettingsDialog = true;

    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.settings, color: Theme.of(Get.context!).primaryColor),
            const SizedBox(width: 8),
            const Text('Location Access Required'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location permission has been permanently denied. To use location features, please enable it in your device settings.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'How to enable:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('1. Go to Settings > Apps'),
            Text('2. Find "BM Security"'),
            Text('3. Tap "Permissions"'),
            Text('4. Enable "Location"'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
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

    if (result == true) {
      await openAppSettings();
      // Wait a moment for user to potentially change settings
      await Future.delayed(const Duration(seconds: 2));
      return await checkPermissionStatus() == PermissionStatus.granted;
    }

    return false;
  }

  /// Reset dialog state (call when app restarts)
  void resetDialogState() {
    _hasShownSettingsDialog = false;
  }

  /// Get permission status description
  String getPermissionStatusDescription() {
    switch (_lastKnownStatus) {
      case PermissionStatus.granted:
        return 'Location access granted';
      case PermissionStatus.denied:
        return 'Location access denied';
      case PermissionStatus.permanentlyDenied:
        return 'Location access permanently denied';
      case PermissionStatus.restricted:
        return 'Location access restricted';
      case PermissionStatus.limited:
        return 'Location access limited';
      default:
        return 'Location access unknown';
    }
  }
}
