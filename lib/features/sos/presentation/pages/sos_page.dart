import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../bloc/sos_bloc.dart';
import '../widgets/emergency_type_selector.dart';
import '../widgets/sos_button.dart';
import '../widgets/location_status_card.dart';
import '../widgets/loading_widget.dart';

class SOSPage extends StatefulWidget {
  const SOSPage({super.key});

  @override
  State<SOSPage> createState() => _SOSPageState();
}

class _SOSPageState extends State<SOSPage> {
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLocationEnabled = false;
  String? _selectedDistressType;

  final List<Map<String, dynamic>> _distressTypes = [
    {
      'id': 'medical',
      'name': 'Medical Emergency',
      'icon': Icons.local_hospital
    },
    {'id': 'security', 'name': 'Security Threat', 'icon': Icons.security},
    {'id': 'fire', 'name': 'Fire Emergency', 'icon': Icons.fire_truck},
    {'id': 'other', 'name': 'Other Emergency', 'icon': Icons.warning},
  ];

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      setState(() {
        _isLocationEnabled = permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse;
      });

      if (!_isLocationEnabled) {
        permission = await Geolocator.requestPermission();
        setState(() {
          _isLocationEnabled = permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse;
        });
      }

      if (_isLocationEnabled) {
        await _getCurrentLocation();
      }
    } catch (e) {
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      // Get address from coordinates
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          setState(() {
            _currentAddress =
                '${place.street}, ${place.locality}, ${place.country}';
          });
        }
      } catch (e) {
      }
    } catch (e) {
    }
  }

  Future<void> _sendSOS() async {
    if (!_isLocationEnabled) {
      _showErrorDialog(
          "Location access is required to send SOS. Please enable location services.");
      return;
    }

    if (_selectedDistressType == null) {
      _showErrorDialog("Please select a type of emergency.");
      return;
    }

    if (_currentPosition == null) {
      _showErrorDialog("Unable to get your location. Please try again.");
      return;
    }

    bool confirm = await _showSOSConfirmationDialog();
    if (!confirm) return;

    context.read<SOSBloc>().add(SendSOSEvent(
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      distressType: _selectedDistressType!,
    ));
  }

  Future<bool> _showSOSConfirmationDialog() async {
    final distressType = _distressTypes.firstWhere(
      (type) => type['id'] == _selectedDistressType,
      orElse: () => {'name': 'Unknown'},
    );

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                SizedBox(width: 8),
                Text('Send SOS Alert?'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Are you sure you want to send an SOS alert? This will notify emergency responders.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text('Emergency Type: ${distressType['name']}'),
                if (_currentPosition != null) ...[
                  const SizedBox(height: 8),
                  const Text('Your Location:'),
                  Text('Latitude: ${_currentPosition!.latitude}'),
                  Text('Longitude: ${_currentPosition!.longitude}'),
                  if (_currentAddress != null) ...[
                    const SizedBox(height: 8),
                    Text('Address: $_currentAddress'),
                  ],
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Send SOS'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Emergency Information',
            onPressed: () {
              // TODO: Navigate to emergency details page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Emergency details - Coming soon')),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to emergency contacts
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Emergency contacts - Coming soon')),
          );
        },
        label: const Text('Emergency Contacts'),
        icon: const Icon(Icons.phone),
        backgroundColor: Colors.red,
      ),
      body: BlocListener<SOSBloc, SOSState>(
        listener: (context, state) {
          if (state is SOSLoading) {
            // Loading state is handled in the build method
          } else if (state is SOSSuccess) {
            _showSuccessDialog(
              "SOS alert sent successfully!\n\n"
              "Emergency responders have been notified of your location.\n"
              "Please stay calm and wait for assistance.",
            );
          } else if (state is SOSError) {
            _showErrorDialog(
                "Failed to send SOS. Please try again or contact emergency services directly.");
          }
        },
        child: BlocBuilder<SOSBloc, SOSState>(
          builder: (context, state) {
            if (state is SOSLoading) {
              return const LoadingWidget(
                message: 'Sending SOS Alert...\nPlease wait while we notify emergency services',
              );
            }

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Location Status
                    if (!_isLocationEnabled)
                      LocationStatusCard(
                        onEnableLocation: _checkLocationPermission,
                      ),
                    const SizedBox(height: 24),

                    // Distress Type Selection
                    const Text(
                      'Select Emergency Type',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    EmergencyTypeSelector(
                      distressTypes: _distressTypes,
                      selectedType: _selectedDistressType,
                      onTypeSelected: (type) {
                        setState(() {
                          _selectedDistressType = type;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Main SOS Button
                    SOSButton(
                      onPressed: _sendSOS,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
