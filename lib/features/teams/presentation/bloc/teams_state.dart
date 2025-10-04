import 'package:equatable/equatable.dart';
import '../../domain/entities/team_entity.dart';
import '../../../auth/domain/entities/user_entity.dart';

abstract class TeamsState extends Equatable {
  const TeamsState();

  @override
  List<Object?> get props => [];
}

class TeamsInitial extends TeamsState {}

class TeamsLoading extends TeamsState {}

class TeamsLoaded extends TeamsState {
  final List<TeamEntity> teams;

  const TeamsLoaded({required this.teams});

  @override
  List<Object> get props => [teams];
}

class TeamLoaded extends TeamsState {
  final TeamEntity team;

  const TeamLoaded({required this.team});

  @override
  List<Object> get props => [team];
}

class TeamsError extends TeamsState {
  final String message;

  const TeamsError({required this.message});

  @override
  List<Object> get props => [message];
}

class TeamCreated extends TeamsState {
  final TeamEntity team;

  const TeamCreated({required this.team});

  @override
  List<Object> get props => [team];
}

class TeamUpdated extends TeamsState {
  final TeamEntity team;

  const TeamUpdated({required this.team});

  @override
  List<Object> get props => [team];
}

class TeamDeleted extends TeamsState {
  final int teamId;

  const TeamDeleted({required this.teamId});

  @override
  List<Object> get props => [teamId];
}

class MemberAdded extends TeamsState {
  final TeamEntity team;

  const MemberAdded({required this.team});

  @override
  List<Object> get props => [team];
}

class MemberRemoved extends TeamsState {
  final TeamEntity team;

  const MemberRemoved({required this.team});

  @override
  List<Object> get props => [team];
}

class TeamMembersLoaded extends TeamsState {
  final int teamId;
  final List<UserEntity> members;

  const TeamMembersLoaded({
    required this.teamId,
    required this.members,
  });

  @override
  List<Object> get props => [teamId, members];
}
