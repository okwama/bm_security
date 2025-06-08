// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Staff _$StaffFromJson(Map<String, dynamic> json) => Staff(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      phone: json['phone'] as String?,
      password: json['password'] as String?,
      roleId: (json['roleId'] as num?)?.toInt() ?? 0,
      role: json['role'] as String,
      emplNo: json['emplNo'] as String,
      idNo: (json['idNo'] as num).toInt(),
      photoUrl: json['photoUrl'] as String,
      status: (json['status'] as num?)?.toInt() ?? 0,
      requests: (json['requests'] as List<dynamic>?)
          ?.map((e) => StaffRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$StaffToJson(Staff instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone': instance.phone,
      'password': instance.password,
      'roleId': instance.roleId,
      'role': instance.role,
      'emplNo': instance.emplNo,
      'idNo': instance.idNo,
      'photoUrl': instance.photoUrl,
      'status': instance.status,
      'requests': instance.requests,
    };

StaffRequest _$StaffRequestFromJson(Map<String, dynamic> json) => StaffRequest(
      id: (json['id'] as num).toInt(),
      clientName: json['clientName'] as String,
      pickupLocation: json['pickupLocation'] as String,
      deliveryLocation: json['deliveryLocation'] as String,
      status: json['status'] as String,
      myStatus: (json['myStatus'] as num).toInt(),
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$StaffRequestToJson(StaffRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clientName': instance.clientName,
      'pickupLocation': instance.pickupLocation,
      'deliveryLocation': instance.deliveryLocation,
      'status': instance.status,
      'myStatus': instance.myStatus,
      'createdAt': instance.createdAt,
    };
