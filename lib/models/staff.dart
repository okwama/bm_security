import 'package:json_annotation/json_annotation.dart';

part 'staff.g.dart';

@JsonSerializable()
class Staff {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? role;
  final int? roleId;
  final int? status;
  @JsonKey(name: 'emplNo')
  final String? emplNo;
  @JsonKey(name: 'idNo')
  final int? idNo;
  @JsonKey(name: 'photoUrl')
  final String? photoUrl;
  final List<StaffRequest>? requests;

  Staff({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.role,
    this.roleId,
    this.status,
    this.emplNo,
    this.idNo,
    this.photoUrl,
    this.requests,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
      roleId: json['roleId'] as int?,
      status: json['status'] as int?,
      emplNo: json['emplNo'] as String?,
      idNo: json['idNo'] as int?,
      photoUrl: json['photoUrl'] as String?,
      requests: json['requests'] != null
          ? List<StaffRequest>.from(
              json['requests'].map((x) => StaffRequest.fromJson(x)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'roleId': roleId,
      'status': status,
      'emplNo': emplNo,
      'idNo': idNo,
      'photoUrl': photoUrl,
      if (requests != null)
        'requests': requests!.map((e) => e.toJson()).toList(),
    };
  }

  Staff copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? role,
    int? roleId,
    int? status,
    String? emplNo,
    int? idNo,
    String? photoUrl,
    List<StaffRequest>? requests,
  }) {
    return Staff(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      roleId: roleId ?? this.roleId,
      status: status ?? this.status,
      emplNo: emplNo ?? this.emplNo,
      idNo: idNo ?? this.idNo,
      photoUrl: photoUrl ?? this.photoUrl,
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
