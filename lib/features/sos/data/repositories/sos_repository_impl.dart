import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/sos_repository.dart';
import '../datasources/sos_remote_datasource.dart';

class SOSRepositoryImpl implements SOSRepository {
  final SOSRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  SOSRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, bool>> sendSOS({
    required double latitude,
    required double longitude,
    required String distressType,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.sendSOS(
          latitude: latitude,
          longitude: longitude,
          distressType: distressType,
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
