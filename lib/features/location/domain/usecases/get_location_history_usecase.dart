import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/location_entity.dart';
import '../repositories/location_repository.dart';

class GetLocationHistoryUseCase implements UseCase<List<LocationEntity>, GetLocationHistoryParams> {
  final LocationRepository repository;

  GetLocationHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<LocationEntity>>> call(GetLocationHistoryParams params) async {
    return await repository.getLocationHistory(requestId: params.requestId);
  }
}

class GetLocationHistoryParams {
  final int requestId;

  GetLocationHistoryParams({
    required this.requestId,
  });
}
