import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/cash_count_entity.dart';

abstract class CashCountRepository {
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
  });

  Future<Either<Failure, List<CashCountEntity>>> getCashCounts({
    int? requestId,
    int? staffId,
    bool? isAtmCashCount,
  });

  Future<Either<Failure, CashCountEntity>> getCashCountById(int id);
}
