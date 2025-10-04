import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../bloc/requests_bloc.dart';
import '../widgets/request_card.dart';
import '../widgets/loading_widget.dart' as request_loading;
import '../widgets/error_widget.dart' as request_error;
import '../widgets/empty_state_widget.dart' as request_empty;
import 'request_detail_page.dart';
import 'pick_drop_page.dart';
import 'bss_slip_page.dart';
import 'cdm_collection_page.dart';
import 'atm_collection_page.dart';
import 'airlift_page.dart';
import 'callout_page.dart';
import 'maintenance_page.dart';
import 'atm_collection_new_page.dart';
import 'bank_transfer_page.dart';

class PendingRequestsPage extends StatefulWidget {
  const PendingRequestsPage({super.key});

  @override
  State<PendingRequestsPage> createState() => _PendingRequestsPageState();
}

class _PendingRequestsPageState extends State<PendingRequestsPage> {
  DateTime? _lastRefreshTime;
  static const Duration _minRefreshInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    context.read<RequestsBloc>().add(
      const LoadRequestsEvent(status: AppConstants.statusPending),
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
        const RefreshRequestsEvent(status: AppConstants.statusPending),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Requisitions'),
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
                return const request_loading.LoadingWidget(
                  message: 'Loading pending requisitions...',
                );
              } else if (state is RequestsError) {
                return request_error.RequestErrorWidget(
                  message: state.message,
                  onRetry: _loadRequests,
                );
              } else if (state is RequestsLoaded) {
                final pendingRequests = state.requests
                    .where((request) => request.myStatus == AppConstants.statusPending)
                    .toList();

                if (pendingRequests.isEmpty) {
                  return const request_empty.EmptyStateWidget(
                    icon: Icons.pending_outlined,
                    title: 'No Pending Requests',
                    message: 'All caught up! No pending requisitions at the moment.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: pendingRequests.length,
                  itemBuilder: (context, index) {
                    final request = pendingRequests[index];
                    return RequestCard(
                      request: request,
                      onTap: () => _navigateToServicePage(request),
                    );
                  },
                );
              }

              return const request_loading.LoadingWidget(
                message: 'Loading pending requisitions...',
              );
            },
          ),
        ),
      ),
    );
  }

  void _navigateToServicePage(request) {
    // Navigate directly to service-specific page based on service type
    switch (request.serviceType?.id) {
      case 1: // Pick and Drop
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PickDropPage(request: request),
          ),
        ).then((result) {
          if (result == true) {
            _loadRequests(); // Refresh list
          }
        });
        break;
      case 2: // BSS
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BssSlipPage(request: request),
          ),
        ).then((result) {
          if (result == true) {
            _loadRequests(); // Refresh list
          }
        });
        break;
      case 3: // CDM Collection
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CdmCollectionPage(request: request),
          ),
        ).then((result) {
          if (result == true) {
            _loadRequests(); // Refresh list
          }
        });
        break;
      case 4: // ATM Loading
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AtmCollectionPage(request: request),
          ),
        ).then((result) {
          if (result == true) {
            _loadRequests(); // Refresh list
          }
        });
        break;
      case 5: // Airlift
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AirliftPage(request: request),
          ),
        ).then((result) {
          if (result == true) {
            _loadRequests(); // Refresh list
          }
        });
        break;
      case 6: // ATM Collection
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AtmCollectionNewPage(request: request),
          ),
        ).then((result) {
          if (result == true) {
            _loadRequests(); // Refresh list
          }
        });
        break;
      case 7: // Bank Transfer
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BankTransferPage(request: request),
          ),
        ).then((result) {
          if (result == true) {
            _loadRequests(); // Refresh list
          }
        });
        break;
      case 10: // Callout
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CalloutPage(request: request),
          ),
        ).then((result) {
          if (result == true) {
            _loadRequests(); // Refresh list
          }
        });
        break;
      case 11: // Maintenance
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MaintenancePage(request: request),
          ),
        ).then((result) {
          if (result == true) {
            _loadRequests(); // Refresh list
          }
        });
        break;
      default:
        // Show error for unknown service type
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unknown service type: ${request.serviceType?.id}'),
            backgroundColor: Colors.red,
          ),
        );
        break;
    }
  }
}
