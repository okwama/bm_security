import 'package:equatable/equatable.dart';

class LocationEntity extends Equatable {
  final int id;
  final int requestId;
  final int staffId;
  final double latitude;
  final double longitude;
  final DateTime capturedAt;

  const LocationEntity({
    required this.id,
    required this.requestId,
    required this.staffId,
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
  });

  @override
  List<Object?> get props => [
        id,
        requestId,
        staffId,
        latitude,
        longitude,
        capturedAt,
      ];

  LocationEntity copyWith({
    int? id,
    int? requestId,
    int? staffId,
    double? latitude,
    double? longitude,
    DateTime? capturedAt,
  }) {
    return LocationEntity(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      staffId: staffId ?? this.staffId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      capturedAt: capturedAt ?? this.capturedAt,
    );
  }
}

class LocationUpdateEntity extends Equatable {
  final int requestId;
  final double latitude;
  final double longitude;

  const LocationUpdateEntity({
    required this.requestId,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [requestId, latitude, longitude];
}
