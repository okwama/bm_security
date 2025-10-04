import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../services/http/auth_service.dart';
import '../../domain/entities/request_entity.dart';
import '../../../cash_count/presentation/pages/cash_count_page.dart';
import '../../../cash_count/domain/entities/cash_count_entity.dart';
import '../widgets/loading_widget.dart';
import '../../../../services/location_service.dart';

class BssSlipPage extends StatefulWidget {
  final RequestEntity request;

  const BssSlipPage({
    super.key,
    required this.request,
  });

  @override
  State<BssSlipPage> createState() => _BssSlipPageState();
}

class _BssSlipPageState extends State<BssSlipPage> {
  final _picker = ImagePicker();
  final _notesController = TextEditingController();
  final _pickupNotesController = TextEditingController();
  final _sealNumberController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isTracking = false;
  bool _isPickedUp = false;
  String _selectedDestination = 'vault'; // Default to vault
  XFile? _imageFile;
  String? _imageUrl;
  CashCountEntity? _cashCount;
  Position? _currentPosition;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _pickupNotesController.dispose();
    _sealNumberController.dispose();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    try {
      final hasPermission = await Geolocator.checkPermission();
      if (hasPermission == LocationPermission.denied) {
        final requestPermission = await Geolocator.requestPermission();
        if (requestPermission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required for tracking'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (!mounted) return;
      setState(() => _isTracking = true);

      // Get initial position
      await _updateLocation();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isTracking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting location tracking: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() => _currentPosition = position);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _navigateToCashCount() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CashCountPage(
            requestId: widget.request.id,
            staffId: 1, // TODO: Get from current user
            isAtmCashCount: false, // BSS uses regular cash_counts table
          ),
        ),
      );

      if (result != null && result is CashCountEntity) {
        if (!mounted) return;
        setState(() => _cashCount = result);
      }
    } catch (e) {
      debugPrint('Error navigating to cash count: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Error: ${e.toString()}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null && mounted) {
        setState(() {
          _imageFile = image;
          _imageUrl = null; // Reset URL when new image is picked
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmPickup() async {
    // Check location permission before pickup
    final locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.denied) {
      final requestedPermission = await Geolocator.requestPermission();
      if (requestedPermission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required for tracking. Please enable in Settings.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }
    
    if (locationPermission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission permanently denied. Please enable in Settings → Apps → BM Security → Permissions → Location'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }
    
    // Validate requirements based on destination
    if ((_selectedDestination == 'vault' || _selectedDestination == 'bank') && _cashCount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cash count is required for Vault and Bank destinations'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isPickedUp = true);

    try {
      // Save cash count data to server for both vault and bank destinations
      if (_cashCount != null) {
        await _saveCashCountToServer();
      }

      // Update request status to in-progress
      await _updateRequestStatusToInProgress();
      
      // Start location tracking for in-progress request
      try {
        final locationService = LocationService();
        await locationService.startTracking(widget.request.id.toString(), myStatus: 2);
        print('✅ Location tracking started for request: ${widget.request.id}');
      } catch (e) {
        print('❌ Failed to start location tracking: $e');
        // Don't fail the pickup if location tracking fails
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pickup confirmed! Request moved to In Progress.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Close the page and return to home
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPickedUp = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error confirming pickup: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveCashCountToServer() async {
    if (_cashCount == null) return;

    try {
      // Prepare cash count data
      final cashCountData = {
        'ones': _cashCount!.ones,
        'fives': _cashCount!.fives,
        'tens': _cashCount!.tens,
        'twenties': _cashCount!.twenties,
        'fifties': _cashCount!.fifties,
        'hundreds': _cashCount!.hundreds,
        'twoHundreds': _cashCount!.twoHundreds,
        'fiveHundreds': _cashCount!.fiveHundreds,
        'thousands': _cashCount!.thousands,
        'totalAmount': _cashCount!.totalAmount,
        'photoUrl': _cashCount!.imageUrl,
        'notes': null, // Add notes field
      };

      // Make API call to save cash count
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/requests/${widget.request.id}/cash-count'),
        headers: {
          AppConstants.contentTypeHeader: AppConstants.applicationJson,
          AppConstants.authorizationHeader: AppConstants.getBearerToken(await _getTokenFromStorage()),
        },
        body: jsonEncode(cashCountData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Cash count saved successfully: ${_cashCount!.totalAmount} KES');
      } else {
        print('❌ Failed to save cash count: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        throw Exception('Failed to save cash count: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error saving cash count: $e');
      throw Exception('Error saving cash count: $e');
    }
  }

  Future<void> _updateRequestStatusToInProgress() async {
    try {
      // Update request status to in-progress (status = 2)
      final response = await http.patch(
        Uri.parse('${AppConstants.baseUrl}/requests/${widget.request.id}/status'),
        headers: {
          AppConstants.contentTypeHeader: AppConstants.applicationJson,
          AppConstants.authorizationHeader: AppConstants.getBearerToken(await _getTokenFromStorage()),
        },
        body: jsonEncode({
          'status': 2, // In Progress
          'actualPickupTime': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Request status updated to in-progress');
      } else {
        print('❌ Failed to update request status: ${response.statusCode}');
        throw Exception('Failed to update request status');
      }
    } catch (e) {
      print('❌ Error updating request status: $e');
      throw Exception('Error updating request status: $e');
    }
  }

  Future<String> _getTokenFromStorage() async {
    try {
      final authService = AuthService();
      final token = await authService.accessToken;
      if (token != null) {
        return AppConstants.getBearerToken(token);
      } else {
        throw Exception('No access token found');
      }
    } catch (e) {
      print('❌ Error getting token from storage: $e');
      throw Exception('Error getting token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('BSS Service'),
        backgroundColor: const Color(AppConstants.primaryColorValue),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading BSS service...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRequestInfo(),
                  const SizedBox(height: 16),
                  _buildDestinationSelection(),
                  const SizedBox(height: 16),
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  if (!_isPickedUp) ...[
                    _buildPickupSection(),
                    const SizedBox(height: 16),
                  ],
                  _buildLocationSection(),
                  const SizedBox(height: 24),
                  _buildActionButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildRequestInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: const Color(AppConstants.primaryColorValue),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Request Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConstants.primaryColorValue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Request ID', '${widget.request.id}'),
            _buildInfoRow('Service Type', widget.request.serviceType?.name ?? 'BSS'),
            if (widget.request.pickupLocation != null)
              _buildInfoRow('Pickup Location', widget.request.pickupLocation!),
            if (widget.request.deliveryLocation != null)
              _buildInfoRow('Delivery Location', widget.request.deliveryLocation!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationSelection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: const Color(AppConstants.primaryColorValue),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Money Destination',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConstants.primaryColorValue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedDestination,
              decoration: InputDecoration(
                labelText: 'Select Destination',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'vault',
                  child: Text('Vault'),
                ),
                DropdownMenuItem(
                  value: 'bank',
                  child: Text('Bank'),
                ),
              ],
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _selectedDestination = value;
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              _selectedDestination == 'vault' 
                  ? 'Cash count will be required for Vault destination'
                  : 'Banking slip photo will be required for Bank destination',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: const Color(AppConstants.primaryColorValue),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Progress Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConstants.primaryColorValue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatusStep(
                  'Pickup',
                  Icons.location_on,
                  _isPickedUp ? Colors.green : Colors.blue,
                  _isPickedUp,
                ),
                Expanded(
                  child: Container(
                    height: 2,
                    color: _isPickedUp ? Colors.green : Colors.grey[300],
                  ),
                ),
                _buildStatusStep(
                  'Delivery',
                  Icons.local_shipping,
                  _isPickedUp ? Colors.blue : Colors.grey,
                  false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusStep(String title, IconData icon, Color color, bool isCompleted) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted ? color : Colors.grey[200],
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: isCompleted ? Colors.white : color,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isCompleted ? color : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPickupSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: const Color(AppConstants.primaryColorValue),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Pickup Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConstants.primaryColorValue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pickupNotesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Pickup Notes',
                hintText: 'Enter any notes about the pickup...',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 12),
            // Cash count section for Vault and Bank destinations
            if (_selectedDestination == 'vault' || _selectedDestination == 'bank') ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_balance, color: Colors.blue[700], size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Cash Count Required',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_cashCount != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.pending, color: Colors.blue[600], size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total: ${_cashCount!.totalAmount} KES',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Ready to save on pickup confirmation',
                                    style: TextStyle(
                                      color: Colors.blue[600],
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _navigateToCashCount,
                              icon: Icon(Icons.edit, color: Colors.blue[600], size: 16),
                              tooltip: 'Edit cash count',
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _navigateToCashCount,
                          icon: const Icon(Icons.calculate, size: 16),
                          label: const Text('Count Cash'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            if (_imageFile != null) ...[
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_imageFile!.path),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt, size: 16),
                label: Text(_imageFile != null ? 'Retake Photo' : 'Take Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.black87,
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSealNumberSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: const Color(AppConstants.primaryColorValue),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Seal Number',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConstants.primaryColorValue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sealNumberController,
              decoration: InputDecoration(
                hintText: 'Enter seal number...',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.note,
                  color: const Color(AppConstants.primaryColorValue),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Pickup Notes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConstants.primaryColorValue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pickupNotesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter any notes about the pickup...',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.camera_alt,
                  color: const Color(AppConstants.primaryColorValue),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Photo Evidence',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConstants.primaryColorValue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_imageFile != null) ...[
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_imageFile!.path),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt, size: 16),
                label: Text(_imageFile != null ? 'Retake Photo' : 'Take Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.black87,
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: const Color(AppConstants.primaryColorValue),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Current Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConstants.primaryColorValue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_currentPosition != null) ...[
              _buildInfoRow('Latitude', _currentPosition!.latitude.toStringAsFixed(6)),
              _buildInfoRow('Longitude', _currentPosition!.longitude.toStringAsFixed(6)),
              _buildInfoRow('Accuracy', '${_currentPosition!.accuracy.toStringAsFixed(1)}m'),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_searching,
                      color: Colors.orange[600],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isTracking ? 'Getting location...' : 'Location not available',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _confirmPickup,
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.location_on),
        label: Text(
          _isSubmitting 
              ? 'Confirming...' 
              : (_selectedDestination == 'vault' || _selectedDestination == 'bank'
                  ? 'Confirm Pickup (Cash Count Required)'
                  : 'Confirm Pickup'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(AppConstants.primaryColorValue),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}

