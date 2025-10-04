import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

class ServerFailure extends Failure {
  const ServerFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

class CacheFailure extends Failure {
  const CacheFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

class ValidationFailure extends Failure {
  const ValidationFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

class PermissionFailure extends Failure {
  const PermissionFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

class LocationFailure extends Failure {
  const LocationFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}
