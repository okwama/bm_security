import 'package:flutter/material.dart';
import '../../components/loading_spinner.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  final bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maps'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Implement refresh logic
        },
        child: _isLoading
            ? const LoadingSpinner.fullScreen(message: 'Loading map...')
            : const Center(
                child: Text('Maps Page'),
              ),
      ),
    );
  }
}
