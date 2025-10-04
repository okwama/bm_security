import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase implements UseCase<UserEntity, LoginParams> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(LoginParams params) async {
    return await repository.login(
      employeeNumber: params.employeeNumber,
      password: params.password,
    );
  }
}

class LoginParams extends Equatable {
  final String employeeNumber;
  final String password;

  const LoginParams({
    required this.employeeNumber,
    required this.password,
  });

  @override
  List<Object> get props => [employeeNumber, password];
}
