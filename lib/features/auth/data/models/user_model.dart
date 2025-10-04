import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.role,
    required super.roleId,
    required super.employeeNumber,
    super.idNumber,
    super.photoUrl,
    required super.status,
    super.teamId,
    super.teamName,
    super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? json['roleName'] as String? ?? '',
      roleId: json['roleId'] as int? ?? 0,
      employeeNumber: json['employeeNumber'] as String? ?? json['empl_no'] as String? ?? '',
      idNumber: json['idNumber'] as int? ?? json['id_no'] as int?,
      photoUrl: json['photoUrl'] as String? ?? json['photo_url'] as String?,
      status: json['status'] as int? ?? 1,
      teamId: json['teamId'] as int?,
      teamName: json['team']?['name'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role,
      'roleId': roleId,
      'employeeNumber': employeeNumber,
      'idNumber': idNumber,
      'photoUrl': photoUrl,
      'status': status,
      'teamId': teamId,
      'teamName': teamName,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      phone: entity.phone,
      role: entity.role,
      roleId: entity.roleId,
      employeeNumber: entity.employeeNumber,
      idNumber: entity.idNumber,
      photoUrl: entity.photoUrl,
      status: entity.status,
      teamId: entity.teamId,
      teamName: entity.teamName,
      createdAt: entity.createdAt,
    );
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      phone: phone,
      role: role,
      roleId: roleId,
      employeeNumber: employeeNumber,
      idNumber: idNumber,
      photoUrl: photoUrl,
      status: status,
      teamId: teamId,
      teamName: teamName,
      createdAt: createdAt,
    );
  }
}
