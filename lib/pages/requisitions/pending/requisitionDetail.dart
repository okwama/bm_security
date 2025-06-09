import 'package:bm_security/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../models/request.dart';
import '../../../models/cash_count.dart';
import '../../../services/requisitions/requisitions_service.dart';
import '../../../widgets/cash_count_dialog.dart';
import '../../../pages/requisitions/cashCount_page.dart';
import '../../../utils/auth_config.dart';

class RequisitionDetail extends StatefulWidget {
  final Request request;

  const RequisitionDetail({super.key, required this.request});

  @override
  State<RequisitionDetail> createState() => _RequisitionDetailState();
}

class _RequisitionDetailState extends State<RequisitionDetail> {
  final RequisitionsService _requisitionsService = RequisitionsService();
  final LocationService _locationService = LocationService();
  Timer? _locationTimer;
  final storage = GetStorage();

  bool _isLoading = false;
  bool _showSuccess = false;
  bool _trackingInitialized = false;
  final String _baseUrl = ApiConfig.baseUrl;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _authToken = storage.read('token');
    // Debug: Print request data when widget is first built
    debugPrint('Request data: ${widget.request.toJson()}');
    debugPrint('serviceTypeId: ${widget.request.serviceTypeId}');
    debugPrint('serviceType: ${widget.request.serviceType}');
  }

  @override
  void dispose() {
    // Don't stop tracking here, let it continue to in-transit
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _confirmPickup() async {
    // Debug: Print service type info when pickup is confirmed
    debugPrint(
        'Confirming pickup - serviceTypeId: ${widget.request.serviceTypeId}, serviceType: ${widget.request.serviceType}');

    // For BSS service type (ID: 2), navigate to CashCountPage
    if (widget.request.serviceTypeId == 2) {
      try {
        final cashCount = await Navigator.push<CashCount>(
          context,
          MaterialPageRoute(
            builder: (context) => CashCountPage(
              onConfirm: (cashCount) {
                Navigator.of(context).pop(cashCount);
              },
            ),
          ),
        );

        if (cashCount == null) return; // User cancelled
        if (!mounted) return;

        setState(() => _isLoading = true);

        try {
          // Upload image if exists
          if (cashCount.imagePath != null) {
            try {} catch (e) {
              debugPrint('Error uploading image: $e');
              // Continue without image if upload fails
            }
          }

          // Call API to confirm pickup with cash count details
          await _requisitionsService.confirmPickup(
            widget.request.id,
            cashCount: cashCount,
          );

          // Start location tracking if not already tracking
          if (!_locationService
              .isTrackingRequest(widget.request.id.toString())) {
            await _initializeLocationTracking();
          }

          if (mounted) {
            setState(() {
              _isLoading = false;
              _showSuccess = true;
            });
            await Future.delayed(const Duration(milliseconds: 1500));
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            _showError(_getErrorMessage(e));
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showError('Failed to open cash count form');
        }
      }
    } else {
      // Original flow for non-BSS service types
      final bool? confirm = await _showConfirmationDialog();
      if (confirm != true) return;

      if (!mounted) return;
      setState(() => _isLoading = true);

      try {
        await _requisitionsService.confirmPickup(widget.request.id);

        // Start location tracking if not already tracking
        if (!_locationService.isTrackingRequest(widget.request.id.toString())) {
          await _initializeLocationTracking();
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
            _showSuccess = true;
          });
          await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted) {
            Navigator.pop(context, true);
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showError(_getErrorMessage(e));
        }
      }
    }
  }

  Future<bool?> _showConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Pickup'),
        content: const Text('Are you sure you want to confirm this pickup?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  String _getErrorMessage(dynamic error) {
    if (error is String) {
      return error;
    } else if (error is Map<String, dynamic>) {
      return error['message'] ?? 'An error occurred';
    } else if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return 'An unexpected error occurred';
  }

  void _showError(String message) {
    if (!mounted) return;

    // Extract the actual error message if it's in the format 'statusCode: message'
    final errorMessage = message.contains(': ')
        ? message.split(': ').sublist(1).join(': ')
        : message;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $errorMessage'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _initializeLocationTracking() async {
    if (_trackingInitialized) return;

    try {
      // Initialize location service with auth token
      if (_authToken == null) {
        _authToken = storage.read('token');
        if (_authToken == null) {
          throw Exception('Authentication token not found');
        }
      }

      // Start background location tracking
      final success = await _locationService.initialize(authToken: _authToken!);
      if (!success) {
        throw Exception('Failed to initialize location tracking');
      }

      // Start tracking for this request
      await _locationService.startTracking(widget.request.id.toString());

      _trackingInitialized = true;
      debugPrint('Location tracking started for request ${widget.request.id}');
    } catch (e) {
      debugPrint('Location tracking error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location tracking error: $e')),
        );
      }
    }
  }

  Future<void> _sendInitialPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      await _sendLocationToServer(position);
    } catch (e) {
      debugPrint('Initial location error: $e');
    }
  }

  void _startPeriodicLocationUpdates() {
    debugPrint('Starting location updates...');
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        final position = await Geolocator.getLastKnownPosition() ??
            await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
            );
        await _sendLocationToServer(position);
      } catch (e) {
        debugPrint('Periodic location error: $e');
      }
    });
  }

  Future<void> _sendLocationToServer(Position position) async {
    final token = storage.read('token');
    final body = jsonEncode({
      'requestId': widget.request.id,
      'latitude': position.latitude,
      'longitude': position.longitude,
    });

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/locations'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      debugPrint("Location sent: $body");

      if (response.statusCode != 201) {
        debugPrint('Server rejected location: ${response.body}');
      }
    } catch (e) {
      debugPrint('Failed to send location: $e');
    }
  }

  Widget _buildInfoCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Service Type', widget.request.serviceType),
            if (widget.request.cashCount != null) ...[
              const Divider(),
              const Text('Cash Count Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              _buildInfoRow('50s',
                  '${widget.request.cashCount!.fifties} × 50 = KES ${widget.request.cashCount!.fifties * 50}'),
              _buildInfoRow('100s',
                  '${widget.request.cashCount!.hundreds} × 100 = KES ${widget.request.cashCount!.hundreds * 100}'),
              _buildInfoRow('200s',
                  '${widget.request.cashCount!.twoHundreds} × 200 = KES ${widget.request.cashCount!.twoHundreds * 200}'),
              _buildInfoRow('500s',
                  '${widget.request.cashCount!.fiveHundreds} × 500 = KES ${widget.request.cashCount!.fiveHundreds * 500}'),
              _buildInfoRow('1000s',
                  '${widget.request.cashCount!.thousands} × 1000 = KES ${widget.request.cashCount!.thousands * 1000}'),
              const Divider(),
              _buildInfoRow(
                  'Total Amount', 'KES ${widget.request.cashCount!.total}'),
              if (widget.request.cashCount!.sealNumber != null)
                _buildInfoRow(
                    'Seal Number', widget.request.cashCount!.sealNumber!),
              if (widget.request.cashImageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sealed Bag Image:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Image.network(
                        widget.request.cashImageUrl!,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Text('Failed to load image'),
                      ),
                    ],
                  ),
                ),
              const Divider(),
            ],
            _buildInfoRow('Pickup Location',
                widget.request.pickupLocation ?? 'Not specified'),
            _buildInfoRow('Delivery Location',
                widget.request.deliveryLocation ?? 'Not specified'),
            if (widget.request.pickupDate != null)
              _buildInfoRow(
                'Pickup Date',
                DateFormat('MMM dd, yyyy hh:mm a')
                    .format(widget.request.pickupDate!),
              ),
            _buildInfoRow(
              'Status',
              widget.request.status.toString().split('.').last,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  // Widget _buildActionButtons() {
  //   return Column(
  //     children: [
  //       if (widget.request.status == Status.pending)
  //         ElevatedButton.icon(
  //           icon: const Icon(Icons.qr_code_scanner),
  //           label: const Text("Confirm Pickup"),
  //           style: ElevatedButton.styleFrom(
  //             minimumSize: const Size.fromHeight(50),
  //           ),
  //           onPressed: _isLoading ? null : _confirmPickup,
  //         ),
  //       if (_isLoading)
  //         const Padding(
  //           padding: EdgeInsets.all(16.0),
  //           child: CircularProgressIndicator(),
  //         ),
  //       if (_showSuccess)
  //         Container(
  //           margin: const EdgeInsets.only(top: 16),
  //           padding: const EdgeInsets.all(16.0),
  //           decoration: BoxDecoration(
  //             color: Colors.green.withOpacity(0.1),
  //             borderRadius: BorderRadius.circular(8),
  //           ),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               Icon(Icons.check_circle, color: Colors.green[700]),
  //               const SizedBox(width: 8),
  //               const Text(
  //                 'Pickup confirmed',
  //                 style: TextStyle(fontWeight: FontWeight.bold),
  //               ),
  //             ],
  //           ),
  //         ),
  //     ],
  //   );
  // }
// Replace your _buildActionButtons method with this temporarily:

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Show success message at the top for better visibility
        if (_showSuccess)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Pickup confirmed successfully!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

        if (widget.request.status == Status.pending)
          ElevatedButton.icon(
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text("Confirm Pickup"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: _isLoading ? null : _confirmPickup,
          ),

        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text('Processing pickup...'),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.request.serviceType),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoCard(),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }
}
