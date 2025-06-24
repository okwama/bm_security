import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/request.dart';
import '../../../services/requisitions/requisitions_service.dart';
import 'requisitionDetail.dart';
import '../../../components/loading_spinner.dart';
import '../../../services/http/auth_service.dart';
import '../../../utils/navigation.dart';

class PendingRequisitionsPage extends StatefulWidget {
  const PendingRequisitionsPage({super.key});

  static int getPendingCount() {
    return _PendingRequisitionsPageState.pendingCount;
  }

  @override
  State<PendingRequisitionsPage> createState() =>
      _PendingRequisitionsPageState();
}

class _PendingRequisitionsPageState extends State<PendingRequisitionsPage> {
  final RequisitionsService _requisitionsService = RequisitionsService();
  final AuthService _authService = AuthService();
  List<Request> _requisitions = [];
  bool _isLoading = true;
  String? _error;
  static int pendingCount = 0;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  DateTime? _lastRefreshTime;
  static const Duration _minRefreshInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    print('🔄 PendingRequisitionsPage initialized');
    _fetchRequisitions();
  }

  Future<void> _fetchRequisitions() async {
    if (!mounted) {
      print('⚠️ Component not mounted, skipping fetch');
      return;
    }

    // Check if we're trying to refresh too frequently
    if (_lastRefreshTime != null) {
      final timeSinceLastRefresh = DateTime.now().difference(_lastRefreshTime!);
      if (timeSinceLastRefresh < _minRefreshInterval) {
        print(
            '⏰ Refresh too soon, skipping. Time since last refresh: $timeSinceLastRefresh');
        return;
      }
    }

    print('📥 Fetching pending requisitions...');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('📡 Fetching requests from service...');
      final requests = await _requisitionsService.getPendingRequests();
      if (!mounted) {
        print('⚠️ Component unmounted during fetch, aborting update');
        return;
      }

      print('📊 Received ${requests.length} pending requests');
      setState(() {
        _requisitions = requests;
        _isLoading = false;
        _retryCount = 0;
        _lastRefreshTime = DateTime.now();
        pendingCount = requests.length;
      });
      print('✅ State updated successfully');
    } catch (e) {
      print('❌ Error fetching requisitions: $e');
      if (!mounted) {
        print('⚠️ Component unmounted during error handling');
        return;
      }

      setState(() {
        _isLoading = false;
        _error = e.toString();
        _retryCount++;
      });
      print('📊 Retry count: $_retryCount');

      // Handle authentication errors
      if (e.toString().contains('Authentication required') ||
          e.toString().contains('Session expired')) {
        print('🔒 Authentication error detected');
        _handleAuthError();
      } else if (_retryCount < _maxRetries) {
        print('🔄 Scheduling retry in 2 seconds...');
        Future.delayed(const Duration(seconds: 2), _fetchRequisitions);
      } else {
        print('❌ Max retries reached');
      }
    }
  }

  void _handleAuthError() {
    print('🔒 Handling authentication error');
    // Clear any stored credentials
    _authService.cleartoken();
    print('🗑️ Token cleared');

    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your session has expired. Please login again.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
    print('📱 Error message displayed');

    // Navigate to login
    print('🔄 Scheduling navigation to login...');
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        print('🔄 Navigating to login page');
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      } else {
        print('⚠️ Component unmounted during navigation');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ Building PendingRequisitionsPage');
    final primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Requisitions'),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _canRefresh() ? _fetchRequisitions : null,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          print('🔄 Pull-to-refresh triggered');
          if (_canRefresh()) {
            await _fetchRequisitions();
          } else {
            print('⏰ Refresh too soon, ignoring pull-to-refresh');
          }
        },
        child: _buildBody(),
      ),
    );
  }

  bool _canRefresh() {
    if (_lastRefreshTime == null) {
      print('✅ Can refresh: No previous refresh');
      return true;
    }
    final canRefresh =
        DateTime.now().difference(_lastRefreshTime!) >= _minRefreshInterval;
    print(
        '⏰ Can refresh: $canRefresh (Time since last refresh: ${DateTime.now().difference(_lastRefreshTime!)})');
    return canRefresh;
  }

  Widget _buildBody() {
    print('🏗️ Building body content');
    if (_isLoading) {
      print('⏳ Showing loading spinner');
      return const LoadingSpinner.fullScreen(
          message: 'Loading pending requisitions...');
    }

    if (_error != null) {
      print('❌ Showing error state: $_error');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _error!.contains('Authentication required') ||
                      _error!.contains('Session expired')
                  ? Icons.lock_outline
                  : Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (!_error!.contains('Authentication required') &&
                !_error!.contains('Session expired'))
              ElevatedButton(
                onPressed: () {
                  print('🔄 Retry button pressed');
                  _fetchRequisitions();
                },
                child: const Text('Retry'),
              ),
          ],
        ),
      );
    }

    if (_requisitions.isEmpty) {
      print('📭 No requisitions to display');
      return const Center(
        child: Text('No pending requisitions found'),
      );
    }

    print('📋 Building list of ${_requisitions.length} requisitions');
    return ListView.builder(
      itemCount: _requisitions.length,
      itemBuilder: (context, index) {
        final req = _requisitions[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            title: Text(
              req.serviceType,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Pickup: ${req.pickupLocation}',
                    style: const TextStyle(fontSize: 13)),
                Text('Delivery: ${req.deliveryLocation}',
                    style: const TextStyle(fontSize: 13)),
                Text(
                  req.pickupDate != null
                      ? DateFormat('MMM dd, yyyy hh:mm a')
                          .format(req.pickupDate!)
                      : 'Not specified',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.red),
            onTap: () async {
              print('👆 Tapped requisition: ${req.serviceType}');
              await _navigateToDetail(req);
            },
          ),
        );
      },
    );
  }

  Widget _getPriorityIcon(Priority priority) {
    switch (priority) {
      case Priority.high:
        return const Icon(Icons.assignment_outlined, color: Colors.red);
      case Priority.medium:
        return const Icon(Icons.assignment_outlined, color: Colors.orange);
      case Priority.low:
        return const Icon(Icons.assignment_outlined, color: Colors.green);
    }
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
  }

  Future<void> _navigateToDetail(Request request) async {
    print('🔄 Navigating to detail view for request: ${request.serviceType}');
    if (!mounted) {
      print('⚠️ Component not mounted, aborting navigation');
      return;
    }
    setState(() => _isLoading = true);

    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RequisitionDetail(request: request),
        ),
      );

      if (mounted) {
        print('🔄 Returning from detail view, refreshing list');
        await _fetchRequisitions();

        if (result == true) {
          print('✅ Operation completed successfully');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text('Operation completed successfully'),
                ],
              ),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error in detail navigation: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    print('🗑️ Disposing PendingRequisitionsPage');
    _requisitionsService.dispose();
    super.dispose();
  }
}
