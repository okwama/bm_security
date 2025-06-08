// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'branch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Branch _$BranchFromJson(Map<String, dynamic> json) => Branch(
      id: (json['id'] as num?)?.toInt() ?? 0,
      clientId: (json['client_id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? 'Unknown Branch',
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      createdAt: Branch._dateTimeFromJson(json['created_at']),
      updatedAt: Branch._dateTimeFromJson(json['updated_at']),
    );

Map<String, dynamic> _$BranchToJson(Branch instance) => <String, dynamic>{
      'id': instance.id,
      'client_id': instance.clientId,
      'name': instance.name,
      'address': instance.address,
      'phone': instance.phone,
      'email': instance.email,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
