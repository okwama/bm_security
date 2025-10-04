import 'package:equatable/equatable.dart';

abstract class TeamsEvent extends Equatable {
  const TeamsEvent();

  @override
  List<Object?> get props => [];
}

class GetMyTeamEvent extends TeamsEvent {
  const GetMyTeamEvent();
}

class GetTeamByIdEvent extends TeamsEvent {
  final int teamId;

  const GetTeamByIdEvent({required this.teamId});

  @override
  List<Object> get props => [teamId];
}

class GetAllTeamsEvent extends TeamsEvent {
  const GetAllTeamsEvent();
}

class CreateTeamEvent extends TeamsEvent {
  final String name;
  final int? crewCommanderId;

  const CreateTeamEvent({
    required this.name,
    this.crewCommanderId,
  });

  @override
  List<Object?> get props => [name, crewCommanderId];
}

class UpdateTeamEvent extends TeamsEvent {
  final int teamId;
  final String? name;
  final int? crewCommanderId;

  const UpdateTeamEvent({
    required this.teamId,
    this.name,
    this.crewCommanderId,
  });

  @override
  List<Object?> get props => [teamId, name, crewCommanderId];
}

class DeleteTeamEvent extends TeamsEvent {
  final int teamId;

  const DeleteTeamEvent({required this.teamId});

  @override
  List<Object> get props => [teamId];
}

class AddMemberToTeamEvent extends TeamsEvent {
  final int teamId;
  final int userId;

  const AddMemberToTeamEvent({
    required this.teamId,
    required this.userId,
  });

  @override
  List<Object> get props => [teamId, userId];
}

class RemoveMemberFromTeamEvent extends TeamsEvent {
  final int teamId;
  final int userId;

  const RemoveMemberFromTeamEvent({
    required this.teamId,
    required this.userId,
  });

  @override
  List<Object> get props => [teamId, userId];
}

class RefreshTeamsEvent extends TeamsEvent {
  const RefreshTeamsEvent();
}

class GetTeamMembersEvent extends TeamsEvent {
  final int teamId;

  const GetTeamMembersEvent({required this.teamId});

  @override
  List<Object> get props => [teamId];
}
