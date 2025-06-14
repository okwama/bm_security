# Cash Count Implementation Pattern

## Overview
This document outlines the standard pattern for implementing cash count functionality in the BM Security app. The pattern ensures consistent handling of cash denomination counting across different service types (BSS Slip, ATM Collection, etc.).

## Core Components

### 1. State Management
```dart
class _ServicePageState extends State<ServicePage> {
  CashCount? _cashCount;  // Store cash count data
  // ... other state variables
}
```

### 2. Navigation Method
```dart
Future<void> _navigateToCashCount() async {
  try {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CashCountPage(
          onConfirm: (cashCount) {
            if (!mounted) return;
            setState(() => _cashCount = cashCount);
          },
        ),
      ),
    );

    if (result != null && result is CashCount) {
      if (!mounted) return;
      setState(() => _cashCount = result);
    }
  } catch (e) {
    debugPrint('Error navigating to cash count: $e');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### 3. UI Component
```dart
Widget _buildCashCountSection() {
  return _buildCompactSection(
    title: 'Cash Count',
    icon: Icons.account_balance_wallet,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_cashCount != null) ...[
          Text(
            'Total Amount: KES ${_cashCount!.totalAmount}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: _navigateToCashCount,
            icon: Icon(
              _cashCount != null ? Icons.edit : Icons.add,
              size: 16,
            ),
            label: Text(
              _cashCount != null ? 'Edit Cash Count' : 'Enter Denominations',
              style: const TextStyle(fontSize: 12),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              backgroundColor: Colors.grey.shade100,
            ),
          ),
        ),
      ],
    ),
  );
}
```

### 4. Pickup Confirmation
```dart
Future<void> _confirmPickup() async {
  if (_cashCount == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please complete the cash count first'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
  
  // ... rest of pickup confirmation logic
  await _requisitionsService.confirmPickup(
    widget.requisition.id,
    cashCount: _cashCount,
    // ... other parameters
  );
}
```

## Implementation Steps

1. **Add State Variable**
   - Add `CashCount? _cashCount` to your state class

2. **Add Navigation Method**
   - Implement `_navigateToCashCount()` method
   - Handle both callback and navigation result

3. **Add UI Component**
   - Implement `_buildCashCountSection()`
   - Add it to your page's widget tree

4. **Update Pickup Confirmation**
   - Add cash count validation
   - Include cash count in pickup confirmation

## Best Practices

1. **Error Handling**
   - Always check for mounted state before setState
   - Provide clear error messages
   - Include retry options where appropriate

2. **State Management**
   - Use setState for UI updates
   - Validate cash count before pickup
   - Clear cash count when appropriate

3. **UI/UX**
   - Show total amount when available
   - Provide clear edit/add button
   - Use consistent styling

4. **Performance**
   - Dispose controllers properly
   - Handle memory management
   - Check mounted state

## Common Issues

1. **State Not Updating**
   - Check mounted state
   - Verify setState calls
   - Ensure proper widget tree structure

2. **Navigation Issues**
   - Handle both callback and result
   - Check for null values
   - Verify type casting

3. **UI Not Refreshing**
   - Verify setState calls
   - Check widget rebuild conditions
   - Ensure proper state management

## Example Usage

```dart
// In your service page
class _ServicePageState extends State<ServicePage> {
  CashCount? _cashCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildCashCountSection(),
          // ... other widgets
        ],
      ),
    );
  }
}
``` 