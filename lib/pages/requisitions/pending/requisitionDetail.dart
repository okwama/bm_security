import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
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
import '../../../components/loading_spinner.dart';
import 'process/pickandDrop.dart';
import 'process/bssSlip.dart';
import 'process/cdmCollection.dart';
import 'process/atmCollection.dart';
import 'process/bssVault.dart';
import '../../../utils/date_formatter.dart';

class RequisitionDetail extends StatefulWidget {
  final Request request;

  const RequisitionDetail({super.key, required this.request});

  @override
  State<RequisitionDetail> createState() => _RequisitionDetailState();
}

class _RequisitionDetailState extends State<RequisitionDetail> {
  final storage = GetStorage();

  bool _isLoading = false;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    debugPrint('Request data: ${widget.request.toJson()}');
    debugPrint('serviceTypeId: ${widget.request.serviceTypeId}');
    debugPrint('serviceType: ${widget.request.serviceType}');
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _confirmPickup() async {
    debugPrint(
        'Confirming pickup - serviceTypeId: ${widget.request.serviceTypeId}, serviceType: ${widget.request.serviceType}');

    final bool? confirm = await _showConfirmationDialog();
    if (confirm != true) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      bool? result;
      switch (widget.request.serviceTypeId) {
        case 1:
          result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PickAndDrop(requisition: widget.request),
            ),
          );
          break;
        case 2:
          result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BssSlip(requisition: widget.request),
            ),
          );
          break;
        case 3:
          result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CdmCollection(requisition: widget.request),
            ),
          );
          break;
        case 4:
          result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AtmCollection(requisition: widget.request),
            ),
          );
          break;
        case 5:
          result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BssVault(requisition: widget.request),
            ),
          );
          break;
        default:
          _showError('Unknown service type');
          break;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          // Only show success if actual changes were made
          _showSuccess = result == true;
        });

        // Only show success message and navigate if actual changes were made
        if (result == true) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Pickup confirmed successfully'),
                ],
              ),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );

          // Navigate back to pending page with success indicator
          Navigator.of(context).pop(true);
        } else {
          // Just pop without success indicator if no changes were made
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(_getErrorMessage(e));
    }
  }

  Future<bool?> _showConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner,
                color: Color.fromARGB(255, 12, 90, 153)),
            SizedBox(width: 8),
            Text('Confirm Pickup'),
          ],
        ),
        content: const Text('Are you sure you want to confirm this pickup?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
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

    final errorMessage = message.contains(': ')
        ? message.split(': ').sublist(1).join(': ')
        : message;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('Error: $errorMessage')),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  Color _getStatusColor(Status status) {
    switch (status) {
      case Status.pending:
        return Colors.orange;
      case Status.inProgress:
        return Colors.blue;
      case Status.completed:
        return Colors.green;
      case Status.cancelled:
        return Colors.red;
    }
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 12, 90, 153),
            Color.fromARGB(255, 12, 90, 153)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.request.serviceType,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.request.status)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(widget.request.status)
                        .withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  widget.request.status
                      .toString()
                      .split('.')
                      .last
                      .toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(widget.request.status),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (widget.request.pickupDate != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a')
                      .format(widget.request.pickupDate!),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildLocationItem(
            icon: Icons.location_on,
            iconColor: Colors.green,
            title: 'Pickup Location',
            location: widget.request.pickupLocation ?? 'Not specified',
            isFirst: true,
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 56),
            color: Colors.grey[200],
          ),
          _buildLocationItem(
            icon: Icons.flag,
            iconColor: Colors.red,
            title: 'Delivery Location',
            location: widget.request.deliveryLocation ?? 'Not specified',
            isFirst: false,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String location,
    required bool isFirst,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashCountCard() {
    if (widget.request.cashCount == null) return const SizedBox.shrink();

    final cashCount = widget.request.cashCount!;
    final denominations = [
      {'value': 50, 'count': cashCount.fifties},
      {'value': 100, 'count': cashCount.hundreds},
      {'value': 200, 'count': cashCount.twoHundreds},
      {'value': 500, 'count': cashCount.fiveHundreds},
      {'value': 1000, 'count': cashCount.thousands},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.account_balance_wallet,
                      color: Colors.green, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Cash Count Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Denominations Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: denominations.length,
              itemBuilder: (context, index) {
                final denom = denominations[index];
                final value = denom['value'] as int;
                final count = denom['count'] as int;
                final total = value * count;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'KES $value',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$count × $value = KES $total',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Total and Seal
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'KES ${NumberFormat('#,###').format(cashCount.totalAmount)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                if (cashCount.sealNumber != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.security, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Seal: ${cashCount.sealNumber}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Cash Image
          if (widget.request.cashImageUrl != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sealed Bag Image',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.request.cashImageUrl!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text('Failed to load image'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_showSuccess)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Pickup confirmed successfully!',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (widget.request.status == Status.pending && !_isLoading)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text(
                'Confirm Pickup',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 12, 90, 153),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: _confirmPickup,
            ),
          ),
        if (_isLoading)
          Container(
            padding: const EdgeInsets.all(20),
            child: const Column(
              children: [
                LoadingSpinner.button(message: 'Processing pickup...'),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Requisition Details'),
        backgroundColor: const Color.fromARGB(255, 12, 90, 153),
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            _buildLocationCard(),
            _buildCashCountCard(),
            const SizedBox(height: 8),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }
}
