import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // For iOS-style icons and colors

/// A customizable success dialog widget for displaying successful operations.
/// It mimics the design principles of the `LoadingSpinner` for consistency.
class SuccessDialog extends StatelessWidget {
  /// The title of the success dialog.
  final String title;

  /// An optional message to display below the title.
  final String? message;

  /// The text for the primary action button. Defaults to 'Done'.
  final String buttonText;

  /// The callback function when the primary action button is pressed.
  final VoidCallback onButtonPressed;

  /// The color of the success icon and primary button.
  /// Defaults to CupertinoColors.activeGreen.
  final Color? successColor;

  /// The icon to display for success. Defaults to CupertinoIcons.check_mark_circled_solid.
  final IconData successIcon;

  const SuccessDialog({
    super.key,
    required this.title,
    this.message,
    this.buttonText = 'Done',
    required this.onButtonPressed,
    this.successColor,
    this.successIcon = CupertinoIcons.check_mark_circled_solid,
  });

  /// Factory constructor for a basic, common success dialog.
  const SuccessDialog.basic({
    Key? key,
    required String title,
    String? message,
    String buttonText = 'Done',
    required VoidCallback onButtonPressed,
  }) : this(
          key: key,
          title: title,
          message: message,
          buttonText: buttonText,
          onButtonPressed: onButtonPressed,
          successColor: CupertinoColors.activeGreen,
          successIcon: CupertinoIcons.check_mark_circled_solid,
        );

  @override
  Widget build(BuildContext context) {
    final Color effectiveSuccessColor = successColor ??
        Theme.of(context)
            .primaryColor; // Or a consistent success color from your theme

    return Material(
      // Use Material to allow for dialog shape and shadow
      type:
          MaterialType.transparency, // Make the Material background transparent
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            decoration: BoxDecoration(
              color:
                  CupertinoColors.systemBackground, // iOS-like background color
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20.0,
                  spreadRadius: 2.0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  successIcon,
                  color: effectiveSuccessColor,
                  size: 64.0, // Larger icon for prominence
                ),
                const SizedBox(height: 24.0),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.label, // iOS-like text color
                      ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 12.0),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: CupertinoColors
                              .secondaryLabel, // iOS-like secondary text color
                        ),
                  ),
                ],
                const SizedBox(height: 32.0),
                SizedBox(
                  width: double.infinity, // Full width button
                  child: CupertinoButton.filled(
                    // iOS-style filled button
                    onPressed: onButtonPressed,
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A helper function to show the success dialog.
/// Usage: `showSuccessDialog(context, title: 'Success!', message: 'Your action was completed.', onDone: () => Navigator.pop(context));`
void showSuccessDialog({
  required BuildContext context,
  required String title,
  String? message,
  String buttonText = 'Done',
  required VoidCallback onDone,
  Color? successColor,
  IconData? successIcon,
  bool barrierDismissible = false, // Prevents dismissing by tapping outside
}) {
  showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext dialogContext) {
      // Use dialogContext to safely pop
      return SuccessDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        onButtonPressed: () {
          Navigator.of(dialogContext).pop(); // Pop the dialog first
          onDone(); // Then execute the provided callback
        },
        successColor: successColor,
        successIcon: successIcon ?? CupertinoIcons.check_mark_circled_solid,
      );
    },
  );
}

// --- Example Usage ---
class SuccessDialogExample extends StatelessWidget {
  const SuccessDialogExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Success Dialog Examples'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                showSuccessDialog(
                  context: context,
                  title: 'Booking Confirmed!',
                  message:
                      'Your flight has been successfully booked. A confirmation email has been sent.',
                  buttonText: 'View My Trips',
                  onDone: () {
                    // Navigate to trips page or perform another action
                    print('Navigating to My Trips');
                    // Navigator.pushNamed(context, '/trips'); // Example navigation
                  },
                );
              },
              child: const Text('Show Booking Success'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                showSuccessDialog(
                  context: context,
                  title: 'Password Updated!',
                  message: 'Your password has been securely changed.',
                  onDone: () => print('Password updated!'),
                );
              },
              child: const Text('Show Simple Success'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                showSuccessDialog(
                  context: context,
                  title: 'Payment Received!',
                  message:
                      'Thank you for your payment. Your transaction is complete.',
                  buttonText: 'Done',
                  successColor: Colors.deepPurple, // Custom color
                  successIcon:
                      CupertinoIcons.money_dollar_circle_fill, // Custom icon
                  onDone: () => print('Payment success!'),
                );
              },
              child: const Text('Show Custom Payment Success'),
            ),
          ],
        ),
      ),
    );
  }
}

