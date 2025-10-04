import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/cash_count_entity.dart';
import '../repositories/cash_count_repository.dart';

class SubmitCashCountUseCase implements UseCase<CashCountEntity, SubmitCashCountParams> {
  final CashCountRepository repository;

  SubmitCashCountUseCase(this.repository);

  @override
  Future<Either<Failure, CashCountEntity>> call(SubmitCashCountParams params) async {
    return await repository.submitCashCount(
      requestId: params.requestId,
      staffId: params.staffId,
      ones: params.ones,
      fives: params.fives,
      tens: params.tens,
      twenties: params.twenties,
      forties: params.forties,
      fifties: params.fifties,
      hundreds: params.hundreds,
      twoHundreds: params.twoHundreds,
      fiveHundreds: params.fiveHundreds,
      thousands: params.thousands,
      sealNumber: params.sealNumber,
      imageUrl: params.imageUrl,
      isAtmCashCount: params.isAtmCashCount,
    );
  }
}

class SubmitCashCountParams {
  final int requestId;
  final int staffId;
  final int ones;
  final int fives;
  final int tens;
  final int twenties;
  final int forties;
  final int fifties;
  final int hundreds;
  final int twoHundreds;
  final int fiveHundreds;
  final int thousands;
  final String? sealNumber;
  final String? imageUrl;
  final bool isAtmCashCount;

  SubmitCashCountParams({
    required this.requestId,
    required this.staffId,
    required this.ones,
    required this.fives,
    required this.tens,
    required this.twenties,
    required this.forties,
    required this.fifties,
    required this.hundreds,
    required this.twoHundreds,
    required this.fiveHundreds,
    required this.thousands,
    this.sealNumber,
    this.imageUrl,
    required this.isAtmCashCount,
  });
}
