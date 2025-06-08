import 'package:json_annotation/json_annotation.dart';

part 'service_type.g.dart';

@JsonSerializable()
class ServiceType {
  final int id;
  final String name;
  final int status;

  ServiceType({
    required this.id,
    required this.name,
    this.status = 0,
  });

  factory ServiceType.fromJson(Map<String, dynamic> json) => _$ServiceTypeFromJson(json);
  Map<String, dynamic> toJson() => _$ServiceTypeToJson(this);
} 