import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/request.dart';
import '../../../services/requisitions_service.dart';
import 'inTransitDetail.dart';

class InProgressPage extends StatefulWidget {
  const InProgressPage({super.key});

  static int getInProgressCount() {
    return _InProgressPageState.inProgressCount;
  }

  @override
  State<InProgressPage> createState() => _InProgressPageState();
}

class _InProgressPageState extends State<InProgressPage> {
  final RequisitionsService _requisitionsService = RequisitionsService();
  List<Request> _requisitions = [];
  bool _isLoading = true;
  String? _error;
  static int inProgressCount = 0;

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

      final requests = await _requisitionsService.getInProgressRequests();

      setState(() {
        _requisitions = requests;
        inProgressCount = requests.length;
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
        title: const Text("In-Transit"),
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
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
      return const Center(child: Text('No in-transit requisitions found'));
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
            leading: const Icon(Icons.local_shipping, color: Colors.blue),
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
                  req.pickupDate != null ? DateFormat('MMM dd, yyyy hh:mm a').format(req.pickupDate!) : 'Not specified',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.red),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InTransitDetail(requisition: req),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _requisitionsService.dispose();
    super.dispose();
  }
}
