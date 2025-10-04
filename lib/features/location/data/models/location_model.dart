import '../../domain/entities/location_entity.dart';

class LocationModel extends LocationEntity {
  const LocationModel({
    required super.id,
    required super.requestId,
    required super.staffId,
    required super.latitude,
    required super.longitude,
    required super.capturedAt,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as int,
      requestId: json['requestId'] as int? ?? json['request_id'] as int? ?? 0,
      staffId: json['staffId'] as int? ?? json['staff_id'] as int? ?? 0,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      capturedAt: json['capturedAt'] != null
          ? DateTime.parse(json['capturedAt'] as String)
          : json['captured_at'] != null
              ? DateTime.parse(json['captured_at'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestId': requestId,
      'staffId': staffId,
      'latitude': latitude,
      'longitude': longitude,
      'capturedAt': capturedAt.toIso8601String(),
    };
  }

  LocationModel copyWith({
    int? id,
    int? requestId,
    int? staffId,
    double? latitude,
    double? longitude,
    DateTime? capturedAt,
  }) {
    return LocationModel(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      staffId: staffId ?? this.staffId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      capturedAt: capturedAt ?? this.capturedAt,
    );
  }
}
