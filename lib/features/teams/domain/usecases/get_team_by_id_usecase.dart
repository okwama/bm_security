import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/team_entity.dart';
import '../repositories/teams_repository.dart';

class GetTeamByIdUseCase implements UseCase<TeamEntity, GetTeamByIdParams> {
  final TeamsRepository repository;

  GetTeamByIdUseCase(this.repository);

  @override
  Future<Either<Failure, TeamEntity>> call(GetTeamByIdParams params) async {
    return await repository.getTeamById(params.teamId);
  }
}

class GetTeamByIdParams extends Equatable {
  final int teamId;

  const GetTeamByIdParams({required this.teamId});

  @override
  List<Object> get props => [teamId];
}
