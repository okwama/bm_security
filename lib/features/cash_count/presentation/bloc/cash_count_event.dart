part of 'cash_count_bloc.dart';

abstract class CashCountEvent extends Equatable {
  const CashCountEvent();

  @override
  List<Object?> get props => [];
}

class SubmitCashCountEvent extends CashCountEvent {
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

  const SubmitCashCountEvent({
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

  @override
  List<Object?> get props => [
        requestId,
        staffId,
        ones,
        fives,
        tens,
        twenties,
        forties,
        fifties,
        hundreds,
        twoHundreds,
        fiveHundreds,
        thousands,
        sealNumber,
        imageUrl,
        isAtmCashCount,
      ];
}

class UpdateDenominationEvent extends CashCountEvent {
  final String denomination;
  final int value;

  const UpdateDenominationEvent({
    required this.denomination,
    required this.value,
  });

  @override
  List<Object?> get props => [denomination, value];
}

class ClearCashCountEvent extends CashCountEvent {
  const ClearCashCountEvent();
}
