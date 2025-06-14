import 'package:flutter/material.dart';
import '../components/loading_spinner.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: LoadingSpinner(),
    );
  }
}
