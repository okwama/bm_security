// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_count.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CashCount _$CashCountFromJson(Map<String, dynamic> json) => CashCount(
      ones: (json['ones'] as num?)?.toInt() ?? 0,
      fives: (json['fives'] as num?)?.toInt() ?? 0,
      tens: (json['tens'] as num?)?.toInt() ?? 0,
      twenties: (json['twenties'] as num?)?.toInt() ?? 0,
      forties: (json['forties'] as num?)?.toInt() ?? 0,
      fifties: (json['fifties'] as num?)?.toInt() ?? 0,
      hundreds: (json['hundreds'] as num?)?.toInt() ?? 0,
      twoHundreds: (json['twoHundreds'] as num?)?.toInt() ?? 0,
      fiveHundreds: (json['fiveHundreds'] as num?)?.toInt() ?? 0,
      thousands: (json['thousands'] as num?)?.toInt() ?? 0,
      sealNumber: json['sealNumber'] as String?,
    );

Map<String, dynamic> _$CashCountToJson(CashCount instance) => <String, dynamic>{
      'ones': instance.ones,
      'fives': instance.fives,
      'tens': instance.tens,
      'twenties': instance.twenties,
      'forties': instance.forties,
      'fifties': instance.fifties,
      'hundreds': instance.hundreds,
      'twoHundreds': instance.twoHundreds,
      'fiveHundreds': instance.fiveHundreds,
      'thousands': instance.thousands,
      if (instance.sealNumber case final value?) 'sealNumber': value,
    };
