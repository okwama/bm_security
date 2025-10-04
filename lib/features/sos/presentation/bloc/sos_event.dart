part of 'sos_bloc.dart';

abstract class SOSEvent extends Equatable {
  const SOSEvent();

  @override
  List<Object?> get props => [];
}

class SendSOSEvent extends SOSEvent {
  final double latitude;
  final double longitude;
  final String distressType;

  const SendSOSEvent({
    required this.latitude,
    required this.longitude,
    required this.distressType,
  });

  @override
  List<Object?> get props => [latitude, longitude, distressType];
}
