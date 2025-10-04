import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/requests_bloc.dart';
import '../widgets/request_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../../../location/presentation/bloc/location_bloc.dart';
import '../../../location/presentation/widgets/location_indicator.dart';
import 'delivery_completion_page.dart';

class InProgressRequestsPage extends StatefulWidget {
  const InProgressRequestsPage({super.key});

  @override
  State<InProgressRequestsPage> createState() => _InProgressRequestsPageState();
}

class _InProgressRequestsPageState extends State<InProgressRequestsPage> {
  DateTime? _lastRefreshTime;
  static const Duration _minRefreshInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    context.read<RequestsBloc>().add(
      const LoadRequestsEvent(status: AppConstants.statusInProgress),
    );
  }

  bool _canRefresh() {
    if (_lastRefreshTime == null) return true;
    return DateTime.now().difference(_lastRefreshTime!) >= _minRefreshInterval;
  }

  Future<void> _onRefresh() async {
    if (_canRefresh()) {
      _lastRefreshTime = DateTime.now();
      context.read<RequestsBloc>().add(
        const RefreshRequestsEvent(status: AppConstants.statusInProgress),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<LocationBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('In Progress Requisitions'),
              SizedBox(width: 8),
              // We'll show a general tracking indicator here
              // Individual request tracking will be shown in request cards
            ],
          ),
          centerTitle: true,
          backgroundColor: const Color(AppConstants.primaryColorValue),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _canRefresh() ? _loadRequests : null,
            ),
          ],
        ),
      body: BlocListener<RequestsBloc, RequestsState>(
        listener: (context, state) {
          if (state is RequestsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: BlocBuilder<RequestsBloc, RequestsState>(
            builder: (context, state) {
              if (state is RequestsLoading) {
                return const LoadingWidget(
                  message: 'Loading in-progress requisitions...',
                );
              } else if (state is RequestsError) {
                return RequestErrorWidget(
                  message: state.message,
                  onRetry: _loadRequests,
                );
              } else if (state is RequestsLoaded) {
                final inProgressRequests = state.requests
                    .where((request) => request.myStatus == AppConstants.statusInProgress)
                    .toList();

                if (inProgressRequests.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.watch_later_outlined,
                    title: 'No In-Progress Requests',
                    message: 'No requisitions are currently in progress.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: inProgressRequests.length,
                  itemBuilder: (context, index) {
                    final request = inProgressRequests[index];
                    return RequestCard(
                      request: request,
                      onTap: () => _navigateToDetail(request),
                    );
                  },
                );
              }

              return const LoadingWidget(
                message: 'Loading in-progress requisitions...',
              );
            },
          ),
        ),
      ),
      ),    );
  }

  void _navigateToDetail(request) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DeliveryCompletionPage(request: request),
      ),
    );
    
    // If delivery was completed, refresh the requests
    if (result == true) {
      _loadRequests();
    }
  }
}
