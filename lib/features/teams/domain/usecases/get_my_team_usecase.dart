import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/team_entity.dart';
import '../repositories/teams_repository.dart';

class GetMyTeamUseCase implements UseCase<List<TeamEntity>, NoParams> {
  final TeamsRepository repository;

  GetMyTeamUseCase(this.repository);

  @override
  Future<Either<Failure, List<TeamEntity>>> call(NoParams params) async {
    return await repository.getMyTeam();
  }
}
