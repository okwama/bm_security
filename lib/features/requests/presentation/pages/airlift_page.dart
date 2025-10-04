import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/request_entity.dart';
import '../widgets/loading_widget.dart';
import '../../../cash_count/presentation/pages/cash_count_page.dart';
import '../../../cash_count/domain/entities/cash_count_entity.dart';
import '../../../../services/location_service.dart';

class AirliftPage extends StatefulWidget {
  final RequestEntity request;

  const AirliftPage({
    super.key,
    required this.request,
  });

  @override
  State<AirliftPage> createState() => _AirliftPageState();
}

class _AirliftPageState extends State<AirliftPage> {
  final _picker = ImagePicker();
  final _notesController = TextEditingController();
  final _pickupNotesController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isTracking = false;
  bool _isPickedUp = false;
  String _selectedDestination = 'vault'; // Default to vault
  XFile? _pickupImageFile;
  String? _pickupImageUrl;
  String? _deliveryImageUrl;
  String? _bankingSlipImageUrl;
  Position? _currentPosition;
  CashCountEntity? _cashCount;
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
      print('Error updating location: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null && mounted) {
        setState(() => _pickupImageFile = image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToCashCount() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CashCountPage(
          requestId: widget.request.id,
          staffId: widget.request.staffId ?? 0,
          isAtmCashCount: false,
          onConfirm: (cashCount) {
            setState(() => _cashCount = cashCount);
          },
        ),
      ),
    );

    if (result != null && result is CashCountEntity) {
      setState(() => _cashCount = result);
    }
  }

  Future<void> _confirmPickup() async {
    if (_isSubmitting) return;

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
      final token = await _storage.read(key: AppConstants.accessTokenKey);
      if (token == null) {
        throw Exception('No access token found');
      }

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/cash-counts'),
        headers: {
          AppConstants.contentTypeHeader: AppConstants.applicationJson,
          AppConstants.authorizationHeader: AppConstants.getBearerToken(token),
        },
        body: json.encode({
          'request_id': widget.request.id,
          'staff_id': widget.request.staffId ?? 0,
          'ones': _cashCount!.ones,
          'fives': _cashCount!.fives,
          'tens': _cashCount!.tens,
          'twenties': _cashCount!.twenties,
          'forties': _cashCount!.forties,
          'fifties': _cashCount!.fifties,
          'hundreds': _cashCount!.hundreds,
          'twoHundreds': _cashCount!.twoHundreds,
          'fiveHundreds': _cashCount!.fiveHundreds,
          'thousands': _cashCount!.thousands,
          'totalAmount': _cashCount!.totalAmount,
          'status': 'pending',
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to save cash count: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving cash count: $e');
      throw e;
    }
  }

  Future<void> _updateRequestStatusToInProgress() async {
    try {
      final token = await _storage.read(key: AppConstants.accessTokenKey);
      if (token == null) {
        throw Exception('No access token found');
      }

      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/requests/${widget.request.id}/status'),
        headers: {
          AppConstants.contentTypeHeader: AppConstants.applicationJson,
          AppConstants.authorizationHeader: AppConstants.getBearerToken(token),
        },
        body: json.encode({
          'status': 2, // IN_PROGRESS
          'staff_id': widget.request.staffId,
          'latitude': _currentPosition?.latitude,
          'longitude': _currentPosition?.longitude,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update request status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating request status: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Airlift Service'),
        backgroundColor: const Color(AppConstants.primaryColorValue),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showInfoDialog();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRequestInfoCard(),
                  const SizedBox(height: 16),
                  _buildDestinationSelection(),
                  const SizedBox(height: 16),
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildPickupSection(),
                  const SizedBox(height: 16),
                  _buildLocationSection(),
                  const SizedBox(height: 24),
                  _buildActionButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildRequestInfoCard() {
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
                  Icons.flight,
                  color: const Color(AppConstants.primaryColorValue),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Airlift Request Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConstants.primaryColorValue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Request ID', '#${widget.request.id}'),
            _buildInfoRow('Pickup Location', widget.request.pickupLocation),
            _buildInfoRow('Delivery Location', widget.request.deliveryLocation),
            _buildInfoRow('Priority', widget.request.priority?.toUpperCase() ?? 'MEDIUM'),
            if (widget.request.description != null && widget.request.description!.isNotEmpty)
              _buildInfoRow('Description', widget.request.description!),
          ],
        ),
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
            if (_pickupImageFile != null) ...[
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
                    File(_pickupImageFile!.path),
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
                label: Text(_pickupImageFile != null ? 'Retake Photo' : 'Take Photo'),
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
            : const Icon(Icons.flight),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Airlift Service'),
          content: const Text(
            'Airlift is an emergency cash transport service for urgent situations. '
            'This service requires immediate pickup and delivery with enhanced security measures.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
