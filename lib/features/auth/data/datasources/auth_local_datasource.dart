import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<UserModel?> getCachedUser();
  Future<void> cacheUser(UserModel user);
  Future<void> clearCache();
  Future<String?> getToken();
  Future<void> saveToken(String token);
  Future<void> clearToken();
  Future<String?> getRefreshToken();
  Future<void> saveRefreshToken(String refreshToken);
  Future<void> clearRefreshToken();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage storage;

  AuthLocalDataSourceImpl({required this.storage});

  @override
  Future<UserModel?> getCachedUser() async {
    final userJson = await storage.read(key: AppConstants.userKey);
    if (userJson != null) {
      return UserModel.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    await storage.write(key: AppConstants.userKey, value: jsonEncode(user.toJson()));
  }

  @override
  Future<void> clearCache() async {
    await storage.delete(key: AppConstants.userKey);
  }

  @override
  Future<String?> getToken() async {
    return await storage.read(key: AppConstants.accessTokenKey);
  }

  @override
  Future<void> saveToken(String token) async {
    await storage.write(key: AppConstants.accessTokenKey, value: token);
  }

  @override
  Future<void> clearToken() async {
    await storage.delete(key: AppConstants.accessTokenKey);
  }

  @override
  Future<String?> getRefreshToken() async {
    return await storage.read(key: AppConstants.refreshTokenKey);
  }

  @override
  Future<void> saveRefreshToken(String refreshToken) async {
    await storage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
  }

  @override
  Future<void> clearRefreshToken() async {
    await storage.delete(key: AppConstants.refreshTokenKey);
  }
}

