import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/location_entity.dart';

abstract class LocationRepository {
  Future<Either<Failure, void>> updateLocation({
    required int requestId,
    required double latitude,
    required double longitude,
  });

  Future<Either<Failure, List<LocationEntity>>> getLocationHistory({
    required int requestId,
  });
}
