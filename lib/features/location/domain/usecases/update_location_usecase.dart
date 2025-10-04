import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/location_entity.dart';
import '../repositories/location_repository.dart';

class UpdateLocationUseCase implements UseCase<void, UpdateLocationParams> {
  final LocationRepository repository;

  UpdateLocationUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateLocationParams params) async {
    return await repository.updateLocation(
      requestId: params.requestId,
      latitude: params.latitude,
      longitude: params.longitude,
    );
  }
}

class UpdateLocationParams {
  final int requestId;
  final double latitude;
  final double longitude;

  UpdateLocationParams({
    required this.requestId,
    required this.latitude,
    required this.longitude,
  });
}
