import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/team_entity.dart';
import '../../domain/repositories/teams_repository.dart';
import '../datasources/teams_remote_datasource.dart';
import '../../../auth/domain/entities/user_entity.dart';

class TeamsRepositoryImpl implements TeamsRepository {
  final TeamsRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  TeamsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<TeamEntity>>> getMyTeam() async {
    if (await networkInfo.isConnected) {
      try {
        final teams = await remoteDataSource.getMyTeam();
        return Right(teams);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, TeamEntity>> getTeamById(int teamId) async {
    if (await networkInfo.isConnected) {
      try {
        final team = await remoteDataSource.getTeamById(teamId);
        return Right(team);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<TeamEntity>>> getAllTeams() async {
    if (await networkInfo.isConnected) {
      try {
        final teams = await remoteDataSource.getAllTeams();
        return Right(teams);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, TeamEntity>> createTeam({
    required String name,
    int? crewCommanderId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final team = await remoteDataSource.createTeam(
          name: name,
          crewCommanderId: crewCommanderId,
        );
        return Right(team);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, TeamEntity>> updateTeam({
    required int teamId,
    String? name,
    int? crewCommanderId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final team = await remoteDataSource.updateTeam(
          teamId: teamId,
          name: name,
          crewCommanderId: crewCommanderId,
        );
        return Right(team);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTeam(int teamId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteTeam(teamId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, TeamEntity>> addMemberToTeam({
    required int teamId,
    required int userId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final team = await remoteDataSource.addMemberToTeam(
          teamId: teamId,
          userId: userId,
        );
        return Right(team);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, TeamEntity>> removeMemberFromTeam({
    required int teamId,
    required int userId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final team = await remoteDataSource.removeMemberFromTeam(
          teamId: teamId,
          userId: userId,
        );
        return Right(team);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<UserEntity>>> getTeamMembers(int teamId) async {
    if (await networkInfo.isConnected) {
      try {
        final members = await remoteDataSource.getTeamMembers(teamId);
        return Right(members);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }
}
