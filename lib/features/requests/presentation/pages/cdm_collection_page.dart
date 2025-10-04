import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/request_entity.dart';
import '../../../cash_count/presentation/pages/cash_count_page.dart';
import '../../../cash_count/domain/entities/cash_count_entity.dart';
import '../widgets/loading_widget.dart';

class CdmCollectionPage extends StatefulWidget {
  final RequestEntity request;

  const CdmCollectionPage({
    super.key,
    required this.request,
  });

  @override
  State<CdmCollectionPage> createState() => _CdmCollectionPageState();
}

class _CdmCollectionPageState extends State<CdmCollectionPage> {
  final _picker = ImagePicker();
  final _notesController = TextEditingController();
  final _pickupNotesController = TextEditingController();
  final _sealNumberController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isTracking = false;
  XFile? _imageFile;
  String? _imageUrl;
  CashCountEntity? _cashCount;
  Position? _currentPosition;

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
            isAtmCashCount: false, // CDM uses regular cash_counts table
          ),
        ),
      );

      if (result != null && result is CashCountEntity) {
        if (!mounted) return;
        setState(() => _cashCount = result);
      }
    } catch (e) {
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

  Future<void> _submitCollection() async {
    if (_cashCount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete cash count before submitting'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = true);

    try {
      // TODO: Implement actual submission logic
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CDM collection completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting collection: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('CDM Collection'),
        backgroundColor: const Color(AppConstants.primaryColorValue),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading CDM collection...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRequestInfo(),
                  const SizedBox(height: 16),
                  _buildCashCountSection(),
                  const SizedBox(height: 16),
                  _buildSealNumberSection(),
                  const SizedBox(height: 16),
                  _buildNotesSection(),
                  const SizedBox(height: 16),
                  _buildImageSection(),
                  const SizedBox(height: 16),
                  _buildLocationSection(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
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
            _buildInfoRow('Service Type', widget.request.serviceType?.name ?? 'CDM Collection'),
            if (widget.request.pickupLocation != null)
              _buildInfoRow('Collection Location', widget.request.pickupLocation!),
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

  Widget _buildCashCountSection() {
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
                  Icons.account_balance_wallet,
                  color: const Color(AppConstants.primaryColorValue),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Cash Count',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConstants.primaryColorValue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_cashCount != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cash count completed - Total: ${_cashCount!.totalAmount} KES',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _navigateToCashCount,
                icon: Icon(
                  _cashCount != null ? Icons.edit : Icons.add,
                  size: 16,
                ),
                label: Text(
                  _cashCount != null ? 'Edit Cash Count' : 'Enter Denominations',
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  backgroundColor: Colors.grey.shade100,
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
                  'Collection Notes',
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
                hintText: 'Enter any notes about the collection...',
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

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitCollection,
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.check_circle),
        label: Text(
          _isSubmitting ? 'Submitting...' : 'Complete Collection',
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
