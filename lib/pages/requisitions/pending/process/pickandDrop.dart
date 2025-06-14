import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';
import 'package:bm_security/services/requisitions/requisitions_service.dart';
import 'package:bm_security/widgets/error_dialog.dart' show showErrorDialog;
import 'package:bm_security/services/location_service.dart';
import 'dart:async';
import '../../../../components/loading_spinner.dart';

class PickAndDrop extends StatefulWidget {
  final dynamic requisition;

  const PickAndDrop({super.key, required this.requisition});

  @override
  State<PickAndDrop> createState() => _PickAndDropState();
}

class _PickAndDropState extends State<PickAndDrop> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoading = false;
  Position? _currentPosition;
  bool _isPickedUp = false;
  bool _isTracking = false;
  int _retryCount = 0;
  static const int maxRetries = 3;

  final RequisitionsService _requisitionsService = RequisitionsService();
  final GetStorage _storage = GetStorage();

  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _isPickedUp = widget.requisition.status == 'in_progress';
    if (_isPickedUp) {
      _startLocationTracking();
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    if (_isTracking) return;

    setState(() => _isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      setState(() => _isTracking = true);

      // Update location every 5 minutes for UI display only
      _locationTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
        _updateLocation();
      });

      // Get initial position
      await _updateLocation();
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context,
          'Location Error',
          'Failed to start location tracking: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _currentPosition = position);
      // Location tracking to server is handled by RequisitionsService
    } catch (e) {
      debugPrint(
          'Silent error updating location: $e, stack trace: ${e.toString()}');
      debugPrint('stack trace: ${StackTrace.current}');
      debugPrint('user_id: ${_storage.read('user_id')}');
      debugPrint('user_name: ${_storage.read('user_name')}');
    }
  }

  Future<void> _confirmPickup() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _retryCount = 0;
    });

    while (_retryCount < maxRetries) {
      try {
        // Debug logging
        debugPrint('Current request status: ${widget.requisition.status}');
        debugPrint('Current request myStatus: ${widget.requisition.myStatus}');
        debugPrint('Current request data: ${widget.requisition.toJson()}');

        // Ensure requestId is properly converted to int
        final requestId = int.tryParse(widget.requisition.id.toString());
        if (requestId == null) {
          throw Exception('Invalid request ID format');
        }

        await _requisitionsService.confirmPickup(
          requestId,
          sealNumber: '',
        );

        setState(() => _isPickedUp = true);
        await _startLocationTracking();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pickup confirmed successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to home screen and clear the navigation stack
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/home', // Make sure this matches your home route name
            (route) => false, // This removes all previous routes
          );
        }
        break; // Success, exit retry loop
      } catch (e) {
        _retryCount++;
        if (_retryCount >= maxRetries) {
          debugPrint(
              'Silent error: Failed to confirm pickup after $maxRetries attempts: $e');
          break;
        } else {
          // Wait before retrying
          await Future.delayed(Duration(seconds: _retryCount * 2));
          continue;
        }
      }
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _completeDelivery() async {
    if (_formKey.currentState?.validate() != true || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _retryCount = 0;
    });

    while (_retryCount < maxRetries) {
      try {
        final userId = _storage.read('user_id');
        final userName = _storage.read('user_name');

        if (userId == null || userName == null) {
          throw Exception('User information not found');
        }

        final requestId = widget.requisition.id.toString();

        if (_currentPosition == null) {
          throw Exception('Current location not available');
        }

        await _requisitionsService.confirmDelivery(
          requestId,
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          notes: _notesController.text.trim(),
        );

        if (mounted) {
          Navigator.of(context).pop(true);
        }
        break; // Success, exit retry loop
      } catch (e) {
        _retryCount++;
        if (_retryCount >= maxRetries) {
          debugPrint(
              'Silent error: Failed to complete delivery after $maxRetries attempts: $e');
          break;
        } else {
          // Wait before retrying
          await Future.delayed(Duration(seconds: _retryCount * 2));
          continue;
        }
      }
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: const Text(
          'Pick and Drop Delivery',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildNotesField(),
                  const SizedBox(height: 24),
                  _buildActionButton(),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: LoadingSpinner(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isPickedUp ? Icons.local_shipping : Icons.pending_actions,
                color: _isPickedUp ? Colors.green : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isPickedUp ? 'In Transit' : 'Pending Pickup',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _isPickedUp ? Colors.green : Colors.orange,
                      ),
                ),
              ),
            ],
          ),
          if (_isPickedUp) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.grey.shade600,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tracking active',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Debug button to test location updates
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  final requestId = widget.requisition.id.toString();
                  debugPrint(
                      '🧪 Testing location update for request: $requestId');
                  await LocationService().testLocationUpdate(requestId);
                },
                icon: const Icon(Icons.bug_report, size: 16),
                label: const Text('Test Location Update',
                    style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comments',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add any comments about the delivery...',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting || _isLoading
            ? null
            : (_isPickedUp ? _completeDelivery : _confirmPickup),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSubmitting || _isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: LoadingSpinner.button(),
              )
            else ...[
              Icon(_isPickedUp ? Icons.check_circle : Icons.local_shipping,
                  size: 20),
              const SizedBox(width: 8),
              Text(
                _isPickedUp ? 'COMPLETE DELIVERY' : 'CONFIRM PICKUP',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
