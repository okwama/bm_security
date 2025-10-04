import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/request_entity.dart';

class ActionButtons extends StatelessWidget {
  final RequestEntity request;
  final VoidCallback onConfirmPickup;
  final bool isLoading;

  const ActionButtons({
    super.key,
    required this.request,
    required this.onConfirmPickup,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(AppConstants.primaryColorValue),
              ),
            ),
            const SizedBox(height: 16),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    // Only show confirm pickup button for pending requests
    if (request.myStatus != AppConstants.statusPending) {
      return _buildStatusMessage();
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : onConfirmPickup,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.qr_code_scanner),
            label: Text(
              isLoading ? 'Processing...' : 'Confirm Pickup',
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
        ),
        const SizedBox(height: 12),
        _buildInfoText(),
      ],
    );
  }

  Widget _buildStatusMessage() {
    String message;
    Color color;
    IconData icon;

    switch (request.myStatus) {
      case AppConstants.statusInProgress:
        message = 'This request is currently in progress';
        color = Colors.blue;
        icon = Icons.watch_later;
        break;
      case AppConstants.statusCompleted:
        message = 'This request has been completed';
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case AppConstants.statusCancelled:
        message = 'This request has been cancelled';
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        message = 'Unknown status';
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoText() {
    final isCashCountRequired = _isCashCountRequired();
    
    if (!isCashCountRequired) {
      return Text(
        'Tap "Confirm Pickup" to start the pickup process.',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      );
    }

    return Column(
      children: [
        Text(
          'Cash count will be required during pickup confirmation.',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Make sure you have access to the cash before confirming.',
          style: TextStyle(
            color: Colors.orange[600],
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  bool _isCashCountRequired() {
    // Check if cash count is required based on service type
    final serviceTypeId = request.serviceType?.id;
    
    switch (serviceTypeId) {
      case 2: // BSS
      case 3: // CDM Collection
      case 4: // ATM Loading
      case 5: // BSS Vault
        return true;
      case 1: // Pick and Drop
      default:
        return false;
    }
  }
}
