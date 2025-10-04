import 'package:equatable/equatable.dart';
import '../../domain/entities/location_entity.dart';

abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationUpdated extends LocationState {
  final String message;

  const LocationUpdated({required this.message});

  @override
  List<Object?> get props => [message];
}

class LocationHistoryLoaded extends LocationState {
  final List<LocationEntity> locations;

  const LocationHistoryLoaded({required this.locations});

  @override
  List<Object?> get props => [locations];
}

class LocationTrackingStarted extends LocationState {
  final int requestId;

  const LocationTrackingStarted({required this.requestId});

  @override
  List<Object?> get props => [requestId];
}

class LocationTrackingStopped extends LocationState {}

class LocationError extends LocationState {
  final String message;

  const LocationError({required this.message});

  @override
  List<Object?> get props => [message];
}
