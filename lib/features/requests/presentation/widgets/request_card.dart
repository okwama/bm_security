import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/request_entity.dart';
import '../../../../core/constants/app_constants.dart';

class RequestCard extends StatelessWidget {
  final RequestEntity request;
  final VoidCallback onTap;

  const RequestCard({
    super.key,
    required this.request,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with service type and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.serviceType?.name ?? 'Unknown Service',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _buildStatusChip(),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Pickup location
              _buildLocationRow(
                icon: Icons.location_on_outlined,
                label: 'Pickup',
                location: request.pickupLocation,
                color: Colors.blue,
              ),
              
              const SizedBox(height: 4),
              
              // Delivery location
              _buildLocationRow(
                icon: Icons.location_on,
                label: 'Delivery',
                location: request.deliveryLocation,
                color: Colors.green,
              ),
              
              const SizedBox(height: 8),
              
              // Date and time
              if (request.createdAt != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd, yyyy hh:mm a').format(request.createdAt!),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              
              // Staff info if available
              if (request.staffName != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Assigned to: ${request.staffName}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              
              // Trailing arrow
              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String text;
    
    switch (request.myStatus) {
      case AppConstants.statusPending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case AppConstants.statusInProgress:
        color = Colors.blue;
        text = 'In Progress';
        break;
      case AppConstants.statusCompleted:
        color = Colors.green;
        text = 'Completed';
        break;
      case AppConstants.statusCancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required String label,
    required String location,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '$label: $location',
            style: const TextStyle(fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
