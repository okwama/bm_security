import 'dart:convert';

enum SOSStatus { active, resolved, cancelled }

class SOSAlert {
  final int? id;
  final int userId;
  final String userName;
  final String userPhone;
  final String distressType;
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime timestamp;
  final SOSStatus status;
  final DateTime? resolvedAt;

  SOSAlert({
    this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.distressType,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.timestamp,
    required this.status,
    this.resolvedAt,
  });

  factory SOSAlert.fromJson(Map<String, dynamic> json) {
    return SOSAlert(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      userPhone: json['userPhone'],
      distressType: json['distressType'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      address: json['address'],
      timestamp: DateTime.parse(json['createdAt']),
      status: SOSStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => SOSStatus.active,
      ),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'distressType': distressType,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'status': status.toString().split('.').last,
    };
  }
}
