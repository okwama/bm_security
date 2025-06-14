import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bm_security/services/api_service.dart';
import 'package:get_storage/get_storage.dart';
import 'package:bm_security/services/sos_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';
import 'package:bm_security/pages/sos/emergency_details_page.dart';
import '../../../components/loading_spinner.dart';

class SOSPage extends StatefulWidget {
  const SOSPage({super.key});

  @override
  State<SOSPage> createState() => _SOSPageState();
}

class _SOSPageState extends State<SOSPage> {
  bool _isLoading = false;
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLocationEnabled = false;
  String? _selectedDistressType;
  Map<String, dynamic>? _userData;

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
    _loadUserData();
    _checkLocationPermission();
  }

  void _loadUserData() {
    final box = GetStorage();
    // Try to get user data from different possible storage keys
    final user = box.read('user') ?? box.read('user_data');

    print('=== Loading User Data ===');
    print('Raw user data from storage: $user');

    if (user != null && user is Map<String, dynamic>) {
      final id = user['id'] ?? user['user_id'];
      final name = user['name'] ?? user['user_name'];

      print('Extracted values:');
      print('ID: $id (${id.runtimeType})');
      print('Name: $name (${name.runtimeType})');

      setState(() {
        _userData = {
          'id': int.tryParse((id ?? '').toString()) ?? 0,
          'name': name ?? '',
        };
      });
      print('Processed user data: $_userData');
    } else {
      print('No user data found in storage');
      print('Storage contents: ${box.read('user')}');
      print('Storage contents (user_data): ${box.read('user_data')}');
      _showErrorDialog("User information not found. Please log in again.");
    }
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
      print('Error checking location permission: $e');
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
        print('Error getting address: $e');
      }
    } catch (e) {
      print('Error getting location: $e');
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

    // Validate user data with detailed logging
    print('=== Validating User Data for SOS ===');
    print('User data: $_userData');

    if (_userData == null) {
      print('User data is null');
      _showErrorDialog("User information not found. Please log in again.");
      return;
    }

    if (_userData!['id'] == 0) {
      print('Invalid user ID: ${_userData!['id']}');
      _showErrorDialog("Invalid user ID. Please log in again.");
      return;
    }

    if (_userData!['name'].isEmpty) {
      print('Empty user name');
      _showErrorDialog("User name is missing. Please log in again.");
      return;
    }

    bool confirm = await _showSOSConfirmationDialog();
    if (!confirm) return;

    setState(() => _isLoading = true);

    try {
      print('Sending SOS with user data:');
      print('User ID: ${_userData!['id']}');
      print('User Name: ${_userData!['name']}');

      await SosService.sendSOS(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        distressType: _selectedDistressType!,
      );
      _showSuccessDialog(
        "SOS alert sent successfully!\n\n"
        "Emergency responders have been notified of your location.\n"
        "Please stay calm and wait for assistance.",
      );
    } catch (e) {
      print('SOS Error: $e');
      _showErrorDialog(
          "Failed to send SOS. Please try again or contact emergency services directly.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _showSOSConfirmationDialog() async {
    final distressType = _distressTypes.firstWhere(
      (type) => type['id'] == _selectedDistressType,
      orElse: () => {'name': 'Unknown'},
    );

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                const SizedBox(width: 8),
                const Text('Send SOS Alert?'),
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
                  Text('Your Location:'),
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
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Success'),
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
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Error'),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmergencyDetailsPage(
                    currentPosition: _currentPosition,
                    currentAddress: _currentAddress,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmergencyDetailsPage(
                currentPosition: _currentPosition,
                currentAddress: _currentAddress,
              ),
            ),
          );
        },
        label: const Text('Emergency Contacts'),
        icon: const Icon(Icons.phone),
        backgroundColor: Colors.red,
      ),
      body: _isLoading
          ? const LoadingSpinner.fullScreen(
              message:
                  'Sending SOS Alert...\nPlease wait while we notify emergency services')
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Location Status
                    if (!_isLocationEnabled)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_off,
                                color: Colors.orange),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Location access is required for SOS functionality',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                            TextButton(
                              onPressed: _checkLocationPermission,
                              child: const Text('Enable Location'),
                            ),
                          ],
                        ),
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
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _distressTypes.length,
                      itemBuilder: (context, index) {
                        final type = _distressTypes[index];
                        final isSelected = _selectedDistressType == type['id'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDistressType = type['id'];
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.red.shade100
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.red
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  type['icon'],
                                  size: 32,
                                  color: isSelected ? Colors.red : Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  type['name'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.red
                                        : Colors.grey.shade700,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Main SOS Button
                    GestureDetector(
                      onTap: _isLoading ? null : _sendSOS,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              spreadRadius: 5,
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.sos,
                              size: 80,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'SEND SOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tap to send emergency alert',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
