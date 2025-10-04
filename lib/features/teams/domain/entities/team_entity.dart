import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/user_entity.dart';

class TeamEntity extends Equatable {
  final int id;
  final String name;
  final int? crewCommanderId;
  final String? crewCommanderName;
  final DateTime createdAt;
  final List<UserEntity> members;

  const TeamEntity({
    required this.id,
    required this.name,
    this.crewCommanderId,
    this.crewCommanderName,
    required this.createdAt,
    this.members = const [],
  });

  @override
  List<Object?> get props => [
        id,
        name,
        crewCommanderId,
        crewCommanderName,
        createdAt,
        members,
      ];

  TeamEntity copyWith({
    int? id,
    String? name,
    int? crewCommanderId,
    String? crewCommanderName,
    DateTime? createdAt,
    List<UserEntity>? members,
  }) {
    return TeamEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      crewCommanderId: crewCommanderId ?? this.crewCommanderId,
      crewCommanderName: crewCommanderName ?? this.crewCommanderName,
      createdAt: createdAt ?? this.createdAt,
      members: members ?? this.members,
    );
  }
}
