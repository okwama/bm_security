import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bm_security/utils/auth_config.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';
import '../core/constants/app_constants.dart';

class ProfileService {
  static final String baseUrl = ApiConfig.baseUrl;

  // Security constants
  static const int _maxRetries = 3;
  static const int _timeoutSeconds = 30;
  static const int _maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const List<String> _allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];

  // Security event logging
  static void _logSecurityEvent(String event,
      {Map<String, dynamic>? metadata}) {
    final sanitizedMetadata =
        metadata?.map((k, v) => MapEntry(k, _sanitizeValue(k, v)));
    final logEntry = {
      'event': event,
      'timestamp': DateTime.now().toIso8601String(),
      'app': 'bm_security',
      if (sanitizedMetadata != null) 'metadata': sanitizedMetadata,
    };
    print('🔒 Security Event: ${json.encode(logEntry)}');
  }

  static dynamic _sanitizeValue(String key, dynamic value) {
    const sensitiveKeys = [
      'password',
      'token',
      'auth',
      'secret',
      'key',
      'bearer'
    ];
    if (sensitiveKeys.any((k) => key.toLowerCase().contains(k))) {
      return '[REDACTED]';
    }
    return value;
  }

  static Future<String?> _getAuthtoken() async {
    try {
      final box = const FlutterSecureStorage();
      final token = await box.read(key: 'token');

      if (token != null) {
        // Check if token is expired
        final tokenExpiry = await box.read(key: 'token_expiry');
        if (tokenExpiry != null) {
          final expiryDate = DateTime.tryParse(tokenExpiry);
          if (expiryDate != null && DateTime.now().isAfter(expiryDate)) {
            _logSecurityEvent('token_expired');
            await box.delete(key: 'token');
            await box.delete(key: 'token_expiry');
            return null;
          }
        }

        // Validate token format (basic JWT structure check)
        if (_isValidTokenFormat(token)) {
          return token;
        } else {
          _logSecurityEvent('invalid_token_format');
          box.remove('token');
          return null;
        }
      }
      return null;
    } catch (e) {
      _logSecurityEvent('token_retrieval_error',
          metadata: {'error': e.toString()});
      return null;
    }
  }

  static bool _isValidTokenFormat(String token) {
    // Basic JWT format validation (3 parts separated by dots)
    final parts = token.split('.');
    return parts.length == 3 && parts.every((part) => part.isNotEmpty);
  }

  static Future<Map<String, String>> _headers([String? contentType]) async {
    final token = await _getAuthtoken();
    final headers = {
      AppConstants.contentTypeHeader: contentType ?? AppConstants.applicationJson,
      'Accept': AppConstants.applicationJson,
      'User-Agent': 'BM-Security-App/1.0',
      'X-App-Version': '1.0.0',
      if (token != null) AppConstants.authorizationHeader: AppConstants.getBearerToken(token),
    };

    _logSecurityEvent('api_request_prepared', metadata: {
      'has_token': token != null,
      'content_type': contentType ?? 'application/json'
    });

    return headers;
  }

  static Future<http.Response> _makeSecureRequest(
      String method, String endpoint,
      {Map<String, dynamic>? body, String? contentType}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = await _headers(contentType);

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        _logSecurityEvent('api_request_attempt', metadata: {
          'method': method,
          'endpoint': endpoint,
          'attempt': attempt
        });

        http.Response response;

        switch (method.toUpperCase()) {
          case 'GET':
            response = await http
                .get(uri, headers: headers)
                .timeout(const Duration(seconds: _timeoutSeconds));
            break;
          case 'POST':
            response = await http
                .post(
                  uri,
                  headers: headers,
                  body: body != null ? json.encode(body) : null,
                )
                .timeout(const Duration(seconds: _timeoutSeconds));
            break;
          case 'PUT':
            response = await http
                .put(
                  uri,
                  headers: headers,
                  body: body != null ? json.encode(body) : null,
                )
                .timeout(const Duration(seconds: _timeoutSeconds));
            break;
          default:
            throw Exception('Unsupported HTTP method: $method');
        }

        _logSecurityEvent('api_response_received', metadata: {
          'status_code': response.statusCode,
          'endpoint': endpoint,
          'attempt': attempt
        });

        // Security status code handling
        if (response.statusCode == 401) {
          _logSecurityEvent('authentication_failed',
              metadata: {'endpoint': endpoint});
          final box = const FlutterSecureStorage();
          await box.delete(key: 'token');
          await box.delete(key: 'token_expiry');
          throw Exception('Session expired. Please login again.');
        }

        if (response.statusCode == 403) {
          _logSecurityEvent('authorization_failed',
              metadata: {'endpoint': endpoint});
          throw Exception('Access denied. Insufficient permissions.');
        }

        if (response.statusCode == 429) {
          _logSecurityEvent('rate_limit_exceeded',
              metadata: {'endpoint': endpoint});
          if (attempt < _maxRetries) {
            await Future.delayed(Duration(seconds: attempt * 2));
            continue;
          }
          throw Exception('Too many requests. Please try again later.');
        }

        return response;
      } catch (e) {
        _logSecurityEvent('api_request_error', metadata: {
          'endpoint': endpoint,
          'attempt': attempt,
          'error': e.toString()
        });

        if (attempt == _maxRetries) {
          _handleNetworkError(e);
          rethrow;
        }

        // Exponential backoff for retries
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    throw Exception('Max retries exceeded');
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await _getAuthtoken();
      _logSecurityEvent('profile_fetch_initiated',
          metadata: {'has_token': token != null});

      final response = await _makeSecureRequest('GET', '/auth/profile');

      if (response.statusCode != 200) {
        _logSecurityEvent('profile_fetch_failed',
            metadata: {'status_code': response.statusCode});
        throw Exception('Failed to fetch profile data');
      }

      try {
        final responseData = json.decode(response.body);
        _logSecurityEvent('profile_fetch_success');

        // Validate response structure
        if (responseData is! Map<String, dynamic>) {
          throw Exception('Invalid response format');
        }

        return responseData;
      } catch (e) {
        _logSecurityEvent('profile_response_parse_error',
            metadata: {'error': e.toString()});
        throw Exception('Invalid response from server');
      }
    } catch (e) {
      _logSecurityEvent('profile_fetch_error',
          metadata: {'error': e.toString()});
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      // Input validation and sanitization
      final sanitizedData = _sanitizeProfileData(data);

      _logSecurityEvent('profile_update_initiated',
          metadata: {'fields_count': sanitizedData.keys.length});

      final response =
          await _makeSecureRequest('PUT', '/auth/profile', body: sanitizedData);

      if (response.statusCode != 200) {
        _logSecurityEvent('profile_update_failed',
            metadata: {'status_code': response.statusCode});
        throw Exception('Failed to update profile');
      }

      final responseData = json.decode(response.body);
      _logSecurityEvent('profile_update_success');
      return responseData;
    } catch (e) {
      _logSecurityEvent('profile_update_error',
          metadata: {'error': e.toString()});
      rethrow;
    }
  }

  Map<String, dynamic> _sanitizeProfileData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};

    // Allow only specific fields for security
    const allowedFields = [
      'firstName',
      'lastName',
      'email',
      'phone',
      'bio',
      'department',
      'position',
      'emergencyContact'
    ];

    for (final entry in data.entries) {
      if (allowedFields.contains(entry.key)) {
        final value = entry.value;
        if (value is String) {
          // Basic XSS prevention
          sanitized[entry.key] = value
              .replaceAll('<', '&lt;')
              .replaceAll('>', '&gt;')
              .replaceAll('"', '&quot;')
              .trim();
        } else {
          sanitized[entry.key] = value;
        }
      }
    }

    return sanitized;
  }

  Future<Map<String, dynamic>> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      // Enhanced password validation for security app
      _validatePasswordStrength(currentPassword, newPassword, confirmPassword);

      _logSecurityEvent('password_update_initiated');

      final response =
          await _makeSecureRequest('POST', '/auth/profile/password', body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      });

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        _logSecurityEvent('password_update_failed',
            metadata: {'status_code': response.statusCode});
        throw Exception(error['message'] ?? 'Failed to update password');
      }

      _logSecurityEvent('password_update_success');
      final responseData = json.decode(response.body);

      // Force re-authentication after password change
      final box = const FlutterSecureStorage();
      await box.delete(key: 'token');
      await box.delete(key: 'token_expiry');

      return responseData;
    } catch (e) {
      _logSecurityEvent('password_update_error',
          metadata: {'error': e.toString()});
      rethrow;
    }
  }

  void _validatePasswordStrength(
      String current, String newPassword, String confirm) {
    if (current.isEmpty) {
      throw Exception('Current password is required');
    }

    if (newPassword.length < 8) {
      throw Exception('New password must be at least 8 characters long');
    }

    if (newPassword.length > 128) {
      throw Exception('Password is too long (maximum 128 characters)');
    }

    if (newPassword != confirm) {
      throw Exception('New passwords do not match');
    }

    if (newPassword == current) {
      throw Exception('New password must be different from current password');
    }

    // Security app requires strong passwords
    if (!_isPasswordStrong(newPassword)) {
      throw Exception('Password must contain at least:\n'
          '• One uppercase letter (A-Z)\n'
          '• One lowercase letter (a-z)\n'
          '• One number (0-9)\n'
          '• One special character (!@#\$%^&*)');
    }

    // Check for common weak passwords
    if (_isCommonPassword(newPassword)) {
      throw Exception(
          'Password is too common. Please choose a stronger password.');
    }
  }

  bool _isPasswordStrong(String password) {
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChars =
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return hasUppercase && hasLowercase && hasDigits && hasSpecialChars;
  }

  bool _isCommonPassword(String password) {
    const commonPasswords = [
      'password',
      '12345678',
      'qwerty123',
      'admin123',
      'password123',
      'security',
      'welcome123',
      'changeme',
      'letmein123'
    ];
    return commonPasswords.contains(password.toLowerCase());
  }

  Future<String> updateProfilePhoto(XFile imageFile) async {
    try {
      // Enhanced image validation for security
      await _validateImageFile(imageFile);

      final token = await _getAuthtoken();
      if (token == null) {
        _logSecurityEvent('profile_photo_upload_no_token');
        throw Exception('Authentication required');
      }

      _logSecurityEvent('profile_photo_upload_initiated', metadata: {
        'file_name': imageFile.name,
        'file_size': await imageFile.length(),
      });

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload'),
      );

      // Enhanced headers for security
      request.headers.addAll({
        AppConstants.authorizationHeader: AppConstants.getBearerToken(token),
        'User-Agent': 'BM-Security-App/1.0',
        'X-Upload-Type': 'profile-photo',
      });

      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));

      final response = await request.send().timeout(
            const Duration(seconds: _timeoutSeconds),
          );

      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        if (data['success'] == true &&
            data['data'] != null &&
            data['data']['url'] != null) {
          final imageUrl = data['data']['url'];

          // Validate returned URL for security
          if (_isValidImageUrl(imageUrl)) {
            _logSecurityEvent('profile_photo_upload_success',
                metadata: {'url_domain': Uri.parse(imageUrl).host});
            return imageUrl;
          } else {
            _logSecurityEvent('profile_photo_upload_invalid_url');
            throw Exception('Invalid image URL returned from server');
          }
        } else {
          _logSecurityEvent('profile_photo_upload_invalid_response');
          throw Exception('Invalid response format from upload server');
        }
      } else {
        _logSecurityEvent('profile_photo_upload_failed',
            metadata: {'status_code': response.statusCode});
        final errorData = json.decode(responseBody);
        throw Exception(
            errorData['message'] ?? 'Failed to update profile photo');
      }
    } catch (e) {
      _logSecurityEvent('profile_photo_upload_error',
          metadata: {'error': e.toString()});
      _handleNetworkError(e);
      rethrow;
    }
  }

  Future<void> _validateImageFile(XFile imageFile) async {
    // Check file size
    final fileSize = await imageFile.length();
    if (fileSize > _maxImageSizeBytes) {
      throw Exception(
          'Image too large. Maximum ${(_maxImageSizeBytes / (1024 * 1024)).round()}MB allowed.');
    }

    if (fileSize == 0) {
      throw Exception('Invalid image file (empty file).');
    }

    // Check file extension
    final extension = imageFile.name.split('.').last.toLowerCase();
    if (!_allowedImageTypes.contains(extension)) {
      throw Exception(
          'Invalid image format. Allowed: ${_allowedImageTypes.join(', ')}');
    }

    // Basic file header validation (magic bytes)
    final bytes = await imageFile.readAsBytes();
    if (!_hasValidImageHeader(bytes, extension)) {
      throw Exception('Invalid image file format.');
    }
  }

  bool _hasValidImageHeader(List<int> bytes, String extension) {
    if (bytes.length < 4) return false;

    // Check magic bytes for common image formats
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return bytes[0] == 0xFF && bytes[1] == 0xD8;
      case 'png':
        return bytes[0] == 0x89 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x4E &&
            bytes[3] == 0x47;
      case 'webp':
        return bytes.length >= 12 &&
            bytes[8] == 0x57 &&
            bytes[9] == 0x45 &&
            bytes[10] == 0x42 &&
            bytes[11] == 0x50;
      default:
        return false;
    }
  }

  bool _isValidImageUrl(String url) {
    try {
      final uri = Uri.parse(url);
      // Ensure HTTPS for security
      if (uri.scheme != 'https') return false;

      // Validate domain (add your trusted domains)
      const trustedDomains = [
        'your-cdn-domain.com',
        'secure-uploads.yourdomain.com',
        // Add your trusted image hosting domains
      ];

      // For development, you might want to allow any domain
      // In production, restrict to trusted domains only
      return trustedDomains.contains(uri.host) ||
          uri.host.endsWith('.amazonaws.com') || // AWS S3
          uri.host.endsWith('.cloudfront.net'); // CloudFront
    } catch (e) {
      return false;
    }
  }

  static void _handleNetworkError(dynamic error) {
    _logSecurityEvent('network_error', metadata: {'error': error.toString()});

    if (error is http.ClientException) {
      _logSecurityEvent('connection_error');
      throw Exception(
          'Unable to connect to server. Please check your internet connection.');
    } else if (error is FormatException) {
      _logSecurityEvent('data_format_error');
      throw Exception('Invalid data received from server.');
    } else if (error.toString().contains('TimeoutException')) {
      _logSecurityEvent('request_timeout');
      throw Exception('Request timed out. Please try again.');
    } else {
      throw Exception('Network error occurred. Please try again.');
    }
  }

  // Utility method for secure logout
  static Future<void> secureLogout() async {
    try {
      _logSecurityEvent('secure_logout_initiated');

      final box = const FlutterSecureStorage();
      await box.delete(key: 'token');
      await box.delete(key: 'token_expiry');
      await box.delete(key: 'user_data');

      // Optional: Call logout endpoint to invalidate server-side token
      try {
        final token = await _getAuthtoken();
        if (token != null) {
          await _makeSecureRequest('POST', '/auth/logout');
        }
      } catch (e) {
        // Don't fail logout if server call fails
        _logSecurityEvent('logout_server_call_failed',
            metadata: {'error': e.toString()});
      }

      _logSecurityEvent('secure_logout_completed');
    } catch (e) {
      _logSecurityEvent('secure_logout_error',
          metadata: {'error': e.toString()});
      rethrow;
    }
  }
}
