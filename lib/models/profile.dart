import 'package:json_annotation/json_annotation.dart';

part 'profile.g.dart';

@JsonSerializable()
class Profile {
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
  @JsonKey(name: 'createdAt')
  final String createdAt;
  final int status;

  Profile({
    required this.id,
    required this.name,
    this.phone,
    this.password,
    required this.roleId,
    required this.role,
    required this.emplNo,
    required this.idNo,
    required this.photoUrl,
    required this.createdAt,
    required this.status,
  });

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileToJson(this);

  Profile copyWith({
    int? id,
    String? name,
    String? phone,
    String? password,
    int? roleId,
    String? role,
    String? emplNo,
    int? idNo,
    String? photoUrl,
    String? createdAt,
    int? status,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      roleId: roleId ?? this.roleId,
      role: role ?? this.role,
      emplNo: emplNo ?? this.emplNo,
      idNo: idNo ?? this.idNo,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
