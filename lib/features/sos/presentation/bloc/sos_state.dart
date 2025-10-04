part of 'sos_bloc.dart';

abstract class SOSState extends Equatable {
  const SOSState();

  @override
  List<Object?> get props => [];
}

class SOSInitial extends SOSState {}

class SOSLoading extends SOSState {}

class SOSSuccess extends SOSState {}

class SOSError extends SOSState {
  final String message;

  const SOSError(this.message);

  @override
  List<Object?> get props => [message];
}
