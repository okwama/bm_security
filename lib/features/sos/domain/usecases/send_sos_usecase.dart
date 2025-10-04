import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/sos_repository.dart';

class SendSOSUseCase implements UseCase<bool, SendSOSParams> {
  final SOSRepository repository;

  SendSOSUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(SendSOSParams params) async {
    return await repository.sendSOS(
      latitude: params.latitude,
      longitude: params.longitude,
      distressType: params.distressType,
    );
  }
}

class SendSOSParams {
  final double latitude;
  final double longitude;
  final String distressType;

  SendSOSParams({
    required this.latitude,
    required this.longitude,
    required this.distressType,
  });
}
