import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/request_entity.dart';
import '../../domain/repositories/requests_repository.dart';
import '../datasources/requests_local_datasource.dart';
import '../datasources/requests_remote_datasource.dart';

class RequestsRepositoryImpl implements RequestsRepository {
  final RequestsRemoteDataSource remoteDataSource;
  final RequestsLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  RequestsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<RequestEntity>>> getRequests({
    int? status,
    int? teamId,
    int? staffId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteRequests = await remoteDataSource.getRequests(
          status: status,
          teamId: teamId,
          staffId: staffId,
        );
        
        // Cache the requests
        await localDataSource.cacheRequests(remoteRequests);
        
        return Right(remoteRequests);
      } on ServerException catch (e) {
        // Try to get cached data on server error
        try {
          final cachedRequests = await localDataSource.getCachedRequests();
          if (cachedRequests.isNotEmpty) {
            return Right(cachedRequests);
          }
        } catch (_) {}
        
        return Left(ServerFailure(message: e.message));
      }
    } else {
      // Use cached data when offline
      try {
        final cachedRequests = await localDataSource.getCachedRequests();
        return Right(cachedRequests);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  @override
  Future<Either<Failure, bool>> updateRequestStatus({
    required int requestId,
    required int newStatus,
    int? staffId,
    double? latitude,
    double? longitude,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.updateRequestStatus(
          requestId: requestId,
          newStatus: newStatus,
          staffId: staffId,
          latitude: latitude,
          longitude: longitude,
        );
        
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }
}
