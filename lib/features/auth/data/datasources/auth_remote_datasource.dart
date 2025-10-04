import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({
    required String employeeNumber,
    required String password,
  });

  Future<UserModel> register({
    required String name,
    required String employeeNumber,
    required String password,
    required String phone,
    required String role,
  });

  Future<UserModel> getCurrentUser(String token);
  Future<Map<String, dynamic>> refreshToken(String refreshToken);
  Future<void> logout(String? refreshToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserModel> login({
    required String employeeNumber,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        '${AppConstants.baseUrl}/auth/login',
        data: {
          'employeeNumber': employeeNumber,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final userModel = UserModel.fromJson(response.data['user']);
        // Save the access token and refresh token to secure storage
        if (response.data['accessToken'] != null) {
          AppConstants.authToken = response.data['accessToken'];
          // Also save to secure storage
          const storage = FlutterSecureStorage();
          await storage.write(key: AppConstants.accessTokenKey, value: response.data['accessToken']);
          
          // Save refresh token if provided
          if (response.data['refreshToken'] != null) {
            await storage.write(key: AppConstants.refreshTokenKey, value: response.data['refreshToken']);
          }
        }
        return userModel;
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Login failed',
          code: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw NetworkException(
          message: 'Connection timeout. Please check your internet connection.',
          code: e.response?.statusCode,
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException(
          message: 'No internet connection. Please check your network.',
          code: e.response?.statusCode,
        );
      } else if (e.response?.statusCode == 401) {
        throw AuthenticationException(
          message: 'Invalid email or password',
          code: 401,
        );
      } else {
        throw ServerException(
          message: e.response?.data?['message'] ?? 'Login failed',
          code: e.response?.statusCode,
        );
      }
    }
  }

  @override
  Future<UserModel> register({
    required String name,
    required String employeeNumber,
    required String password,
    required String phone,
    required String role,
  }) async {
    try {
      final response = await dio.post(
        '${AppConstants.baseUrl}/auth/register',
        data: {
          'name': name,
          'employeeNumber': employeeNumber,
          'password': password,
          'phone': phone,
          'role': role,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Registration failed',
          code: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw NetworkException(
          message: 'Connection timeout. Please check your internet connection.',
          code: e.response?.statusCode,
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException(
          message: 'No internet connection. Please check your network.',
          code: e.response?.statusCode,
        );
      } else if (e.response?.statusCode == 400) {
        throw ValidationException(
          message: e.response?.data?['message'] ?? 'Invalid registration data',
          code: 400,
        );
      } else {
        throw ServerException(
          message: e.response?.data?['message'] ?? 'Registration failed',
          code: e.response?.statusCode,
        );
      }
    }
  }

  @override
  Future<UserModel> getCurrentUser(String token) async {
    try {
      final response = await dio.get(
        '${AppConstants.baseUrl}/auth/profile',
        options: Options(
          headers: {
            AppConstants.authorizationHeader: AppConstants.getBearerToken(token),
          },
        ),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to get user profile',
          code: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw NetworkException(
          message: 'Connection timeout. Please check your internet connection.',
          code: e.response?.statusCode,
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException(
          message: 'No internet connection. Please check your network.',
          code: e.response?.statusCode,
        );
      } else if (e.response?.statusCode == 401) {
        throw AuthenticationException(
          message: 'Invalid or expired token',
          code: 401,
        );
      } else {
        throw ServerException(
          message: e.response?.data?['message'] ?? 'Failed to get user profile',
          code: e.response?.statusCode,
        );
      }
    }
  }

  @override
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await dio.post(
        '${AppConstants.baseUrl}/auth/refresh',
        data: {
          'refreshToken': refreshToken,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Token refresh failed',
          code: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw NetworkException(
          message: 'Connection timeout. Please check your internet connection.',
          code: e.response?.statusCode,
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException(
          message: 'No internet connection. Please check your network.',
          code: e.response?.statusCode,
        );
      } else if (e.response?.statusCode == 401) {
        throw AuthenticationException(
          message: 'Invalid or expired refresh token',
          code: 401,
        );
      } else {
        throw ServerException(
          message: e.response?.data?['message'] ?? 'Token refresh failed',
          code: e.response?.statusCode,
        );
      }
    }
  }

  @override
  Future<void> logout(String? refreshToken) async {
    try {
      final response = await dio.post(
        '${AppConstants.baseUrl}/auth/logout',
        data: refreshToken != null ? {'refreshToken': refreshToken} : {},
        options: Options(
          headers: {
            AppConstants.authorizationHeader: AppConstants.getBearerToken(await _getTokenFromStorage()),
          },
        ),
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: response.data['message'] ?? 'Logout failed',
          code: response.statusCode,
        );
      }
    } on DioException catch (e) {
      // Don't throw on logout errors, just log them
      print('Logout error: ${e.message}');
    }
  }

  Future<String> _getTokenFromStorage() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: AppConstants.accessTokenKey);
      if (token != null && token.isNotEmpty) {
        return token;
      }
      // Fallback to AppConstants if storage is empty
      return AppConstants.authToken;
    } catch (e) {
      return AppConstants.authToken;
    }
  }
}
