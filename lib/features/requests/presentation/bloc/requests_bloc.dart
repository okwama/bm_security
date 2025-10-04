import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/request_entity.dart';
import '../../domain/usecases/get_requests_usecase.dart';
import '../../domain/usecases/update_request_status_usecase.dart';

part 'requests_event.dart';
part 'requests_state.dart';

class RequestsBloc extends Bloc<RequestsEvent, RequestsState> {
  final GetRequestsUseCase getRequestsUseCase;
  final UpdateRequestStatusUseCase updateRequestStatusUseCase;

  RequestsBloc({
    required this.getRequestsUseCase,
    required this.updateRequestStatusUseCase,
  }) : super(RequestsInitial()) {
    on<LoadRequestsEvent>(_onLoadRequests);
    on<UpdateRequestStatusEvent>(_onUpdateRequestStatus);
    on<RefreshRequestsEvent>(_onRefreshRequests);
  }

  Future<void> _onLoadRequests(
    LoadRequestsEvent event,
    Emitter<RequestsState> emit,
  ) async {
    emit(RequestsLoading());
    
    final result = await getRequestsUseCase(GetRequestsParams(
      status: event.status,
      teamId: event.teamId,
      staffId: event.staffId,
    ));

    result.fold(
      (failure) => emit(RequestsError(failure.message)),
      (requests) => emit(RequestsLoaded(requests)),
    );
  }

  Future<void> _onUpdateRequestStatus(
    UpdateRequestStatusEvent event,
    Emitter<RequestsState> emit,
  ) async {
    if (state is RequestsLoaded) {
      final currentState = state as RequestsLoaded;
      
      // Optimistically update the UI
      final updatedRequests = currentState.requests.map((request) {
        if (request.id == event.requestId) {
          return RequestEntity(
            id: request.id,
            userId: request.userId,
            userName: request.userName,
            serviceTypeId: request.serviceTypeId,
            serviceTypeName: request.serviceTypeName,
            price: request.price,
            pickupLocation: request.pickupLocation,
            deliveryLocation: request.deliveryLocation,
            pickupDate: request.pickupDate,
            description: request.description,
            priority: request.priority,
            myStatus: event.newStatus,
            status: _getStatusString(event.newStatus),
            staffId: request.staffId,
            staffName: request.staffName,
            teamId: request.teamId,
            latitude: request.latitude,
            longitude: request.longitude,
            branchId: request.branchId,
            sealNumberId: request.sealNumberId,
            atmId: request.atmId,
            serviceType: request.serviceType,
            cashCounts: request.cashCounts,
            createdAt: request.createdAt,
            updatedAt: request.updatedAt,
          );
        }
        return request;
      }).toList();

      emit(RequestsLoaded(updatedRequests));

      // Make the API call
      final result = await updateRequestStatusUseCase(UpdateRequestStatusParams(
        requestId: event.requestId,
        newStatus: event.newStatus,
        staffId: event.staffId,
        latitude: event.latitude,
        longitude: event.longitude,
      ));

      result.fold(
        (failure) {
          // Revert the optimistic update on failure
          emit(RequestsError(failure.message));
          add(LoadRequestsEvent(
            status: event.status,
            teamId: event.teamId,
            staffId: event.staffId,
          ));
        },
        (success) {
          // Keep the updated state
          emit(RequestsLoaded(updatedRequests));
        },
      );
    }
  }

  Future<void> _onRefreshRequests(
    RefreshRequestsEvent event,
    Emitter<RequestsState> emit,
  ) async {
    add(LoadRequestsEvent(
      status: event.status,
      teamId: event.teamId,
      staffId: event.staffId,
    ));
  }

  String _getStatusString(int status) {
    switch (status) {
      case 0:
        return 'Pending';
      case 1:
        return 'In Progress';
      case 2:
        return 'Completed';
      case 3:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }
}
