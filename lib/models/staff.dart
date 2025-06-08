import 'package:json_annotation/json_annotation.dart';

part 'staff.g.dart';

@JsonSerializable()
class Staff {
  final int id;
  final String name;
  final String? phone;
  final String? password;
  @JsonKey(name: 'roleId')
  final int roleId;
  final String role;
  @JsonKey(name: 'emplNo')
  final String emplNo;
  @JsonKey(name: 'idNo')
  final int idNo;
  @JsonKey(name: 'photoUrl')
  final String photoUrl;
  final int status;
  final List<StaffRequest>? requests;

  Staff({
    required this.id,
    required this.name,
    this.phone,
    this.password,
    this.roleId = 0,
    required this.role,
    required this.emplNo,
    required this.idNo,
    required this.photoUrl,
    this.status = 0,
    this.requests,
  });

  factory Staff.fromJson(Map<String, dynamic> json) => _$StaffFromJson(json);
  Map<String, dynamic> toJson() => _$StaffToJson(this);

  Staff copyWith({
    int? id,
    String? name,
    String? phone,
    String? password,
    int? roleId,
    String? role,
    String? emplNo,
    int? idNo,
    String? photoUrl,
    int? status,
    List<StaffRequest>? requests,
  }) {
    return Staff(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      roleId: roleId ?? this.roleId,
      role: role ?? this.role,
      emplNo: emplNo ?? this.emplNo,
      idNo: idNo ?? this.idNo,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      requests: requests ?? this.requests,
    );
  }
}

@JsonSerializable()
class StaffRequest {
  final int id;
  final String clientName;
  final String pickupLocation;
  final String deliveryLocation;
  final String status;
  @JsonKey(name: 'myStatus')
  final int myStatus;
  @JsonKey(name: 'createdAt')
  final String createdAt;

  StaffRequest({
    required this.id,
    required this.clientName,
    required this.pickupLocation,
    required this.deliveryLocation,
    required this.status,
    required this.myStatus,
    required this.createdAt,
  });

  factory StaffRequest.fromJson(Map<String, dynamic> json) =>
      _$StaffRequestFromJson(json);
  Map<String, dynamic> toJson() => _$StaffRequestToJson(this);
}
