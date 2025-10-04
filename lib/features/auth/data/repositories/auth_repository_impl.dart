import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, UserEntity>> login({
    required String employeeNumber,
    required String password,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = await remoteDataSource.login(
          employeeNumber: employeeNumber,
          password: password,
        );
        
        // Cache the user data
        await localDataSource.cacheUser(userModel);
        
        // Save the token (it's already saved in AppConstants.authToken by the remote data source)
        // You can also save it to local storage if needed
        
        return Right(userModel.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, code: e.code));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(message: e.message, code: e.code));
      } on AuthenticationException catch (e) {
        return Left(AuthenticationFailure(message: e.message, code: e.code));
      } on ValidationException catch (e) {
        return Left(ValidationFailure(message: e.message, code: e.code));
      }
    } else {
      // Try to get cached user data when offline
      final cachedUser = await localDataSource.getCachedUser();
      if (cachedUser != null) {
        return Right(cachedUser.toEntity());
      } else {
        return const Left(NetworkFailure(message: 'No internet connection and no cached data'));
      }
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String employeeNumber,
    required String password,
    required String phone,
    required String role,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = await remoteDataSource.register(
          name: name,
          employeeNumber: employeeNumber,
          password: password,
          phone: phone,
          role: role,
        );
        
        // Cache the user data
        await localDataSource.cacheUser(userModel);
        
        return Right(userModel.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, code: e.code));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(message: e.message, code: e.code));
      } on ValidationException catch (e) {
        return Left(ValidationFailure(message: e.message, code: e.code));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      // First check if we have a valid token
      final token = await localDataSource.getToken();
      if (token == null) {
        return const Left(AuthenticationFailure(message: 'No authentication token found'));
      }

      // If we have internet connection, validate token with server
      if (await networkInfo.isConnected) {
        try {
          // Verify token with server by getting current user
          final userModel = await remoteDataSource.getCurrentUser(token);
          // Update cached user data with fresh data from server
          await localDataSource.cacheUser(userModel);
          return Right(userModel.toEntity());
        } on AuthenticationException catch (e) {
          // Token is invalid or expired, clear local data
          await localDataSource.clearCache();
          await localDataSource.clearToken();
          return Left(AuthenticationFailure(message: e.message, code: e.code));
        } on ServerException catch (e) {
          // Server error, try to return cached data if available
          final cachedUser = await localDataSource.getCachedUser();
          if (cachedUser != null) {
            return Right(cachedUser.toEntity());
          }
          return Left(ServerFailure(message: e.message, code: e.code));
        } on NetworkException catch (e) {
          // Network error, try to return cached data if available
          final cachedUser = await localDataSource.getCachedUser();
          if (cachedUser != null) {
            return Right(cachedUser.toEntity());
          }
          return Left(NetworkFailure(message: e.message, code: e.code));
        }
      } else {
        // No internet connection, return cached user if available
        final cachedUser = await localDataSource.getCachedUser();
        if (cachedUser != null) {
          return Right(cachedUser.toEntity());
        } else {
          return const Left(NetworkFailure(message: 'No internet connection and no cached user data'));
        }
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, code: e.code));
    }
  }


  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    try {
      final token = await localDataSource.getToken();
      final user = await localDataSource.getCachedUser();
      return Right(token != null && user != null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, code: e.code));
    }
  }

  @override
  Future<Either<Failure, String>> getToken() async {
    try {
      final token = await localDataSource.getToken();
      if (token != null) {
        return Right(token);
      } else {
        return const Left(CacheFailure(message: 'No token found'));
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, code: e.code));
    }
  }

  @override
  Future<Either<Failure, void>> saveToken(String token) async {
    try {
      await localDataSource.saveToken(token);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, code: e.code));
    }
  }

  @override
  Future<Either<Failure, void>> saveUser(UserEntity user) async {
    try {
      final userModel = UserModel.fromEntity(user);
      await localDataSource.cacheUser(userModel);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, code: e.code));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> refreshToken(String refreshToken) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.refreshToken(refreshToken);
        
        // Save new tokens
        if (response['accessToken'] != null) {
          await localDataSource.saveToken(response['accessToken']);
        }
        if (response['refreshToken'] != null) {
          await localDataSource.saveRefreshToken(response['refreshToken']);
        }
        if (response['user'] != null) {
          final userModel = UserModel.fromJson(response['user']);
          await localDataSource.cacheUser(userModel);
        }
        
        return Right(response);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, code: e.code));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(message: e.message, code: e.code));
      } on AuthenticationException catch (e) {
        return Left(AuthenticationFailure(message: e.message, code: e.code));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> logout([String? refreshToken]) async {
    try {
      // Get refresh token if not provided
      final tokenToUse = refreshToken ?? await localDataSource.getRefreshToken();
      
      // Call server logout if connected
      if (await networkInfo.isConnected) {
        try {
          await remoteDataSource.logout(tokenToUse);
        } catch (e) {
          // Don't fail logout if server call fails
          print('Server logout failed: $e');
        }
      }
      
      // Clear local data
      await localDataSource.clearCache();
      await localDataSource.clearToken();
      await localDataSource.clearRefreshToken();
      
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message, code: e.code));
    }
  }
}
