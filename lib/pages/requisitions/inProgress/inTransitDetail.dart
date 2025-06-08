import 'package:flutter/material.dart';
import 'package:bm_security/models/branch.dart';

class InTransitDetail extends StatefulWidget {
  final dynamic requisition;

  const InTransitDetail({super.key, required this.requisition});

  @override
  State<InTransitDetail> createState() => _InTransitDetailState();
}

class _InTransitDetailState extends State<InTransitDetail> {
  String sealNumber = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("In-Transit Details"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Compact Header
            _buildCompactHeader(),
            const SizedBox(height: 8),
            
            // Route & Cash in single row for larger screens
            if (MediaQuery.of(context).size.width > 600) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildRouteSection()),
                  const SizedBox(width: 8),
                  if (widget.requisition.serviceType != "Pick & Drop")
                    Expanded(child: _buildCashSection()),
                ],
              ),
            ] else ...[
              _buildRouteSection(),
              const SizedBox(height: 8),
              if (widget.requisition.serviceType != "Pick & Drop")
                _buildCashSection(),
            ],
            
            const SizedBox(height: 8),
            _buildActionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    String branchName = 'Unknown Branch';
    String branchAddress = 'No address';
    
    try {
      // Access branch data from the requisition
      final branch = widget.requisition?.branch;
      
      if (branch != null) {
        // If branch is a Map (from JSON)
        if (branch is Map) {
          branchName = branch['name']?.toString() ?? 'Unknown Branch';
          branchAddress = branch['address']?.toString() ?? 'No address';
        } 
        // If branch is a Branch object
        else if (branch is Branch) {
          branchName = branch.name;
          branchAddress = branch.address ?? 'No address';
        }
      }
      
      // Debug print to verify branch data
      print('Branch data - Name: $branchName, Address: $branchAddress');
    } catch (e, stackTrace) {
      print('Error accessing branch data: $e');
      print('Stack trace: $stackTrace');
      print('Requisition type: ${widget.requisition?.runtimeType}');
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.business, color: Colors.blue[600], size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  branchName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  branchAddress,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'IN TRANSIT',
              style: TextStyle(
                fontSize: 10,
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route, color: Colors.orange[600], size: 16),
              const SizedBox(width: 6),
              const Text('Route', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              _buildCompactRouteItem(
                Icons.my_location,
                widget.requisition.pickupLocation ?? 'Not specified',
                Colors.orange,
              ),
              _buildCompactRouteItem(
                Icons.location_on,
                widget.requisition.deliveryLocation ?? 'Not specified',
                Colors.red,
                isLast: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactRouteItem(IconData icon, String value, Color color, {bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route indicator column
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              if (!isLast) ...[
                Container(
                  width: 2,
                  height: 20,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.green[600], size: 16),
              const SizedBox(width: 6),
              const Text('Cash', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.requisition.cashCount != null) ...[
            _buildCompactCashGrid(),
            if (widget.requisition.cashCount?.sealNumber != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.security, color: Colors.blue[600], size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'Seal: ${widget.requisition.cashCount!.sealNumber}',
                    style: TextStyle(fontSize: 11, color: Colors.blue[600]),
                  ),
                ],
              ),
            ],
          ] else ...[
            Text(
              'No cash data',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactCashGrid() {
    final cashData = [

      ('1', widget.requisition.cashCount?.ones ?? 0),
      ('2', widget.requisition.cashCount?.twos ?? 0),
      ('5', widget.requisition.cashCount?.fives ?? 0),  
      ('10', widget.requisition.cashCount?.tens ?? 0),
      ('20', widget.requisition.cashCount?.twenties ?? 0),
        ('40', widget.requisition.cashCount?.forty ?? 0),
      ('50', widget.requisition.cashCount?.fifties ?? 0),
      ('100', widget.requisition.cashCount?.hundreds ?? 0),
      ('200', widget.requisition.cashCount?.twoHundreds ?? 0),
      ('500', widget.requisition.cashCount?.fiveHundreds ?? 0),
      ('1K', widget.requisition.cashCount?.thousands ?? 0),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: cashData.map((item) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${item.$1}: ${item.$2}',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      )).toList(),
    );
  }

  Widget _buildActionsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          if (widget.requisition.serviceType != "Pick & Drop") ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_camera, size: 16),
                    label: const Text('Photo', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Seal Number',
                      labelStyle: const TextStyle(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (val) => setState(() => sealNumber = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : const Icon(Icons.check_circle, size: 16),
              label: Text(
                _isLoading ? 'Processing...' : 'Complete Delivery',
                style: const TextStyle(fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: _isLoading ? null : _completeDelivery,
            ),
          ),
        ],
      ),
    );
  }

  void _completeDelivery() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}