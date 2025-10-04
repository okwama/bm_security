import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/request_entity.dart';
import '../repositories/requests_repository.dart';

class GetRequestsUseCase implements UseCase<List<RequestEntity>, GetRequestsParams> {
  final RequestsRepository repository;

  GetRequestsUseCase(this.repository);

  @override
  Future<Either<Failure, List<RequestEntity>>> call(GetRequestsParams params) async {
    return await repository.getRequests(
      status: params.status,
      teamId: params.teamId,
      staffId: params.staffId,
    );
  }
}

class GetRequestsParams {
  final int? status;
  final int? teamId;
  final int? staffId;

  GetRequestsParams({
    this.status,
    this.teamId,
    this.staffId,
  });
}
