import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/location_bloc.dart';
import '../bloc/location_event.dart';

class LocationTrackingService {
  static void startTrackingForRequest(BuildContext context, int requestId) {
    context.read<LocationBloc>().add(StartLocationTrackingEvent(requestId: requestId));
  }

  static void stopTracking(BuildContext context) {
    context.read<LocationBloc>().add(const StopLocationTrackingEvent());
  }
}
