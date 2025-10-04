part of 'cash_count_bloc.dart';

abstract class CashCountState extends Equatable {
  const CashCountState();

  @override
  List<Object?> get props => [];
}

class CashCountInitial extends CashCountState {
  final CashCountDenominations denominations;

  const CashCountInitial({
    this.denominations = const CashCountDenominations(),
  });

  @override
  List<Object?> get props => [denominations];

  CashCountInitial copyWith({
    CashCountDenominations? denominations,
  }) {
    return CashCountInitial(
      denominations: denominations ?? this.denominations,
    );
  }
}

class CashCountSubmitting extends CashCountState {}

class CashCountSubmitted extends CashCountState {
  final CashCountEntity cashCount;

  const CashCountSubmitted(this.cashCount);

  @override
  List<Object?> get props => [cashCount];
}

class CashCountError extends CashCountState {
  final String message;

  const CashCountError(this.message);

  @override
  List<Object?> get props => [message];
}
