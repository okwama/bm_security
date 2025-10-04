import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/request_entity.dart';

class CashCountCard extends StatelessWidget {
  final RequestEntity request;

  const CashCountCard({
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
                  Icons.account_balance_wallet,
                  color: const Color(AppConstants.primaryColorValue),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Cash Count',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConstants.primaryColorValue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCashCountStatus(),
            const SizedBox(height: 12),
            _buildCashCountInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildCashCountStatus() {
    // Check if cash count is required for this service type
    final isCashCountRequired = _isCashCountRequired();
    
    if (!isCashCountRequired) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.grey[600],
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cash count not required for this service type',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Check if cash count is completed
    final hasCashCount = request.cashCounts?.isNotEmpty ?? false;
    
    if (hasCashCount) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green[300]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green[600],
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cash count completed',
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Cash count required but not completed
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber,
            color: Colors.orange[600],
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Cash count required before pickup',
              style: TextStyle(
                color: Colors.orange[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashCountInfo() {
    final isCashCountRequired = _isCashCountRequired();
    
    if (!isCashCountRequired) {
      return const SizedBox.shrink();
    }

    final hasCashCount = request.cashCounts?.isNotEmpty ?? false;
    
    if (!hasCashCount) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cash count will be required when you confirm pickup.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You will need to count and enter:',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          _buildDenominationList(),
        ],
      );
    }

    // Show completed cash count details
    final cashCount = request.cashCounts!.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cash count completed:',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _buildCompletedCashCount(cashCount),
      ],
    );
  }

  Widget _buildDenominationList() {
    final denominations = [
      '1,000 shillings',
      '500 shillings',
      '200 shillings',
      '100 shillings',
      '50 shillings',
      '20 shillings',
      '10 shillings',
      '5 shillings',
      '1 shilling',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: denominations.map((denom) => Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 2),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              denom,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildCompletedCashCount(dynamic cashCount) {
    // This would show the actual cash count data
    // For now, showing a placeholder
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Text(
        'Total: ${cashCount.totalAmount ?? 'N/A'} KES',
        style: TextStyle(
          color: Colors.green[700],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  bool _isCashCountRequired() {
    // Check if cash count is required based on service type
    final serviceTypeId = request.serviceType?.id;
    
    switch (serviceTypeId) {
      case 2: // BSS
      case 3: // CDM Collection
      case 4: // ATM Loading
      case 5: // BSS Vault
        return true;
      case 1: // Pick and Drop
      default:
        return false;
    }
  }
}
