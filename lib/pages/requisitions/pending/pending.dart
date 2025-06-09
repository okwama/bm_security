import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/request.dart';
import '../../../services/requisitions/requisitions_service.dart';
import 'requisitionDetail.dart';

class PendingRequisitionsPage extends StatefulWidget {
  const PendingRequisitionsPage({super.key});

  static int getPendingCount() {
    return _PendingRequisitionsPageState.pendingCount;
  }

  @override
  State<PendingRequisitionsPage> createState() =>
      _PendingRequisitionsPageState();
}

class _PendingRequisitionsPageState extends State<PendingRequisitionsPage> {
  final RequisitionsService _requisitionsService = RequisitionsService();
  List<Request> _requisitions = [];
  bool _isLoading = true;
  String? _error;
  static int pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchRequisitions();
  }

  Future<void> _fetchRequisitions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final requests = await _requisitionsService.getMyAssignedRequests();

      setState(() {
        _requisitions = requests;
        pendingCount = requests.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Requisitions'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRequisitions,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRequisitions,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchRequisitions,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_requisitions.isEmpty) {
      return const Center(
        child: Text('No pending requisitions found'),
      );
    }

    return ListView.builder(
      itemCount: _requisitions.length,
      itemBuilder: (context, index) {
        final req = _requisitions[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            title: Text(
              req.serviceType,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Pickup: ${req.pickupLocation}',
                    style: const TextStyle(fontSize: 13)),
                Text('Delivery: ${req.deliveryLocation}',
                    style: const TextStyle(fontSize: 13)),
                Text(
                  req.pickupDate != null
                      ? DateFormat('MMM dd, yyyy hh:mm a').format(req.pickupDate!)
                      : 'Not specified',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.red),
            onTap: () async {
              await _navigateToDetail(req);
            },
          ),
        );
      },
    );
  }

  Widget _getPriorityIcon(Priority priority) {
    switch (priority) {
      case Priority.high:
        return const Icon(Icons.assignment_outlined, color: Colors.red);
      case Priority.medium:
        return const Icon(Icons.assignment_outlined, color: Colors.orange);
      case Priority.low:
        return const Icon(Icons.assignment_outlined, color: Colors.green);
    }
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
  }

  Future<void> _navigateToDetail(Request request) async {
    final shouldRefresh = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RequisitionDetail(request: request),
      ),
    );
    
    // If we got back true, it means the pickup was confirmed
    if (shouldRefresh == true && mounted) {
      await _fetchRequisitions();
      
      // Show success dialog
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                SizedBox(height: 16),
                Text(
                  'Pickup Confirmed',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK', style: TextStyle(color: Colors.green)),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _requisitionsService.dispose();
    super.dispose();
  }
}
