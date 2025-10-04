import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/cash_count_entity.dart';
import '../../domain/repositories/cash_count_repository.dart';
import '../datasources/cash_count_remote_datasource.dart';

class CashCountRepositoryImpl implements CashCountRepository {
  final CashCountRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  CashCountRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, CashCountEntity>> submitCashCount({
    required int requestId,
    required int staffId,
    required int ones,
    required int fives,
    required int tens,
    required int twenties,
    required int forties,
    required int fifties,
    required int hundreds,
    required int twoHundreds,
    required int fiveHundreds,
    required int thousands,
    String? sealNumber,
    String? imageUrl,
    required bool isAtmCashCount,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.submitCashCount(
          requestId: requestId,
          staffId: staffId,
          ones: ones,
          fives: fives,
          tens: tens,
          twenties: twenties,
          forties: forties,
          fifties: fifties,
          hundreds: hundreds,
          twoHundreds: twoHundreds,
          fiveHundreds: fiveHundreds,
          thousands: thousands,
          sealNumber: sealNumber,
          imageUrl: imageUrl,
          isAtmCashCount: isAtmCashCount,
        );
        
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<CashCountEntity>>> getCashCounts({
    int? requestId,
    int? staffId,
    bool? isAtmCashCount,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getCashCounts(
          requestId: requestId,
          staffId: staffId,
          isAtmCashCount: isAtmCashCount,
        );
        
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, CashCountEntity>> getCashCountById(int id) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getCashCountById(id);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }
}
