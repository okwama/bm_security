import 'package:bm_security/models/cash_count.dart';
import 'package:flutter/material.dart';

class CashCountPage extends StatefulWidget {
  final Function(CashCount) onConfirm;

  const CashCountPage({super.key, required this.onConfirm});

  @override
  _CashCountPageState createState() => _CashCountPageState();
}

class _CashCountPageState extends State<CashCountPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Denomination data structure in reverse order (highest to lowest)
  final Map<String, DenominationData> _denominations = {
    '1000': DenominationData(
        label: '1000s', value: 1000, controller: TextEditingController()),
    '500': DenominationData(
        label: '500s', value: 500, controller: TextEditingController()),
    '200': DenominationData(
        label: '200s', value: 200, controller: TextEditingController()),
    '100': DenominationData(
        label: '100s', value: 100, controller: TextEditingController()),
    '50': DenominationData(
        label: '50s', value: 50, controller: TextEditingController()),
    '40': DenominationData(
        label: '40s', value: 40, controller: TextEditingController()),
    '20': DenominationData(
        label: '20s', value: 20, controller: TextEditingController()),
    '10': DenominationData(
        label: '10s', value: 10, controller: TextEditingController()),
    '5': DenominationData(
        label: '5s', value: 5, controller: TextEditingController()),
    '1': DenominationData(
        label: '1s', value: 1, controller: TextEditingController()),
  };

  // Fixed total calculation
  int get total {
    return _denominations.values.fold(0, (sum, denomination) {
      String text = denomination.controller.text.trim();
      int count = (text.isEmpty) ? 0 : (int.tryParse(text) ?? 0);
      return sum + (count * denomination.value);
    });
  }

  int _getControllerValue(String key) {
    String text = _denominations[key]!.controller.text.trim();
    return (text.isEmpty) ? 0 : (int.tryParse(text) ?? 0);
  }

  @override
  void dispose() {
    for (var denomination in _denominations.values) {
      denomination.controller.dispose();
    }
    super.dispose();
  }

  Widget _buildCompactTotalHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'KES ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (total > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_denominations.values.where((d) => d.controller.text.isNotEmpty).length}/10',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactDenominationGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: _denominations.length,
      itemBuilder: (context, index) {
        String key = _denominations.keys.elementAt(index);
        DenominationData denomination = _denominations[key]!;
        bool hasValue = denomination.controller.text.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            color: hasValue ? Colors.green.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasValue ? Colors.green.shade200 : Colors.grey.shade300,
              width: hasValue ? 1.5 : 1,
            ),
            boxShadow: hasValue
                ? [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Denomination label
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        hasValue ? Colors.green.shade100 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'KES ${denomination.value}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: hasValue
                          ? Colors.green.shade800
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
                // Input field
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: TextFormField(
                      controller: denomination.controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: hasValue
                            ? Colors.green.shade800
                            : Colors.grey.shade700,
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 6),
                        isDense: true,
                        hintText: '0',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        denomination.controller.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: denomination.controller.text.length,
                        );
                      },
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        if (int.tryParse(value) == null) return '';
                        return null;
                      },
                    ),
                  ),
                ),
                // Subtotal
                Text(
                  'KES ${(() {
                    String text = denomination.controller.text.trim();
                    int count = (text.isEmpty) ? 0 : (int.tryParse(text) ?? 0);
                    return (count * denomination.value).toStringAsFixed(0);
                  })()}',
                  style: TextStyle(
                    fontSize: 9,
                    color:
                        hasValue ? Colors.green.shade600 : Colors.grey.shade500,
                    fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Cash Count',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 16),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Compact total header
            _buildCompactTotalHeader(),
            // Content area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section header
                    Row(
                      children: [
                        Icon(
                          Icons.calculate,
                          size: 18,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Count by Denomination',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Denomination grid
                    _buildCompactDenominationGrid(),
                  ],
                ),
              ),
            ),
            // Bottom button
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting || total <= 0 ? null : _onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: total > 0 ? 2 : 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSubmitting)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        Icon(
                          total > 0 ? Icons.check_circle : Icons.calculate,
                          size: 18,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _isSubmitting
                            ? 'SAVING...'
                            : (total > 0
                                ? 'CONFIRM CASH COUNT'
                                : 'ENTER DENOMINATIONS'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onConfirm() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (!mounted) return;
      setState(() => _isSubmitting = true);

      try {
        final cashCount = CashCount(
          ones: _getControllerValue('1'),
          fives: _getControllerValue('5'),
          tens: _getControllerValue('10'),
          twenties: _getControllerValue('20'),
          forties: _getControllerValue('40'),
          fifties: _getControllerValue('50'),
          hundreds: _getControllerValue('100'),
          twoHundreds: _getControllerValue('200'),
          fiveHundreds: _getControllerValue('500'),
          thousands: _getControllerValue('1000'),
        );

        // Call the onConfirm callback with the cash count data
        widget.onConfirm(cashCount);

        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cash count saved successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );

        // Navigate back to parent page with the cash count data
        Navigator.of(context).pop(cashCount);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving cash count: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }
}

// Helper class for denomination data
class DenominationData {
  final String label;
  final int value;
  final TextEditingController controller;

  DenominationData({
    required this.label,
    required this.value,
    required this.controller,
  });
}

