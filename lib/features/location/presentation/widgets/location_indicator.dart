import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/location_bloc.dart';
import '../bloc/location_state.dart';

class LocationIndicator extends StatelessWidget {
  final int requestId;

  const LocationIndicator({
    Key? key,
    required this.requestId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationBloc, LocationState>(
      builder: (context, state) {
        // Show green dot only when tracking is active for this request
        if (state is LocationTrackingStarted && state.requestId == requestId) {
          return Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.my_location,
                size: 8,
                color: Colors.white,
              ),
            ),
          );
        }
        
        // Show nothing when not tracking
        return const SizedBox.shrink();
      },
    );
  }
}
