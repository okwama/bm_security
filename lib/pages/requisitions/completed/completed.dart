import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:bm_security/models/request.dart';
import 'package:bm_security/services/requisitions/requisitions_service.dart';

class CompletedPage extends StatefulWidget {
  const CompletedPage({super.key});

  @override
  State<CompletedPage> createState() => _CompletedPageState();
}

class _CompletedPageState extends State<CompletedPage> {
  final RequisitionsService _requisitionsService = RequisitionsService();
  bool _isLoading = true;
  List<Request> _completedRequests = [];

  @override
  void initState() {
    super.initState();
    _loadCompletedRequests();
  }

  void _showCompletionDialog(Request request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Completed'),
        content: const Text('Are you sure you want to mark this requisition as completed? This will stop location tracking.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _markAsCompleted(request);
            },
            child: const Text('COMPLETE'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadCompletedRequests() async {
    try {
      // In a real app, you would fetch completed requests from your API
      // For now, we'll use an empty list
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load completed requests: $e')),
        );
      }
    }
  }
  
  // In a real app, this would be called when marking a request as completed
  Future<void> _markAsCompleted(Request request) async {
    try {
      setState(() => _isLoading = true);
      
      // Get current location if needed or use default values
      // Note: You might want to implement proper location fetching logic here
      final double? latitude = 0.0; // Replace with actual location logic
      final double? longitude = 0.0; // Replace with actual location logic
      
      // Complete the requisition with all required parameters
      await _requisitionsService.completeRequisition(
        request.id.toString(),
        photoUrl: '',
        bankDetails: null, // Since bankDetails is not available in Request model
        latitude: latitude,
        longitude: longitude,
        notes: 'Completed by user',
      );
      
      if (mounted) {
        // Refresh the list
        await _loadCompletedRequests();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Requisition marked as completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete requisition: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Requisitions'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _completedRequests.isEmpty
              ? const Center(child: Text('No completed requisitions'))
              : ListView.builder(
                  itemCount: _completedRequests.length,
                  itemBuilder: (context, index) {
                    final request = _completedRequests[index];
                    return ListTile(
                      title: Text('Requisition #${request.id}'),
                      subtitle: Text('Created on ${request.createdAt != null ? DateFormat.yMd().add_jm().format(request.createdAt!) : 'N/A'}'),
                      onTap: () {
                        // Show completion dialog
                        _showCompletionDialog(request);
                      },
                    );
                  },
                ),
    );
  }
}