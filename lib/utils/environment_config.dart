import 'package:flutter/foundation.dart';

class EnvironmentConfig {
  static const String _devBaseUrl = 'http://192.168.100.2:3000/api/v1'; // Update this to your computer's IP
  static const String _stagingBaseUrl =
      'https://bm-server-staging.vercel.app/api';
  static const String _prodBaseUrl = 'https://bm-server.vercel.app/api';

  // Environment detection
  static bool get isDevelopment => kDebugMode;
  static bool get isProduction => !kDebugMode;

  // Get base URL based on environment
  static String get baseUrl {
    if (isDevelopment) {
      return _devBaseUrl;
    } else {
      // In production, use staging for now (change to _prodBaseUrl when ready)
      return _prodBaseUrl;
    }
  }

  // Get environment name
  static String get environmentName {
    if (isDevelopment) {
      return 'Development';
    } else {
      return 'Production';
    }
  }

  // Get API timeout duration
  static Duration get apiTimeout {
    if (isDevelopment) {
      return const Duration(seconds: 30); // Longer timeout for development
    } else {
      return const Duration(seconds: 15); // Shorter timeout for production
    }
  }

  // Get location update interval
  static Duration get locationUpdateInterval {
    if (isDevelopment) {
      return const Duration(
          seconds: 15); // More frequent updates in development
    } else {
      return const Duration(seconds: 30); // Standard interval in production
    }
  }

  // Get location accuracy
  static String get locationAccuracy {
    if (isDevelopment) {
      return 'high'; // High accuracy for development
    } else {
      return 'medium'; // Balanced accuracy for production
    }
  }

  // Debug information
  static Map<String, dynamic> get debugInfo {
    return {
      'environment': environmentName,
      'baseUrl': baseUrl,
      'apiTimeout': apiTimeout.inSeconds,
      'locationUpdateInterval': locationUpdateInterval.inSeconds,
      'locationAccuracy': locationAccuracy,
      'isDebugMode': kDebugMode,
    };
  }

  // Print debug info
  static void printDebugInfo() {
    print('Environment Configuration:');
    print('  Base URL: $baseUrl');
    print('  API Timeout: ${apiTimeout.inSeconds}s');
    print('  Location Update Interval: ${locationUpdateInterval.inSeconds}s');
  }
}
