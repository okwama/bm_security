part of 'requests_bloc.dart';

abstract class RequestsEvent extends Equatable {
  const RequestsEvent();

  @override
  List<Object?> get props => [];
}

class LoadRequestsEvent extends RequestsEvent {
  final int? status;
  final int? teamId;
  final int? staffId;

  const LoadRequestsEvent({
    this.status,
    this.teamId,
    this.staffId,
  });

  @override
  List<Object?> get props => [status, teamId, staffId];
}

class UpdateRequestStatusEvent extends RequestsEvent {
  final int requestId;
  final int newStatus;
  final int? staffId;
  final double? latitude;
  final double? longitude;
  final int? status;
  final int? teamId;

  const UpdateRequestStatusEvent({
    required this.requestId,
    required this.newStatus,
    this.staffId,
    this.latitude,
    this.longitude,
    this.status,
    this.teamId,
  });

  @override
  List<Object?> get props => [
        requestId,
        newStatus,
        staffId,
        latitude,
        longitude,
        status,
        teamId,
      ];
}

class RefreshRequestsEvent extends RequestsEvent {
  final int? status;
  final int? teamId;
  final int? staffId;

  const RefreshRequestsEvent({
    this.status,
    this.teamId,
    this.staffId,
  });

  @override
  List<Object?> get props => [status, teamId, staffId];
}
