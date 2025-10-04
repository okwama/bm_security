import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../bloc/requests_bloc.dart';
import '../widgets/request_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/empty_state_widget.dart';

class CompletedRequestsPage extends StatefulWidget {
  const CompletedRequestsPage({super.key});

  @override
  State<CompletedRequestsPage> createState() => _CompletedRequestsPageState();
}

class _CompletedRequestsPageState extends State<CompletedRequestsPage> {
  DateTime? _lastRefreshTime;
  static const Duration _minRefreshInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    context.read<RequestsBloc>().add(
      const LoadRequestsEvent(status: AppConstants.statusCompleted),
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
        const RefreshRequestsEvent(status: AppConstants.statusCompleted),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Requisitions'),
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
                  message: 'Loading completed requisitions...',
                );
              } else if (state is RequestsError) {
                return RequestErrorWidget(
                  message: state.message,
                  onRetry: _loadRequests,
                );
              } else if (state is RequestsLoaded) {
                final completedRequests = state.requests
                    .where((request) => request.myStatus == AppConstants.statusCompleted)
                    .toList();

                if (completedRequests.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.done_all_outlined,
                    title: 'No Completed Requests',
                    message: 'No requisitions have been completed yet.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: completedRequests.length,
                  itemBuilder: (context, index) {
                    final request = completedRequests[index];
                    return RequestCard(
                      request: request,
                      onTap: () => _navigateToDetail(request),
                    );
                  },
                );
              }

              return const LoadingWidget(
                message: 'Loading completed requisitions...',
              );
            },
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(request) {
    // TODO: Navigate to request detail page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request details - Coming soon')),
    );
  }
}
