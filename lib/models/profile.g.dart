// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Profile _$ProfileFromJson(Map<String, dynamic> json) => Profile(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      phone: json['phone'] as String?,
      password: json['password'] as String?,
      roleId: (json['roleId'] as num).toInt(),
      role: json['role'] as String,
      emplNo: json['emplNo'] as String,
      idNo: (json['idNo'] as num).toInt(),
      photoUrl: json['photoUrl'] as String,
      createdAt: json['createdAt'] as String,
      status: (json['status'] as num).toInt(),
    );

Map<String, dynamic> _$ProfileToJson(Profile instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone': instance.phone,
      'password': instance.password,
      'roleId': instance.roleId,
      'role': instance.role,
      'emplNo': instance.emplNo,
      'idNo': instance.idNo,
      'photoUrl': instance.photoUrl,
      'createdAt': instance.createdAt,
      'status': instance.status,
    };
