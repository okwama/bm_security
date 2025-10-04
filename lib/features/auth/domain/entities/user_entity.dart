import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final int id;
  final String name;
  final String phone;
  final String role;
  final int roleId;
  final String employeeNumber;
  final int? idNumber;
  final String? photoUrl;
  final int status;
  final int? teamId;
  final String? teamName;
  final DateTime? createdAt;

  const UserEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.roleId,
    required this.employeeNumber,
    this.idNumber,
    this.photoUrl,
    required this.status,
    this.teamId,
    this.teamName,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        role,
        roleId,
        employeeNumber,
        idNumber,
        photoUrl,
        status,
        teamId,
        teamName,
        createdAt,
      ];

  UserEntity copyWith({
    int? id,
    String? name,
    String? phone,
    String? role,
    int? roleId,
    String? employeeNumber,
    int? idNumber,
    String? photoUrl,
    int? status,
    int? teamId,
    String? teamName,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      roleId: roleId ?? this.roleId,
      employeeNumber: employeeNumber ?? this.employeeNumber,
      idNumber: idNumber ?? this.idNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
