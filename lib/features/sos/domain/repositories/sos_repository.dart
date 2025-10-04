import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

abstract class SOSRepository {
  Future<Either<Failure, bool>> sendSOS({
    required double latitude,
    required double longitude,
    required String distressType,
  });
}
