part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LoginEvent extends AuthEvent {
  final String employeeNumber;
  final String password;

  const LoginEvent({
    required this.employeeNumber,
    required this.password,
  });

  @override
  List<Object> get props => [employeeNumber, password];
}

class GetCurrentUserEvent extends AuthEvent {
  const GetCurrentUserEvent();
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

class TokenExpiredEvent extends AuthEvent {
  final String message;

  const TokenExpiredEvent(this.message);

  @override
  List<Object> get props => [message];
}
