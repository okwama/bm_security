import 'package:bm_security/models/outlet_model.dart';
import 'package:flutter/material.dart';

class JourneyPlan {
  // Status constants
  static const int statusPending = 0;
  static const int statusCheckedIn = 1;
  static const int statusInProgress = 2;
  static const int statusCheckedOut = 3;
  static const int statusCancelled = 4;

  final int? id;
  final DateTime date;
  final String time;
  
  final int userId; // User account for the location
  final int? guardId; // Guard who performed the check-in
  
  final int status;
  final String? notes;
  
  // Check-in specific fields
  final DateTime? checkInTime;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final String? checkInQrCode;
  final String? checkInImageUrl;
  final String? checkInDeviceInfo;
  
  // Check-out specific fields
  final DateTime? checkOutTime;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final String? checkOutImageUrl;
  
  final Duration? timeSpentCheckedIn;
  final String? imageUrl;
  final Outlet outlet;

  JourneyPlan({
    this.id,
    required this.date,
    required this.time,
    required this.userId,
    this.guardId,
    required this.status,
    this.notes,
    this.checkInTime,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkInQrCode,
    this.checkInImageUrl,
    this.checkInDeviceInfo,
    this.checkOutTime,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.checkOutImageUrl,
    this.timeSpentCheckedIn,
    this.imageUrl,
    required this.outlet,
  });

  // Status-related getters
  String get statusText {
    switch (status) {
      case statusPending:
        return 'Pending';
      case statusCheckedIn:
        return 'Checked In';
      case statusInProgress:
        return 'In Progress';
      case statusCheckedOut:
        return 'Checked Out';
      case statusCancelled:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  // Status color getter
  Color get statusColor {
    switch (status) {
      case statusPending:
        return Colors.orange;
      case statusCheckedIn:
        return Colors.blue;
      case statusInProgress:
        return Colors.purple;
      case statusCheckedOut:
        return Colors.green;
      case statusCancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Method to calculate time spent
  JourneyPlan calculateTimeSpent() {
    if (checkInTime != null && checkOutTime != null) {
      return copyWith(
        timeSpentCheckedIn: checkOutTime!.difference(checkInTime!)
      );
    }
    return this;
  }

  // Updated copyWith method
  JourneyPlan copyWith({
    int? id,
    DateTime? date,
    String? time,
    int? userId,
    int? guardId,
    int? status,
    String? notes,
    DateTime? checkInTime,
    double? checkInLatitude,
    double? checkInLongitude,
    String? checkInQrCode,
    String? checkInImageUrl,
    String? checkInDeviceInfo,
    DateTime? checkOutTime,
    double? checkOutLatitude,
    double? checkOutLongitude,
    String? checkOutImageUrl,
    Duration? timeSpentCheckedIn,
    String? imageUrl,
    Outlet? outlet,
  }) {
    return JourneyPlan(
      id: id ?? this.id,
      date: date ?? this.date,
      time: time ?? this.time,
      userId: userId ?? this.userId,
      guardId: guardId ?? this.guardId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      checkInTime: checkInTime ?? this.checkInTime,
      checkInLatitude: checkInLatitude ?? this.checkInLatitude,
      checkInLongitude: checkInLongitude ?? this.checkInLongitude,
      checkInQrCode: checkInQrCode ?? this.checkInQrCode,
      checkInImageUrl: checkInImageUrl ?? this.checkInImageUrl,
      checkInDeviceInfo: checkInDeviceInfo ?? this.checkInDeviceInfo,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkOutLatitude: checkOutLatitude ?? this.checkOutLatitude,
      checkOutLongitude: checkOutLongitude ?? this.checkOutLongitude,
      checkOutImageUrl: checkOutImageUrl ?? this.checkOutImageUrl,
      timeSpentCheckedIn: timeSpentCheckedIn ?? this.timeSpentCheckedIn,
      imageUrl: imageUrl ?? this.imageUrl,
      outlet: outlet ?? this.outlet,
    );
  }

  // Updated fromJson method
  factory JourneyPlan.fromJson(Map<String, dynamic> json) {
    if (json['date'] == null) {
      throw FormatException('Journey date is required');
    }
    if (json['outlet'] == null) {
      throw FormatException('Outlet information is required');
    }

    DateTime parseDate(String dateStr) {
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        throw FormatException('Invalid date format: $dateStr');
      }
    }

    String getTime(DateTime date) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
    }

    final date = parseDate(json['date']);
    final time = json['time'] ?? getTime(date);

    final status = json['status'] != null
        ? (json['status'] is int
            ? json['status']
            : int.tryParse(json['status'].toString()) ?? statusPending)
        : statusPending;

    // Calculate time spent if check-in and check-out times are available
    Duration? calculateTimeSpent(DateTime? checkIn, DateTime? checkOut) {
      if (checkIn != null && checkOut != null) {
        return checkOut.difference(checkIn);
      }
      return null;
    }

    final checkInTime = json['checkInTime'] != null ? parseDate(json['checkInTime']) : null;
    final checkOutTime = json['checkOutTime'] != null ? parseDate(json['checkOutTime']) : null;

    return JourneyPlan(
      id: json['id'],
      date: date,
      time: time,
      userId: json['userId'],
      guardId: json['guardId'],
      status: status,
      notes: json['notes'],
      checkInTime: checkInTime,
      checkInLatitude: json['checkInLatitude'] != null
          ? (json['checkInLatitude'] is double
              ? json['checkInLatitude']
              : double.tryParse(json['checkInLatitude'].toString()))
          : null,
      checkInLongitude: json['checkInLongitude'] != null
          ? (json['checkInLongitude'] is double
              ? json['checkInLongitude']
              : double.tryParse(json['checkInLongitude'].toString()))
          : null,
      checkInQrCode: json['checkInQrCode'],
      checkInImageUrl: json['checkInImageUrl'],
      checkInDeviceInfo: json['checkInDeviceInfo'],
      checkOutTime: checkOutTime,
      checkOutLatitude: json['checkOutLatitude'] != null
          ? (json['checkOutLatitude'] is double
              ? json['checkOutLatitude']
              : double.tryParse(json['checkOutLatitude'].toString()))
          : null,
      checkOutLongitude: json['checkOutLongitude'] != null
          ? (json['checkOutLongitude'] is double
              ? json['checkOutLongitude']
              : double.tryParse(json['checkOutLongitude'].toString()))
          : null,
      checkOutImageUrl: json['checkOutImageUrl'],
      timeSpentCheckedIn: calculateTimeSpent(checkInTime, checkOutTime),
      imageUrl: json['imageUrl'],
      outlet: Outlet.fromJson(json['outlet']),
    );
  }

  // Updated toJson method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'time': time,
      'userId': userId,
      'guardId': guardId,
      'status': status,
      'notes': notes,
      'checkInTime': checkInTime?.toIso8601String(),
      'checkInLatitude': checkInLatitude,
      'checkInLongitude': checkInLongitude,
      'checkInQrCode': checkInQrCode,
      'checkInImageUrl': checkInImageUrl,
      'checkInDeviceInfo': checkInDeviceInfo,
      'checkOutTime': checkOutTime?.toIso8601String(),
      'checkOutLatitude': checkOutLatitude,
      'checkOutLongitude': checkOutLongitude,
      'checkOutImageUrl': checkOutImageUrl,
      'timeSpentCheckedIn': timeSpentCheckedIn?.inSeconds,
      'imageUrl': imageUrl,
      'outlet': outlet.toJson(),
    };
  }
}