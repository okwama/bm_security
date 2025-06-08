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
  final _sealNumberController = TextEditingController();

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
      // Handle empty strings as 0
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
    _sealNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Count & Bag Sealing'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Total display at top - sticky
            Container(
              width: double.infinity,
              color: Colors.green.shade50,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'KES ${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Seal number field moved here
                  TextFormField(
                    controller: _sealNumberController,
                    decoration: InputDecoration(
                      labelText: 'Seal Number',
                      labelStyle: const TextStyle(fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      prefixIcon: const Icon(Icons.security, size: 20),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 14),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ],
              ),
            ),
            // Divider between sections
            const Divider(height: 1, thickness: 1),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Denomination inputs
                    const Text(
                      'Count by Denomination',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDenominationGrid(),
                    const SizedBox(height: 32),
                    // Confirm button section
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _onConfirm,
                        icon: const Icon(Icons.check_circle, size: 24),
                        label: const Text(
                          'CONFIRM CASH COUNT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDenominationGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2, // Slightly taller for better touch targets
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: 100, // Fixed height for each item
      ),
      itemCount: _denominations.length,
      itemBuilder: (context, index) {
        String key = _denominations.keys.elementAt(index);
        DenominationData denomination = _denominations[key]!;

        return Card(
          elevation: 0.5,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    'KES ${denomination.value}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Flexible(
                  flex: 2,
                  child: TextFormField(
                    controller: denomination.controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                      isDense: true,
                      hintText: '0',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                    ),
                    onTap: () {
                      // Select all text when tapped
                      denomination.controller.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: denomination.controller.text.length,
                      );
                    },
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      // Allow empty values and treat them as 0
                      if (value == null || value.isEmpty) return null;
                      if (int.tryParse(value) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                Flexible(
                  child: Text(
                    'KES ${(() {
                      String text = denomination.controller.text.trim();
                      int count =
                          (text.isEmpty) ? 0 : (int.tryParse(text) ?? 0);
                      return (count * denomination.value).toStringAsFixed(0);
                    })()}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onConfirm() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onConfirm(
        CashCount(
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
          sealNumber: _sealNumberController.text,
        ),
      );
      Navigator.pop(context);
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