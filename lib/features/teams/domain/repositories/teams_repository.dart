import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/team_entity.dart';
import '../../../auth/domain/entities/user_entity.dart';

abstract class TeamsRepository {
  Future<Either<Failure, List<TeamEntity>>> getMyTeam();
  Future<Either<Failure, TeamEntity>> getTeamById(int teamId);
  Future<Either<Failure, List<TeamEntity>>> getAllTeams();
  Future<Either<Failure, TeamEntity>> createTeam({
    required String name,
    int? crewCommanderId,
  });
  Future<Either<Failure, TeamEntity>> updateTeam({
    required int teamId,
    String? name,
    int? crewCommanderId,
  });
  Future<Either<Failure, void>> deleteTeam(int teamId);
  Future<Either<Failure, TeamEntity>> addMemberToTeam({
    required int teamId,
    required int userId,
  });
  Future<Either<Failure, TeamEntity>> removeMemberFromTeam({
    required int teamId,
    required int userId,
  });
  Future<Either<Failure, List<UserEntity>>> getTeamMembers(int teamId);
}
