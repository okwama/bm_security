import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_local_datasource.dart';
import '../datasources/location_remote_datasource.dart';
import '../models/location_model.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationRemoteDataSource remoteDataSource;
  final LocationLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  LocationRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, void>> updateLocation({
    required int requestId,
    required double latitude,
    required double longitude,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updateLocation(
          requestId: requestId,
          latitude: latitude,
          longitude: longitude,
        );
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, code: e.code));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(message: e.message, code: e.code));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<LocationEntity>>> getLocationHistory({
    required int requestId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteLocations = await remoteDataSource.getLocationHistory(
          requestId: requestId,
        );
        
        // Cache the results
        await localDataSource.cacheLocationHistory(
          requestId: requestId,
          locations: remoteLocations,
        );
        
        return Right(remoteLocations);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message, code: e.code));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(message: e.message, code: e.code));
      }
    } else {
      try {
        final cachedLocations = await localDataSource.getCachedLocationHistory(
          requestId: requestId,
        );
        return Right(cachedLocations);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }
}
