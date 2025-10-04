import 'package:flutter/material.dart';

class LocationStatusCard extends StatelessWidget {
  final VoidCallback onEnableLocation;

  const LocationStatusCard({
    super.key,
    required this.onEnableLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off, color: Colors.orange),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Location access is required for SOS functionality',
              style: TextStyle(color: Colors.orange),
            ),
          ),
          TextButton(
            onPressed: onEnableLocation,
            child: const Text('Enable Location'),
          ),
        ],
      ),
    );
  }
}
