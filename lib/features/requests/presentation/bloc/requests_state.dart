part of 'requests_bloc.dart';

abstract class RequestsState extends Equatable {
  const RequestsState();

  @override
  List<Object?> get props => [];
}

class RequestsInitial extends RequestsState {}

class RequestsLoading extends RequestsState {}

class RequestsLoaded extends RequestsState {
  final List<RequestEntity> requests;

  const RequestsLoaded(this.requests);

  @override
  List<Object?> get props => [requests];
}

class RequestsError extends RequestsState {
  final String message;

  const RequestsError(this.message);

  @override
  List<Object?> get props => [message];
}
