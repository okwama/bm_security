// ignore: file_names
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bm_security/controllers/auth_controller.dart';

class NoConnectionPage extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? message;

  const NoConnectionPage({
    super.key,
    this.onRetry,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Icon(
                  Icons.signal_wifi_off_rounded,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  'No Internet',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Message
                Text(
                  message ?? 'Please check your connection and try again.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Retry Button
                ElevatedButton.icon(
                  onPressed: () {
                    if (onRetry != null) {
                      onRetry!();
                    } else {
                      final authController = Get.find<AuthController>();
                      if (authController.isAuthenticated) {
                        Get.offAllNamed('/home');
                      } else {
                        Get.offAllNamed('/login');
                      }
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
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

