import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../models/request.dart';
import '../../../../models/cash_count.dart';
import '../../../../services/requisitions/requisitions_service.dart';
import '../../../../services/location_service.dart';
import '../../../../components/loading_spinner.dart';
import '../../cashCount_page.dart';

class BssVault extends StatefulWidget {
  final Request requisition;

  const BssVault({super.key, required this.requisition});

  @override
  State<BssVault> createState() => _BssVaultState();
}

class _BssVaultState extends State<BssVault> {
  final RequisitionsService _requisitionsService = RequisitionsService();
  final LocationService _locationService = LocationService();
  final _storage = GetStorage();
  final _notesController = TextEditingController();
  final _pickupNotesController = TextEditingController();
  final _sealNumberController = TextEditingController();
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isPickedUp = false;
  bool _isTracking = false;
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
        final request =
            await _requisitionsService.getRequestDetails(widget.requisition.id);

        if (!mounted) return;

        setState(() {
          _request = request;
          _isPickedUp =
              request.myStatus == 2 || request.status == Status.inProgress;
          _isLoading = false;
          _error = null;
        });

        // Start background location tracking
        await _startLocationTracking();

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
      // Initialize location service with auto backup
      final initialized = await _locationService.initializeWithAutoBackup();
      if (!initialized) {
        debugPrint('Failed to initialize location service');
        return;
      }

      // Start tracking for this request
      final success = await _locationService.startTracking(
        widget.requisition.id.toString(),
        myStatus: widget.requisition.myStatus,
      );

      if (!mounted) return;
      setState(() => _isTracking = success);

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start location tracking'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
      if (!mounted) return;
      setState(() => _isTracking = false);
    }
  }

  Future<void> _confirmPickup() async {
    if (_cashCount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the cash count first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_sealNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seal number is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Confirm pickup with cash count and seal number
      await _requisitionsService.confirmPickup(
        widget.requisition.id,
        cashCount: _cashCount,
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
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              _confirmPickup();
            },
          ),
        ),
      );

      debugPrint('Error confirming pickup: $e');
    }
  }

  Future<void> _completeDelivery() async {
    setState(() => _isSubmitting = true);

    try {
      final requestId = widget.requisition.id.toString();

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _requisitionsService.confirmDelivery(
        requestId,
        notes: _notesController.text,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // Stop location tracking after successful delivery
      await _locationService.stopTrackingForRequest(requestId);

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
                if (_isTracking)
                  Text(
                    'Location tracking active',
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
            'BSS Vault',
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
                    ] else ...[
                      _buildCompactSection(
                        title: 'Delivery Notes',
                        icon: Icons.note_alt,
                        child: TextField(
                          controller: _notesController,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Enter delivery notes...',
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
