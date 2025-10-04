import '../../domain/entities/team_entity.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/data/models/user_model.dart';

class TeamModel extends TeamEntity {
  const TeamModel({
    required super.id,
    required super.name,
    super.crewCommanderId,
    super.crewCommanderName,
    required super.createdAt,
    super.members = const [],
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['id'] as int,
      name: json['name'] as String,
      crewCommanderId: json['crewCommanderId'] as int?,
      crewCommanderName: json['crewCommander'] != null 
          ? json['crewCommander']['name'] as String?
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      members: json['members'] != null
          ? (json['members'] as List)
              .map((member) => UserModel.fromJson(member as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'crew_commander_id': crewCommanderId,
      'crewCommanderName': crewCommanderName,
      'created_at': createdAt.toIso8601String(),
      'members': members.map((member) => (member as UserModel).toJson()).toList(),
    };
  }

  factory TeamModel.fromEntity(TeamEntity entity) {
    return TeamModel(
      id: entity.id,
      name: entity.name,
      crewCommanderId: entity.crewCommanderId,
      crewCommanderName: entity.crewCommanderName,
      createdAt: entity.createdAt,
      members: entity.members,
    );
  }
}
