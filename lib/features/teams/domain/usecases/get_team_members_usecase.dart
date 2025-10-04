import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/teams_repository.dart';
import '../../../auth/domain/entities/user_entity.dart';

class GetTeamMembersUseCase implements UseCase<List<UserEntity>, GetTeamMembersParams> {
  final TeamsRepository repository;

  GetTeamMembersUseCase(this.repository);

  @override
  Future<Either<Failure, List<UserEntity>>> call(GetTeamMembersParams params) async {
    return await repository.getTeamMembers(params.teamId);
  }
}

class GetTeamMembersParams {
  final int teamId;

  GetTeamMembersParams({required this.teamId});
}
