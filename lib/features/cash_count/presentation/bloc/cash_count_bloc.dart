import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/cash_count_entity.dart';
import '../../domain/usecases/submit_cash_count_usecase.dart';

part 'cash_count_event.dart';
part 'cash_count_state.dart';

class CashCountBloc extends Bloc<CashCountEvent, CashCountState> {
  final SubmitCashCountUseCase submitCashCountUseCase;

  CashCountBloc({
    required this.submitCashCountUseCase,
  }) : super(CashCountInitial()) {
    on<SubmitCashCountEvent>(_onSubmitCashCount);
    on<UpdateDenominationEvent>(_onUpdateDenomination);
    on<ClearCashCountEvent>(_onClearCashCount);
  }

  Future<void> _onSubmitCashCount(
    SubmitCashCountEvent event,
    Emitter<CashCountState> emit,
  ) async {
    emit(CashCountSubmitting());
    
    final result = await submitCashCountUseCase(SubmitCashCountParams(
      requestId: event.requestId,
      staffId: event.staffId,
      ones: event.ones,
      fives: event.fives,
      tens: event.tens,
      twenties: event.twenties,
      forties: event.forties,
      fifties: event.fifties,
      hundreds: event.hundreds,
      twoHundreds: event.twoHundreds,
      fiveHundreds: event.fiveHundreds,
      thousands: event.thousands,
      sealNumber: event.sealNumber,
      imageUrl: event.imageUrl,
      isAtmCashCount: event.isAtmCashCount,
    ));

    result.fold(
      (failure) => emit(CashCountError(failure.message)),
      (cashCount) => emit(CashCountSubmitted(cashCount)),
    );
  }

  void _onUpdateDenomination(
    UpdateDenominationEvent event,
    Emitter<CashCountState> emit,
  ) {
    if (state is CashCountInitial) {
      final currentState = state as CashCountInitial;
      emit(currentState.copyWith(
        denominations: currentState.denominations.copyWith(
          ones: event.denomination == 'ones' ? event.value : currentState.denominations.ones,
          fives: event.denomination == 'fives' ? event.value : currentState.denominations.fives,
          tens: event.denomination == 'tens' ? event.value : currentState.denominations.tens,
          twenties: event.denomination == 'twenties' ? event.value : currentState.denominations.twenties,
          forties: event.denomination == 'forties' ? event.value : currentState.denominations.forties,
          fifties: event.denomination == 'fifties' ? event.value : currentState.denominations.fifties,
          hundreds: event.denomination == 'hundreds' ? event.value : currentState.denominations.hundreds,
          twoHundreds: event.denomination == 'twoHundreds' ? event.value : currentState.denominations.twoHundreds,
          fiveHundreds: event.denomination == 'fiveHundreds' ? event.value : currentState.denominations.fiveHundreds,
          thousands: event.denomination == 'thousands' ? event.value : currentState.denominations.thousands,
        ),
      ));
    }
  }

  void _onClearCashCount(
    ClearCashCountEvent event,
    Emitter<CashCountState> emit,
  ) {
    emit(CashCountInitial());
  }
}

class CashCountDenominations extends Equatable {
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

  const CashCountDenominations({
    this.ones = 0,
    this.fives = 0,
    this.tens = 0,
    this.twenties = 0,
    this.forties = 0,
    this.fifties = 0,
    this.hundreds = 0,
    this.twoHundreds = 0,
    this.fiveHundreds = 0,
    this.thousands = 0,
  });

  double get totalAmount {
    return (ones * 1) +
        (fives * 5) +
        (tens * 10) +
        (twenties * 20) +
        (forties * 40) +
        (fifties * 50) +
        (hundreds * 100) +
        (twoHundreds * 200) +
        (fiveHundreds * 500) +
        (thousands * 1000);
  }

  int get filledCount {
    int count = 0;
    if (ones > 0) count++;
    if (fives > 0) count++;
    if (tens > 0) count++;
    if (twenties > 0) count++;
    if (forties > 0) count++;
    if (fifties > 0) count++;
    if (hundreds > 0) count++;
    if (twoHundreds > 0) count++;
    if (fiveHundreds > 0) count++;
    if (thousands > 0) count++;
    return count;
  }

  @override
  List<Object?> get props => [
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
      ];

  CashCountDenominations copyWith({
    int? ones,
    int? fives,
    int? tens,
    int? twenties,
    int? forties,
    int? fifties,
    int? hundreds,
    int? twoHundreds,
    int? fiveHundreds,
    int? thousands,
  }) {
    return CashCountDenominations(
      ones: ones ?? this.ones,
      fives: fives ?? this.fives,
      tens: tens ?? this.tens,
      twenties: twenties ?? this.twenties,
      forties: forties ?? this.forties,
      fifties: fifties ?? this.fifties,
      hundreds: hundreds ?? this.hundreds,
      twoHundreds: twoHundreds ?? this.twoHundreds,
      fiveHundreds: fiveHundreds ?? this.fiveHundreds,
      thousands: thousands ?? this.thousands,
    );
  }
}
