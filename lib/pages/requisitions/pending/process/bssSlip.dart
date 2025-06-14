import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../models/request.dart';
import '../../../../models/cash_count.dart';
import '../../../../services/requisitions/requisitions_service.dart';
import '../../../../components/loading_spinner.dart';
import '../../cashCount_page.dart';
import '../../../../utils/auth_config.dart';

class BssSlip extends StatefulWidget {
  final Request requisition;

  const BssSlip({super.key, required this.requisition});

  @override
  State<BssSlip> createState() => _BssSlipState();
}

class _BssSlipState extends State<BssSlip> {
  final RequisitionsService _requisitionsService = RequisitionsService();
  final _storage = GetStorage();
  final _picker = ImagePicker();
  final _notesController = TextEditingController();
  final _pickupNotesController = TextEditingController();
  final _sealNumberController = TextEditingController();
  Timer? _locationTimer;
  Position? _currentPosition;
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isPickedUp = false;
  bool _isTracking = false;
  XFile? _imageFile;
  String? _imageUrl;
  String? _authtoken;
  CashCount? _cashCount;
  Request? _request;
  String? _error;

  @override
  void initState() {
    super.initState();
    _authtoken = _storage.read('token');
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        print('Checking initial state for request: ${widget.requisition.id}');
        print('Request service type: ${widget.requisition.serviceType}');
        print('Request data: ${widget.requisition.toJson()}');

        final request =
            await _requisitionsService.getRequestDetails(widget.requisition.id);

        if (!mounted) return;

        setState(() {
          _request = request;
          _isLoading = false;
          _error = null;
        });

        // Start location tracking
        _startLocationTracking();

        return;
      } catch (e) {
        print('Error in _checkInitialState (attempt ${retryCount + 1}): $e');

        if (!mounted) return;

        if (e.toString().contains('session has expired')) {
          setState(() {
            _isLoading = false;
            _error = 'Your session has expired. Please login again.';
          });
          return;
        }

        if (e.toString().contains('not authorized')) {
          setState(() {
            _isLoading = false;
            _error = 'You are not authorized to access this request.';
          });
          return;
        }

        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(Duration(seconds: 1 * retryCount));
          continue;
        }

        setState(() {
          _isLoading = false;
          _error = 'Failed to load request details. Please try again.';
        });
      }
    }
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

      // Update location every 5 minutes for UI display only
      _locationTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
        _updateLocation();
      });

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
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _currentPosition = position);
      // Location tracking to server is handled by RequisitionsService
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        if (!mounted) return;
        setState(() {
          _imageFile = image;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error taking photo: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmPickup() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Banking slip photo is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_cashCount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the cash count first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Upload the image first
      final imageUrl = await _requisitionsService.uploadImage(_imageFile!);

      if (!mounted) return;

      // Confirm pickup with image URL and cash count
      await _requisitionsService.confirmPickup(
        widget.requisition.id,
        cashCount: _cashCount,
        imageUrl: imageUrl,
        sealNumber: _sealNumberController.text,
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup confirmed successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to detail page with success indicator
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      // Show error message with retry option
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error confirming pickup: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              // Clear any existing error messages
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              // Retry confirming pickup
              _confirmPickup();
            },
          ),
        ),
      );

      // Log the error for debugging
      debugPrint('Error confirming pickup: $e');
    }
  }

  Future<void> _completeDelivery() async {
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
      final requestId = widget.requisition.id.toString();
      await _requisitionsService.confirmDelivery(
        requestId,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        notes: _notesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _navigateToCashCount() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CashCountPage(
            onConfirm: (cashCount) {
              if (!mounted) return;
              setState(() => _cashCount = cashCount);
            },
          ),
        ),
      );

      if (result != null && result is CashCount) {
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

  @override
  void dispose() {
    _locationTimer?.cancel();
    _notesController.dispose();
    _pickupNotesController.dispose();
    _sealNumberController.dispose();
    super.dispose();
  }

  Widget _buildCompactStatusCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isPickedUp ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isPickedUp ? Colors.green.shade200 : Colors.orange.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isPickedUp ? Icons.local_shipping : Icons.pending_actions,
            color: _isPickedUp ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPickedUp ? 'In Transit' : 'Pending Pickup',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _isPickedUp
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                    fontSize: 14,
                  ),
                ),
                if (_isTracking && _currentPosition != null)
                  Text(
                    'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
                    'Long: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return _buildCompactSection(
      title: 'Banking Slip Photo',
      icon: Icons.camera_alt,
      child: Column(
        children: [
          if (_imageFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(_imageFile!.path),
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Icon(
                Icons.add_a_photo,
                color: Colors.grey.shade400,
                size: 32,
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt, size: 16),
              label: Text(
                _imageFile != null ? 'Retake Photo' : 'Take Photo',
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
    );
  }

  Widget _buildCashCountSection() {
    return _buildCompactSection(
      title: 'Cash Count',
      icon: Icons.account_balance_wallet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_cashCount != null) ...[
            Text(
              'Total Amount: KES ${_cashCount!.totalAmount}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
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
    );
  }

  Widget _buildSealNumberSection() {
    return _buildCompactSection(
      title: 'Seal Number',
      icon: Icons.security,
      child: TextField(
        controller: _sealNumberController,
        decoration: InputDecoration(
          hintText: 'Enter seal number...',
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding: const EdgeInsets.all(10),
          isDense: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingSpinner.fullScreen(message: 'Loading...'),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 16),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          title: const Text(
            'BSS Bank to Bank',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: _buildCompactStatusCard(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    if (!_isPickedUp) ...[
                      _buildCashCountSection(),
                      _buildSealNumberSection(),
                      _buildPhotoSection(),
                      _buildCompactSection(
                        title: 'Pickup Notes',
                        icon: Icons.note_alt,
                        child: TextField(
                          controller: _pickupNotesController,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Enter pickup notes...',
                            hintStyle: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            contentPadding: const EdgeInsets.all(10),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : (_isPickedUp ? _completeDelivery : _confirmPickup),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: LoadingSpinner.button(),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isPickedUp
                                  ? Icons.delivery_dining
                                  : Icons.check_circle,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isPickedUp
                                  ? 'COMPLETE DELIVERY'
                                  : 'CONFIRM PICKUP',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
