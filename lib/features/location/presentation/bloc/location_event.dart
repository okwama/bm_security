import 'package:equatable/equatable.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

class UpdateLocationEvent extends LocationEvent {
  final int requestId;
  final double latitude;
  final double longitude;

  const UpdateLocationEvent({
    required this.requestId,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [requestId, latitude, longitude];
}

class LoadLocationHistoryEvent extends LocationEvent {
  final int requestId;

  const LoadLocationHistoryEvent({required this.requestId});

  @override
  List<Object?> get props => [requestId];
}

class StartLocationTrackingEvent extends LocationEvent {
  final int requestId;

  const StartLocationTrackingEvent({required this.requestId});

  @override
  List<Object?> get props => [requestId];
}

class StopLocationTrackingEvent extends LocationEvent {
  const StopLocationTrackingEvent();
}
