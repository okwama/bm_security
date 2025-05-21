import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyDetailsPage extends StatefulWidget {
  final Position? currentPosition;
  final String? currentAddress;

  const EmergencyDetailsPage({
    Key? key,
    this.currentPosition,
    this.currentAddress,
  }) : super(key: key);

  @override
  State<EmergencyDetailsPage> createState() => _EmergencyDetailsPageState();
}

class _EmergencyDetailsPageState extends State<EmergencyDetailsPage> {
  final List<Map<String, dynamic>> _emergencyContacts = [
    {'name': 'Police', 'number': '911', 'icon': Icons.local_police},
    {'name': 'Ambulance', 'number': '911', 'icon': Icons.local_hospital},
    {'name': 'Fire Department', 'number': '911', 'icon': Icons.fire_truck},
  ];

  Future<void> _callEmergencyContact(String number) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: number,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      _showErrorDialog('Could not launch phone dialer');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Details'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Emergency Contacts
              Card(
                margin: const EdgeInsets.only(bottom: 24),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.contacts, color: Colors.red, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Emergency Contacts',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ..._emergencyContacts.map((contact) => ListTile(
                            leading: Icon(contact['icon'], color: Colors.red),
                            title: Text(contact['name']),
                            subtitle: Text(contact['number']),
                            trailing: IconButton(
                              icon: const Icon(Icons.phone),
                              color: Colors.red,
                              onPressed: () =>
                                  _callEmergencyContact(contact['number']),
                            ),
                          )),
                    ],
                  ),
                ),
              ),

              // Emergency Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.red, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Emergency Instructions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Important Guidelines:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('1. Stay calm and assess the situation'),
                      const Text('2. Ensure your safety first'),
                      const Text(
                          '3. Provide clear information to emergency services'),
                      const Text(
                          '4. Follow instructions from emergency responders'),
                      const SizedBox(height: 24),
                      const Text(
                        'Your Location:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (widget.currentPosition != null) ...[
                        Text('Latitude: ${widget.currentPosition!.latitude}'),
                        Text('Longitude: ${widget.currentPosition!.longitude}'),
                        if (widget.currentAddress != null) ...[
                          const SizedBox(height: 8),
                          Text('Address: ${widget.currentAddress}'),
                        ],
                      ] else ...[
                        const Text('Location information not available'),
                      ],
                      const SizedBox(height: 24),
                      const Text(
                        'Additional Resources:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                          '• Download emergency preparedness checklists'),
                      const Text('• Learn basic first aid techniques'),
                      const Text('• Identify evacuation routes in your area'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
