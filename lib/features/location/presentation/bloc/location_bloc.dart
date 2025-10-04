import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/usecases/update_location_usecase.dart';
import '../../domain/usecases/get_location_history_usecase.dart';
import 'location_event.dart';
import 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final UpdateLocationUseCase updateLocationUseCase;
  final GetLocationHistoryUseCase getLocationHistoryUseCase;
  
  Timer? _locationTimer;
  int? _currentRequestId;

  LocationBloc({
    required this.updateLocationUseCase,
    required this.getLocationHistoryUseCase,
  }) : super(LocationInitial()) {
    on<UpdateLocationEvent>(_onUpdateLocation);
    on<LoadLocationHistoryEvent>(_onLoadLocationHistory);
    on<StartLocationTrackingEvent>(_onStartLocationTracking);
    on<StopLocationTrackingEvent>(_onStopLocationTracking);
  }

  Future<void> _onUpdateLocation(
    UpdateLocationEvent event,
    Emitter<LocationState> emit,
  ) async {
    emit(LocationLoading());
    
    final result = await updateLocationUseCase(UpdateLocationParams(
      requestId: event.requestId,
      latitude: event.latitude,
      longitude: event.longitude,
    ));

    result.fold(
      (failure) => emit(LocationError(message: failure.message)),
      (_) => emit(const LocationUpdated(message: 'Location updated successfully')),
    );
  }

  Future<void> _onLoadLocationHistory(
    LoadLocationHistoryEvent event,
    Emitter<LocationState> emit,
  ) async {
    emit(LocationLoading());
    
    final result = await getLocationHistoryUseCase(GetLocationHistoryParams(
      requestId: event.requestId,
    ));

    result.fold(
      (failure) => emit(LocationError(message: failure.message)),
      (locations) => emit(LocationHistoryLoaded(locations: locations)),
    );
  }

  Future<void> _onStartLocationTracking(
    StartLocationTrackingEvent event,
    Emitter<LocationState> emit,
  ) async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          emit(const LocationError(message: 'Location permissions are denied'));
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        emit(const LocationError(message: 'Location permissions are permanently denied'));
        return;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(const LocationError(message: 'Location services are disabled'));
        return;
      }

      _currentRequestId = event.requestId;
      emit(LocationTrackingStarted(requestId: event.requestId));

      // Start periodic location updates (every 30 seconds)
      _locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          add(UpdateLocationEvent(
            requestId: event.requestId,
            latitude: position.latitude,
            longitude: position.longitude,
          ));
        } catch (e) {
          // Handle location error silently to avoid spamming the UI
        }
      });

    } catch (e) {
      emit(LocationError(message: 'Failed to start location tracking: $e'));
    }
  }

  Future<void> _onStopLocationTracking(
    StopLocationTrackingEvent event,
    Emitter<LocationState> emit,
  ) async {
    _locationTimer?.cancel();
    _locationTimer = null;
    _currentRequestId = null;
    emit(LocationTrackingStopped());
  }

  @override
  Future<void> close() {
    _locationTimer?.cancel();
    return super.close();
  }
}
