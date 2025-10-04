import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/usecases/send_sos_usecase.dart';

part 'sos_event.dart';
part 'sos_state.dart';

class SOSBloc extends Bloc<SOSEvent, SOSState> {
  final SendSOSUseCase sendSOSUseCase;

  SOSBloc({
    required this.sendSOSUseCase,
  }) : super(SOSInitial()) {
    on<SendSOSEvent>(_onSendSOS);
  }

  Future<void> _onSendSOS(
    SendSOSEvent event,
    Emitter<SOSState> emit,
  ) async {
    emit(SOSLoading());
    
    final result = await sendSOSUseCase(SendSOSParams(
      latitude: event.latitude,
      longitude: event.longitude,
      distressType: event.distressType,
    ));

    result.fold(
      (failure) => emit(SOSError(failure.message)),
      (success) => emit(SOSSuccess()),
    );
  }
}
