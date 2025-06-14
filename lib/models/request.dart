import 'package:json_annotation/json_annotation.dart';
import 'cash_count.dart';
import 'branch.dart';
import 'delivery_completion.dart';
part 'request.g.dart';

enum Priority {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
}

enum Status {
  @JsonValue('pending')
  pending,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
}

@JsonSerializable()
class Request {
  final int id;
  @JsonKey(name: 'clientName', includeIfNull: false)
  final String? clientName;
  @JsonKey(name: 'pickupLocation', includeIfNull: false)
  final String? pickupLocation;
  @JsonKey(name: 'deliveryLocation', includeIfNull: false)
  final String? deliveryLocation;
  @JsonKey(name: 'pickupDate', fromJson: _dateFromJson, toJson: _dateToJson)
  final DateTime? pickupDate;

  @JsonKey(name: 'status', unknownEnumValue: Status.pending)
  final Status status;

  @JsonKey(name: 'priority', unknownEnumValue: Priority.medium)
  final Priority priority;

  @JsonKey(name: 'myStatus', defaultValue: 0)
  final int myStatus;

  @JsonKey(name: 'createdAt', fromJson: _dateFromJson, toJson: _dateToJson)
  final DateTime? createdAt;
  @JsonKey(name: 'ServiceType')
  final dynamic _serviceTypeData;

  String get serviceType {
    try {
      if (_serviceTypeData == null) return '';
      if (_serviceTypeData is String) return _serviceTypeData;
      if (_serviceTypeData is Map) {
        return _serviceTypeData['name']?.toString() ?? '';
      }
      return '';
    } catch (e) {
      print('Error getting serviceType: $e');
      return '';
    }
  }

  int get serviceTypeId {
    try {
      if (_serviceTypeData == null) return 0;
      if (_serviceTypeData is Map) {
        final id = _serviceTypeData['id'];
        if (id is int) return id;
        if (id is String) return int.tryParse(id) ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error getting serviceTypeId: $e');
      return 0;
    }
  }

  @JsonKey(includeIfNull: false)
  final CashCount? cashCount;

  @JsonKey(name: 'cashImageUrl', includeIfNull: false)
  final String? cashImageUrl;

  @JsonKey(name: 'branch', includeIfNull: false)
  final Branch? branch;

  @JsonKey(name: 'deliveryCompletion')
  final DeliveryCompletion? deliveryCompletion;

  Request({
    required this.id,
    this.clientName,
    this.pickupLocation,
    this.deliveryLocation,
    required this.pickupDate,
    required this.status,
    required this.priority,
    this.myStatus = 0,
    required this.createdAt,
    dynamic serviceType,
    int? serviceTypeId,
    this.cashCount,
    this.cashImageUrl,
    this.branch,
    this.deliveryCompletion,
  }) : _serviceTypeData = serviceType ??
            (serviceTypeId != null
                ? {
                    'id': serviceTypeId,
                    'name': serviceType is String ? serviceType : null
                  }
                : null);

  factory Request.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing Request JSON: $json');

      // Safely parse ID with null check
      final id = json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0;

      if (id == 0) {
        print('Warning: Invalid or missing ID in request JSON');
      }

      // Handle potential null or invalid enum values
      final status = Status.values.firstWhere(
        (e) =>
            e.toString().split('.').last ==
            json['status']?.toString().toLowerCase(),
        orElse: () => Status.pending,
      );

      final priority = Priority.values.firstWhere(
        (e) =>
            e.toString().split('.').last ==
            json['priority']?.toString().toLowerCase(),
        orElse: () => Priority.medium,
      );

      // Handle service type data
      dynamic serviceTypeData = json['ServiceType'] ?? json['serviceType'];
      final serviceTypeId = json['serviceTypeId'] is int
          ? json['serviceTypeId']
          : int.tryParse(json['serviceTypeId']?.toString() ?? '');

      if (serviceTypeData is String) {
        // If ServiceType is a string, create a proper object with ID and name
        serviceTypeData = {
          'id': serviceTypeId ?? (serviceTypeData == 'BSS' ? 2 : 0),
          'name': serviceTypeData,
        };
      } else if (serviceTypeData == null && serviceTypeId != null) {
        // If only serviceTypeId is provided, create a minimal object
        serviceTypeData = {
          'id': serviceTypeId,
          'name': json['serviceType']?.toString() ?? 'Unknown',
        };
      }

      // Safely parse cash count
      CashCount? cashCount;
      try {
        if (json['cashCount'] != null) {
          cashCount = CashCount.fromJson(
            json['cashCount'] is Map<String, dynamic>
                ? json['cashCount']
                : <String, dynamic>{},
          );
        }
      } catch (e) {
        print('Error parsing cashCount: $e');
      }

      // Safely parse branch
      Branch? branch;
      try {
        if (json['branch'] != null) {
          branch = Branch.fromJson(
            json['branch'] is Map<String, dynamic>
                ? json['branch']
                : <String, dynamic>{},
          );
        }
      } catch (e) {
        print('Error parsing branch: $e');
      }

      DeliveryCompletion? deliveryCompletion;
      try {
        if (json['deliveryCompletion'] != null) {
          deliveryCompletion = DeliveryCompletion.fromJson(
              json['deliveryCompletion'] as Map<String, dynamic>);
        }
      } catch (e) {
        print('Error parsing deliveryCompletion: $e');
      }

      return Request(
        id: id,
        clientName: json['clientName']?.toString(),
        pickupLocation: json['pickupLocation']?.toString(),
        deliveryLocation: json['deliveryLocation']?.toString(),
        pickupDate: _dateFromJson(json['pickupDate']),
        status: status,
        priority: priority,
        createdAt: _dateFromJson(json['createdAt']),
        serviceType: serviceTypeData,
        serviceTypeId: serviceTypeId,
        cashCount: cashCount,
        cashImageUrl: json['cashImageUrl']?.toString(),
        branch: branch,
        deliveryCompletion: deliveryCompletion,
      );
    } catch (e, stackTrace) {
      print('Error parsing Request from JSON: $e');
      print('Stack trace: $stackTrace');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientName': clientName,
      'pickupLocation': pickupLocation,
      'deliveryLocation': deliveryLocation,
      'pickupDate': _dateToJson(pickupDate),
      'status': status.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'createdAt': _dateToJson(createdAt),
      'ServiceType': _serviceTypeData is Map ? serviceType : _serviceTypeData,
      'serviceTypeId': serviceTypeId,
      'cashCount': cashCount?.toJson(),
      'cashImageUrl': cashImageUrl,
      'branch': branch?.toJson(),
      if (deliveryCompletion != null)
        'deliveryCompletion': deliveryCompletion!.toJson(),
    };
  }

  static DateTime? _dateFromJson(dynamic date) {
    try {
      if (date == null) return null;
      if (date is DateTime) return date;
      if (date is String) {
        if (date.isEmpty) return null;
        return DateTime.tryParse(date) ?? DateTime.now();
      }
      return null;
    } catch (e) {
      print('Error parsing date: $e');
      return null;
    }
  }

  static String? _dateToJson(DateTime? date) => date?.toIso8601String();
}

class ServiceTypeInfo {
  final String name;

  ServiceTypeInfo({required this.name});

  factory ServiceTypeInfo.fromJson(Map<String, dynamic> json) {
    return ServiceTypeInfo(
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }
}
