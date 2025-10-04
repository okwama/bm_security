import 'package:flutter/material.dart';
import '../bloc/cash_count_bloc.dart';

class DenominationGrid extends StatelessWidget {
  final CashCountDenominations denominations;
  final Function(String denomination, int value) onDenominationChanged;

  const DenominationGrid({
    super.key,
    required this.denominations,
    required this.onDenominationChanged,
  });

  final List<Map<String, dynamic>> _denominationData = const [
    {'key': 'thousands', 'value': 1000, 'label': '1000s'},
    {'key': 'fiveHundreds', 'value': 500, 'label': '500s'},
    {'key': 'twoHundreds', 'value': 200, 'label': '200s'},
    {'key': 'hundreds', 'value': 100, 'label': '100s'},
    {'key': 'fifties', 'value': 50, 'label': '50s'},
    {'key': 'forties', 'value': 40, 'label': '40s'},
    {'key': 'twenties', 'value': 20, 'label': '20s'},
    {'key': 'tens', 'value': 10, 'label': '10s'},
    {'key': 'fives', 'value': 5, 'label': '5s'},
    {'key': 'ones', 'value': 1, 'label': '1s'},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: _denominationData.length,
      itemBuilder: (context, index) {
        final data = _denominationData[index];
        final key = data['key'] as String;
        final value = data['value'] as int;
        final label = data['label'] as String;
        
        int currentValue = 0;
        switch (key) {
          case 'ones':
            currentValue = denominations.ones;
            break;
          case 'fives':
            currentValue = denominations.fives;
            break;
          case 'tens':
            currentValue = denominations.tens;
            break;
          case 'twenties':
            currentValue = denominations.twenties;
            break;
          case 'forties':
            currentValue = denominations.forties;
            break;
          case 'fifties':
            currentValue = denominations.fifties;
            break;
          case 'hundreds':
            currentValue = denominations.hundreds;
            break;
          case 'twoHundreds':
            currentValue = denominations.twoHundreds;
            break;
          case 'fiveHundreds':
            currentValue = denominations.fiveHundreds;
            break;
          case 'thousands':
            currentValue = denominations.thousands;
            break;
        }

        final hasValue = currentValue > 0;

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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: hasValue ? Colors.green.shade100 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'KES $value',
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
                      initialValue: currentValue > 0 ? currentValue.toString() : '',
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
                        hintText: '0',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      onChanged: (value) {
                        final intValue = int.tryParse(value) ?? 0;
                        onDenominationChanged(key, intValue);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
