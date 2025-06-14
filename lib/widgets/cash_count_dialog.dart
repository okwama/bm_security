import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/cash_count.dart';

class CashCountDialog extends StatefulWidget {
  final Function(CashCount) onConfirm;

  const CashCountDialog({super.key, required this.onConfirm});

  @override
  _CashCountDialogState createState() => _CashCountDialogState();
}

class _CashCountDialogState extends State<CashCountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _sealNumberController = TextEditingController();

  // Denomination data structure for better organization
  final Map<String, DenominationData> _denominations = {
    '1': DenominationData(label: '1s', value: 1, controller: TextEditingController()),
    '5': DenominationData(label: '5s', value: 5, controller: TextEditingController()),
    '10': DenominationData(label: '10s', value: 10, controller: TextEditingController()),
    '20': DenominationData(label: '20s', value: 20, controller: TextEditingController()),
    '50': DenominationData(label: '50s', value: 50, controller: TextEditingController()),
    '100': DenominationData(label: '100s', value: 100, controller: TextEditingController()),
    '200': DenominationData(label: '200s', value: 200, controller: TextEditingController()),
    '500': DenominationData(label: '500s', value: 500, controller: TextEditingController()),
    '1000': DenominationData(label: '1000s', value: 1000, controller: TextEditingController()),
  };

  File? _image;
  final picker = ImagePicker();

  // Fixed total calculation
  int get total {
    return _denominations.values.fold(0, (sum, denomination) {
      // Handle empty strings as 0
      String text = denomination.controller.text.trim();
      int count = (text.isEmpty) ? 0 : (int.tryParse(text) ?? 0);
      return sum + (count * denomination.value);
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
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
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.money, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Cash Count & Bag Sealing',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total display at top
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9 * 0.9, // 90% of dialog width
                        child: Card(
                          color: Colors.green.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Total Amount',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: double.infinity,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'KES ${total.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Denomination inputs in grid
                      const Text(
                        'Count by Denomination:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDenominationGrid(),
                      const SizedBox(height: 20),
                      
                      // Seal number
                      const Text(
                        'Seal Information:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _sealNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Seal Number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.security),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter seal number' : null,
                      ),
                      const SizedBox(height: 20),
                      
                      // Photo section
                      const Text(
                        'Photo Verification:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPhotoSection(),
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _onConfirm,
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm Count'),
                  ),
                ],
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
        childAspectRatio: 1.0, // Made it square for more height
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _denominations.length,
      itemBuilder: (context, index) {
        String key = _denominations.keys.elementAt(index);
        DenominationData denomination = _denominations[key]!;
        
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(4), // Reduced padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Better distribution
              mainAxisSize: MainAxisSize.min, // Only use needed space
              children: [
                Flexible(
                  child: Text(
                    'KES ${denomination.value}',
                    style: const TextStyle(
                      fontSize: 11,
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
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
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
                      int count = (text.isEmpty) ? 0 : (int.tryParse(text) ?? 0);
                      return (count * denomination.value).toStringAsFixed(0);
                    })()}',
                    style: TextStyle(
                      fontSize: 9,
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

  Widget _buildPhotoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_image == null) ...[
              Icon(
                Icons.camera_alt,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              const Text(
                'Photo of sealed bag required',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
              ),
            ] else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _image!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retake'),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _image = null),
                    icon: const Icon(Icons.delete),
                    label: const Text('Remove'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _getControllerValue(String key) {
    String text = _denominations[key]!.controller.text.trim();
    return (text.isEmpty) ? 0 : (int.tryParse(text) ?? 0);
  }

  void _onConfirm() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please take a photo of the sealed bag'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      widget.onConfirm(
        CashCount(
          ones: _getControllerValue('1'),
          fives: _getControllerValue('5'),
          tens: _getControllerValue('10'),
          twenties: _getControllerValue('20'),
          fifties: _getControllerValue('50'),
          hundreds: _getControllerValue('100'),
          twoHundreds: _getControllerValue('200'),
          fiveHundreds: _getControllerValue('500'),
          thousands: _getControllerValue('1000'),
          sealNumber: _sealNumberController.text,
          imageUrl: _image?.path,
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