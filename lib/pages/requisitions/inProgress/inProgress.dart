import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/request.dart';
import '../../../services/requisitions/requisitions_service.dart';
import 'inTransitDetail.dart';

import '../../../components/loading_spinner.dart';

class InProgressPage extends StatefulWidget {
  const InProgressPage({super.key});
  static int getInProgressCount() => _InProgressPageState.inProgressCount;
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
      setState(() => _isLoading = true);
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
        title: const Text("In-Transit", style: TextStyle(fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _fetchRequisitions)
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRequisitions,
        child: _isLoading
            ? const LoadingSpinner.fullScreen(
                message: 'Loading in-transit requisitions...')
            : _error != null
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('Error: $_error',
                        style:
                            const TextStyle(color: Colors.red, fontSize: 12)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                        onPressed: _fetchRequisitions,
                        child: const Text('Retry',
                            style: TextStyle(fontSize: 12))),
                  ]))
                : _requisitions.isEmpty
                    ? const Center(
                        child: Text('No in-transit requisitions',
                            style: TextStyle(fontSize: 12)))
                    : ListView.builder(
                        itemCount: _requisitions.length,
                        itemBuilder: (context, index) =>
                            _buildRequisitionCard(_requisitions[index]),
                      ),
      ),
    );
  }

  Widget _buildRequisitionCard(Request req) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InTransitDetail(requisition: req),
            ),
          );

          // If delivery was completed, refresh the list
          if (result == true) {
            _fetchRequisitions();
          }
        },
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              // First row: Branch, Service Type, and Status
              Row(children: [
                _buildInfoColumn('BRANCH', req.branch?.name ?? 'N/A',
                    fontSize: 11),
                const VerticalDivider(width: 12, thickness: 1),
                _buildInfoColumn('SERVICE TYPE', req.serviceType,
                    color: Colors.blue, fontSize: 11),
                const Spacer(),
                _buildStatusIndicator(),
                const Icon(Icons.arrow_forward_ios,
                    size: 12, color: Colors.grey),
              ]),
              const SizedBox(height: 6),
              // Second row: Pickup, Delivery, and Date
              Row(children: [
                _buildInfoColumn('PICKUP', req.pickupLocation ?? 'N/A',
                    fontSize: 10, maxLines: 1),
                const VerticalDivider(width: 12, thickness: 1),
                _buildInfoColumn('DELIVERY', req.deliveryLocation ?? 'N/A',
                    fontSize: 10, maxLines: 1),
                const Spacer(),
                _buildInfoColumn(
                    'DATE',
                    req.pickupDate != null
                        ? DateFormat('MMM dd').format(req.pickupDate!)
                        : '-',
                    fontSize: 10),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[300]!, width: 0.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
                color: Colors.orange[600], shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('IN TRANSIT',
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800])),
      ]),
    );
  }

  Widget _buildInfoColumn(String label, String value,
      {Color? color, double fontSize = 12, int maxLines = 2}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: fontSize - 2,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color ?? Colors.black87),
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _requisitionsService.dispose();
    super.dispose();
  }
}
