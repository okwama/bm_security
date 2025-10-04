import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/request_entity.dart';

class LocationCard extends StatelessWidget {
  final RequestEntity request;

  const LocationCard({
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
                Icon(
                  Icons.location_on,
                  color: const Color(AppConstants.primaryColorValue),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Location Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConstants.primaryColorValue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (request.pickupLocation != null) ...[
              _buildLocationRow(
                'Pickup Location',
                request.pickupLocation!,
                request.latitude,
                request.longitude,
                context,
              ),
              const SizedBox(height: 12),
            ],
            if (request.deliveryLocation != null) ...[
              _buildLocationRow(
                'Delivery Location',
                request.deliveryLocation!,
                null, // Delivery location coordinates would be separate
                null,
                context,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(
    String label,
    String address,
    double? latitude,
    double? longitude,
    BuildContext context,
  ) {
    return Column(
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
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                address,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (latitude != null && longitude != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _openMaps(latitude, longitude, address),
                icon: const Icon(
                  Icons.directions,
                  color: Color(AppConstants.primaryColorValue),
                ),
                tooltip: 'Open in Maps',
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _openMaps(double latitude, double longitude, String address) async {
    try {
      // Try Google Maps first
      final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(Uri.parse(googleMapsUrl));
        return;
      }

      // Fallback to Apple Maps
      final appleMapsUrl = 'https://maps.apple.com/?q=$latitude,$longitude';
      if (await canLaunchUrl(Uri.parse(appleMapsUrl))) {
        await launchUrl(Uri.parse(appleMapsUrl));
        return;
      }

      // Fallback to generic maps URL
      final genericMapsUrl = 'geo:$latitude,$longitude?q=$latitude,$longitude(${Uri.encodeComponent(address)})';
      if (await canLaunchUrl(Uri.parse(genericMapsUrl))) {
        await launchUrl(Uri.parse(genericMapsUrl));
      }
    } catch (e) {
    }
  }
}
