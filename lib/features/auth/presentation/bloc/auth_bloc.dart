import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../../../core/errors/failures.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.getCurrentUserUseCase,
  }) : super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<GetCurrentUserEvent>(_onGetCurrentUser);
    on<LogoutEvent>(_onLogout);
    on<TokenExpiredEvent>(_onTokenExpired);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await loginUseCase(LoginParams(
      employeeNumber: event.employeeNumber,
      password: event.password,
    ));

    result.fold(
      (failure) => emit(AuthError(_mapFailureToMessage(failure))),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onGetCurrentUser(GetCurrentUserEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await getCurrentUserUseCase();

    result.fold(
      (failure) => emit(AuthError(_mapFailureToMessage(failure))),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    emit(AuthUnauthenticated());
  }

  Future<void> _onTokenExpired(TokenExpiredEvent event, Emitter<AuthState> emit) async {
    emit(AuthTokenExpired(event.message));
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server error. Please try again later.';
      case NetworkFailure:
        return 'No internet connection. Please check your network.';
      case AuthenticationFailure:
        return 'Invalid email or password.';
      case ValidationFailure:
        return 'Please check your input and try again.';
      case CacheFailure:
        return 'Local data error. Please try again.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
