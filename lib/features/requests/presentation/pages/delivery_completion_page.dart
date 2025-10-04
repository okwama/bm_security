import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../services/http/auth_service.dart';
import '../../domain/entities/request_entity.dart';
import '../../../../services/location_service.dart';

class DeliveryCompletionPage extends StatefulWidget {
  final RequestEntity request;

  const DeliveryCompletionPage({
    super.key,
    required this.request,
  });

  @override
  State<DeliveryCompletionPage> createState() => _DeliveryCompletionPageState();
}

class _DeliveryCompletionPageState extends State<DeliveryCompletionPage> {
  final _storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _recipientNameController = TextEditingController();
  
  File? _deliveryPhoto;
  File? _bankingSlipPhoto;
  bool _isSubmitting = false;
  bool _isVaultOfficer = false;
  
  // Location
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _recipientNameController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _pickImage(ImageSource source, {bool isBankingSlip = false}) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source);
      
      if (image != null) {
        setState(() {
          if (isBankingSlip) {
            _bankingSlipPhoto = File(image.path);
          } else {
            _deliveryPhoto = File(image.path);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _getTokenFromStorage() async {
    try {
      final authService = AuthService();
      return await authService.accessToken;
    } catch (e) {
      print('Error reading token: $e');
      return null;
    }
  }

  Future<void> _completeDelivery() async {
    if (_isSubmitting) return; // Prevent duplicate submissions
    
    if (!_formKey.currentState!.validate()) return;
    
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location is required for delivery completion'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Stop location tracking (don't fail if this errors)
      try {
        await LocationService().stopTracking();
        print('✅ Location tracking stopped');
      } catch (e) {
        print('⚠️ Location tracking stop failed (non-critical): $e');
        // Continue with delivery completion even if location stop fails
      }

      // Complete delivery
      await _submitDeliveryCompletion();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery completed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Close page and return to home with refresh signal
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete delivery: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitDeliveryCompletion() async {
    final token = await _getTokenFromStorage();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final headers = {
      AppConstants.contentTypeHeader: AppConstants.applicationJson,
      AppConstants.authorizationHeader: AppConstants.getBearerToken(token),
    };

    final body = {
      'requestId': widget.request.id,
      'latitude': _currentPosition!.latitude,
      'longitude': _currentPosition!.longitude,
      'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      'recipientName': _recipientNameController.text.trim().isEmpty ? null : _recipientNameController.text.trim(),
      'isVaultOfficer': _isVaultOfficer,
      'photoUrl': _deliveryPhoto?.path,
      'bankingSlipUrl': _bankingSlipPhoto?.path,
    };

    print('🚚 Submitting delivery completion: $body');

    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/requests/${widget.request.id}/delivery'),
      headers: headers,
      body: jsonEncode(body),
    );

    print('🚚 Delivery completion response: ${response.statusCode}');
    print('🚚 Response body: ${response.body}');
    print('🚚 Status code type: ${response.statusCode.runtimeType}');
    print('🚚 Status code == 201: ${response.statusCode == 201}');
    print('🚚 Status code == 200: ${response.statusCode == 200}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      // Success - delivery completed
      print('✅ Delivery completion successful');
      return;
    } else if (response.statusCode == 400) {
      // Request already completed or invalid status
      final responseBody = jsonDecode(response.body);
      if (responseBody['message']?.contains('not in progress') == true) {
        throw Exception('This request has already been completed');
      }
      throw Exception('Invalid request: ${responseBody['message']}');
    } else {
      throw Exception('Failed to complete delivery: ${response.statusCode} - ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Delivery'),
        backgroundColor: const Color(AppConstants.primaryColorValue),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Request Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request #${widget.request.id}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('From: ${widget.request.pickupLocation}'),
                      Text('To: ${widget.request.deliveryLocation}'),
                      Text('Destination: ${widget.request.destinationType?.toUpperCase() ?? 'VAULT'}'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Location Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Location',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_currentPosition != null) ...[
                        Text('Latitude: ${_currentPosition!.latitude.toStringAsFixed(6)}'),
                        Text('Longitude: ${_currentPosition!.longitude.toStringAsFixed(6)}'),
                      ] else ...[
                        const Text('Getting location...'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _getCurrentLocation,
                          child: const Text('Get Location'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Recipient Name
              TextFormField(
                controller: _recipientNameController,
                decoration: const InputDecoration(
                  labelText: 'Recipient Name (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Delivery Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              
              const SizedBox(height: 16),
              
              // Vault Officer Checkbox
              if (widget.request.destinationType == 'vault') ...[
                CheckboxListTile(
                  title: const Text('I am a Vault Officer'),
                  value: _isVaultOfficer,
                  onChanged: (value) {
                    setState(() {
                      _isVaultOfficer = value ?? false;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
              
              // Delivery Photo
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery Photo (Optional)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_deliveryPhoto != null) ...[
                        Image.file(
                          _deliveryPhoto!,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Banking Slip Photo (for bank deliveries)
              if (widget.request.destinationType == 'bank') ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Banking Slip Photo (Required)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (_bankingSlipPhoto != null) ...[
                          Image.file(
                            _bankingSlipPhoto!,
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(height: 8),
                        ],
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _pickImage(ImageSource.camera, isBankingSlip: true),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Camera'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _pickImage(ImageSource.gallery, isBankingSlip: true),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Gallery'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Complete Delivery Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _completeDelivery,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Completing Delivery...'),
                          ],
                        )
                      : const Text(
                          'Complete Delivery',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
