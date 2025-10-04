import '../../domain/entities/request_entity.dart';
import '../../domain/entities/service_type_entity.dart';
import '../../../cash_count/domain/entities/cash_count_entity.dart';

class RequestModel extends RequestEntity {
  const RequestModel({
    required super.id,
    super.userId,
    required super.userName,
    required super.serviceTypeId,
    required super.serviceTypeName,
    required super.price,
    required super.pickupLocation,
    required super.deliveryLocation,
    required super.pickupDate,
    super.description,
    required super.priority,
    required super.myStatus,
    super.status,
    super.staffId,
    super.staffName,
    super.teamId,
    super.latitude,
    super.longitude,
    super.branchId,
    super.sealNumberId,
    super.atmId,
    super.destinationType,
    super.serviceType,
    super.cashCounts,
    required super.createdAt,
    required super.updatedAt,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['id'] as int,
      userId: json['userId'] as int? ?? json['user_id'] as int?,
      userName: json['userName'] as String? ?? json['user_name'] as String? ?? 'Unknown User',
      serviceTypeId: json['serviceTypeId'] as int? ?? json['service_type_id'] as int? ?? 1,
      serviceTypeName: json['serviceTypeName'] as String? ?? 
                      json['service_type_name'] as String? ?? 
                      (json['serviceType'] != null ? (json['serviceType'] as Map<String, dynamic>)['name'] as String? : null) ?? 
                      'Unknown Service',
      price: json['price'] is num 
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      pickupLocation: json['pickupLocation'] as String? ?? json['pickup_location'] as String? ?? 'Unknown Location',
      deliveryLocation: json['deliveryLocation'] as String? ?? json['delivery_location'] as String? ?? 'Unknown Location',
      pickupDate: json['pickupDate'] != null 
          ? DateTime.parse(json['pickupDate'] as String)
          : json['pickup_date'] != null
              ? DateTime.parse(json['pickup_date'] as String)
              : DateTime.now(),
      description: json['description'] as String?,
      priority: json['priority'] as String? ?? 'Normal',
      myStatus: json['myStatus'] as int? ?? json['my_status'] as int? ?? 0,
      status: json['status'] as String? ?? 'Pending',
      staffId: json['staffId'] as int? ?? json['staff_id'] as int?,
      atmId: json['atmId'] as int? ?? json['atm_id'] as int?,
      staffName: json['staffName'] as String? ?? json['staff_name'] as String?,
      teamId: json['teamId'] as int? ?? json['team_id'] as int?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      branchId: json['branchId'] as int? ?? json['branch_id'] as int?,
      sealNumberId: json['sealNumberId'] as int? ?? json['sealNumberId'] as int?,
      destinationType: json['destinationType'] as String? ?? json['destination_type'] as String?,
      serviceType: json['serviceType'] != null
          ? ServiceTypeEntity.fromJson(json['serviceType'] as Map<String, dynamic>)
          : null,
      cashCounts: json['cashCounts'] != null
          ? (json['cashCounts'] as List)
              .map((e) => CashCountEntity.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pickupLocation': pickupLocation,
      'deliveryLocation': deliveryLocation,
      'myStatus': myStatus,
      'status': status,
      'staffId': staffId,
      'atmId': atmId,
      'staffName': staffName,
      'teamId': teamId,
      'latitude': latitude,
      'longitude': longitude,
      'branchId': branchId,
      'sealNumberId': sealNumberId,
      'destinationType': destinationType,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'serviceType': serviceType != null
          ? {
              'id': serviceType!.id,
              'name': serviceType!.name,
              'description': serviceType!.description,
            }
          : null,
    };
  }

  RequestModel copyWith({
    int? id,
    int? userId,
    String? userName,
    int? serviceTypeId,
    String? serviceTypeName,
    double? price,
    String? pickupLocation,
    String? deliveryLocation,
    DateTime? pickupDate,
    String? description,
    String? priority,
    int? myStatus,
    String? status,
    int? staffId,
    String? staffName,
    int? teamId,
    double? latitude,
    double? longitude,
    int? branchId,
    int? sealNumberId,
    int? atmId,
    String? destinationType,
    ServiceTypeEntity? serviceType,
    List<CashCountEntity>? cashCounts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      serviceTypeId: serviceTypeId ?? this.serviceTypeId,
      serviceTypeName: serviceTypeName ?? this.serviceTypeName,
      price: price ?? this.price,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      pickupDate: pickupDate ?? this.pickupDate,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      myStatus: myStatus ?? this.myStatus,
      status: status ?? this.status,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      teamId: teamId ?? this.teamId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      branchId: branchId ?? this.branchId,
      sealNumberId: sealNumberId ?? this.sealNumberId,
      atmId: atmId ?? this.atmId,
      destinationType: destinationType ?? this.destinationType,
      serviceType: serviceType ?? this.serviceType,
      cashCounts: cashCounts ?? this.cashCounts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
