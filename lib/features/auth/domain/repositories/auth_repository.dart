import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login({
    required String employeeNumber,
    required String password,
  });

  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String employeeNumber,
    required String password,
    required String phone,
    required String role,
  });

  Future<Either<Failure, UserEntity>> getCurrentUser();

  Future<Either<Failure, void>> logout([String? refreshToken]);

  Future<Either<Failure, bool>> isLoggedIn();

  Future<Either<Failure, String>> getToken();

  Future<Either<Failure, void>> saveToken(String token);

  Future<Either<Failure, void>> saveUser(UserEntity user);

  Future<Either<Failure, Map<String, dynamic>>> refreshToken(String refreshToken);
}
