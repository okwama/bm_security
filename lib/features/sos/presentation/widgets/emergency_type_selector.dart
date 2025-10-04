import 'package:flutter/material.dart';

class EmergencyTypeSelector extends StatelessWidget {
  final List<Map<String, dynamic>> distressTypes;
  final String? selectedType;
  final Function(String) onTypeSelected;

  const EmergencyTypeSelector({
    super.key,
    required this.distressTypes,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: distressTypes.length,
      itemBuilder: (context, index) {
        final type = distressTypes[index];
        final isSelected = selectedType == type['id'];
        return GestureDetector(
          onTap: () => onTypeSelected(type['id']),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.red.shade100
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.red
                    : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type['icon'],
                  size: 32,
                  color: isSelected ? Colors.red : Colors.grey,
                ),
                const SizedBox(height: 8),
                Text(
                  type['name'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.red
                        : Colors.grey.shade700,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
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
