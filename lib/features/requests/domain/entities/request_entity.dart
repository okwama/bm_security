import 'package:equatable/equatable.dart';
import 'service_type_entity.dart';
import '../../../cash_count/domain/entities/cash_count_entity.dart';

class RequestEntity extends Equatable {
  final int id;
  final int? userId;
  final String userName;
  final int serviceTypeId;
  final String serviceTypeName;
  final double price;
  final String pickupLocation;
  final String deliveryLocation;
  final DateTime pickupDate;
  final String? description;
  final String priority;
  final int myStatus;
  final String? status;
  final int? staffId;
  final String? staffName;
  final int? teamId;
  final double? latitude;
  final double? longitude;
  final int? branchId;
  final int? sealNumberId;
  final int? atmId;
  final String? destinationType;
  final ServiceTypeEntity? serviceType;
  final List<CashCountEntity>? cashCounts;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RequestEntity({
    required this.id,
    this.userId,
    required this.userName,
    required this.serviceTypeId,
    required this.serviceTypeName,
    required this.price,
    required this.pickupLocation,
    required this.deliveryLocation,
    required this.pickupDate,
    this.description,
    required this.priority,
    required this.myStatus,
    this.status,
    this.staffId,
    this.staffName,
    this.teamId,
    this.latitude,
    this.longitude,
    this.branchId,
    this.sealNumberId,
    this.atmId,
    this.destinationType,
    this.serviceType,
    this.cashCounts,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        serviceTypeId,
        serviceTypeName,
        price,
        pickupLocation,
        deliveryLocation,
        pickupDate,
        description,
        priority,
        myStatus,
        status,
        staffId,
        staffName,
        teamId,
        latitude,
        longitude,
        branchId,
        sealNumberId,
        atmId,
        destinationType,
        serviceType,
        cashCounts,
        createdAt,
        updatedAt,
      ];

  RequestEntity copyWith({
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
    return RequestEntity(
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

  // Helper methods for status
  bool get isPending => myStatus == 0;
  bool get isInProgress => myStatus == 1;
  bool get isCompleted => myStatus == 2;
  bool get isCancelled => myStatus == 3;

  String get statusText {
    switch (myStatus) {
      case 0:
        return 'Pending';
      case 1:
        return 'In Progress';
      case 2:
        return 'Completed';
      case 3:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }
}
