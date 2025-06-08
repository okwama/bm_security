import 'package:json_annotation/json_annotation.dart';

part 'client.g.dart';

@JsonSerializable()
class Client {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Client({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Client.fromJson(Map<String, dynamic> json) => _$ClientFromJson(json);
  Map<String, dynamic> toJson() => _$ClientToJson(this);
} 