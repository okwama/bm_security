// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Request _$RequestFromJson(Map<String, dynamic> json) => Request(
      id: (json['id'] as num).toInt(),
      clientName: json['clientName'] as String?,
      pickupLocation: json['pickupLocation'] as String?,
      deliveryLocation: json['deliveryLocation'] as String?,
      pickupDate: Request._dateFromJson(json['pickupDate']),
      status: $enumDecode(_$StatusEnumMap, json['status'],
          unknownValue: Status.pending),
      priority: $enumDecode(_$PriorityEnumMap, json['priority'],
          unknownValue: Priority.medium),
      createdAt: Request._dateFromJson(json['createdAt']),
      serviceType: json['serviceType'],
      serviceTypeId: (json['serviceTypeId'] as num?)?.toInt(),
      cashCount: json['cashCount'] == null
          ? null
          : CashCount.fromJson(json['cashCount'] as Map<String, dynamic>),
      cashImageUrl: json['cashImageUrl'] as String?,
      branch: json['branch'] == null
          ? null
          : Branch.fromJson(json['branch'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RequestToJson(Request instance) => <String, dynamic>{
      'id': instance.id,
      if (instance.clientName case final value?) 'clientName': value,
      if (instance.pickupLocation case final value?) 'pickupLocation': value,
      if (instance.deliveryLocation case final value?)
        'deliveryLocation': value,
      'pickupDate': Request._dateToJson(instance.pickupDate),
      'status': _$StatusEnumMap[instance.status]!,
      'priority': _$PriorityEnumMap[instance.priority]!,
      'createdAt': Request._dateToJson(instance.createdAt),
      'serviceType': instance.serviceType,
      'serviceTypeId': instance.serviceTypeId,
      if (instance.cashCount case final value?) 'cashCount': value,
      if (instance.cashImageUrl case final value?) 'cashImageUrl': value,
      if (instance.branch case final value?) 'branch': value,
    };

const _$StatusEnumMap = {
  Status.pending: 'pending',
  Status.inProgress: 'in_progress',
  Status.completed: 'completed',
  Status.cancelled: 'cancelled',
};

const _$PriorityEnumMap = {
  Priority.low: 'low',
  Priority.medium: 'medium',
  Priority.high: 'high',
};
