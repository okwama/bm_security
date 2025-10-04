import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/request_entity.dart';

class RequestHeader extends StatelessWidget {
  final RequestEntity request;

  const RequestHeader({
    super.key,
    required this.request,
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request.myStatus),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(request.myStatus),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'ID: ${request.id}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              request.serviceType?.name ?? 'Unknown Service',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(AppConstants.primaryColorValue),
              ),
            ),
            const SizedBox(height: 8),
            if (request.pickupLocation != null) ...[
              _buildInfoRow(
                Icons.location_on,
                'Pickup Location',
                request.pickupLocation!,
              ),
              const SizedBox(height: 8),
            ],
            if (request.deliveryLocation != null) ...[
              _buildInfoRow(
                Icons.location_on,
                'Delivery Location',
                request.deliveryLocation!,
              ),
              const SizedBox(height: 8),
            ],
            if (request.createdAt != null) ...[
              _buildInfoRow(
                Icons.access_time,
                'Created',
                DateFormat('MMM dd, yyyy - HH:mm').format(request.createdAt!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case AppConstants.statusPending:
        return Colors.orange;
      case AppConstants.statusInProgress:
        return Colors.blue;
      case AppConstants.statusCompleted:
        return Colors.green;
      case AppConstants.statusCancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case AppConstants.statusPending:
        return 'PENDING';
      case AppConstants.statusInProgress:
        return 'IN PROGRESS';
      case AppConstants.statusCompleted:
        return 'COMPLETED';
      case AppConstants.statusCancelled:
        return 'CANCELLED';
      default:
        return 'UNKNOWN';
    }
  }
}
