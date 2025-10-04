import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/requests_repository.dart';

class UpdateRequestStatusUseCase implements UseCase<bool, UpdateRequestStatusParams> {
  final RequestsRepository repository;

  UpdateRequestStatusUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(UpdateRequestStatusParams params) async {
    return await repository.updateRequestStatus(
      requestId: params.requestId,
      newStatus: params.newStatus,
      staffId: params.staffId,
      latitude: params.latitude,
      longitude: params.longitude,
    );
  }
}

class UpdateRequestStatusParams {
  final int requestId;
  final int newStatus;
  final int? staffId;
  final double? latitude;
  final double? longitude;

  UpdateRequestStatusParams({
    required this.requestId,
    required this.newStatus,
    this.staffId,
    this.latitude,
    this.longitude,
  });
}
