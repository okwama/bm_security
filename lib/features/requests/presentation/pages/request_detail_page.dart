import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/requests_bloc.dart';
import '../../domain/entities/request_entity.dart';
import '../widgets/request_header.dart';
import '../widgets/location_card.dart';
import '../widgets/cash_count_card.dart';
import '../widgets/action_buttons.dart';
import '../widgets/loading_widget.dart';
import '../../../location/presentation/bloc/location_bloc.dart';
import '../../../location/presentation/widgets/location_indicator.dart';
import '../../../location/presentation/services/location_tracking_service.dart';
import 'bss_slip_page.dart';
import 'cdm_collection_page.dart';
import 'atm_collection_page.dart';
import 'pick_drop_page.dart';
import 'airlift_page.dart';
import 'callout_page.dart';
import 'maintenance_page.dart';
import 'atm_collection_new_page.dart';
import 'bank_transfer_page.dart';

class RequestDetailPage extends StatefulWidget {
  final RequestEntity request;

  const RequestDetailPage({
    super.key,
    required this.request,
  });

  @override
  State<RequestDetailPage> createState() => _RequestDetailPageState();
}

class _RequestDetailPageState extends State<RequestDetailPage> {
  bool _isLoading = false;
  bool _showSuccess = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<LocationBloc>(),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Row(
            children: [
              const Text('Requisition Details'),
              const SizedBox(width: 8),
              LocationIndicator(requestId: widget.request.id),
            ],
          ),
          backgroundColor: const Color(AppConstants.primaryColorValue),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _isLoading
            ? const LoadingWidget(message: 'Processing...')
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    RequestHeader(request: widget.request),
                    const SizedBox(height: 16),
                    LocationCard(request: widget.request),
                    const SizedBox(height: 16),
                    CashCountCard(request: widget.request),
                    const SizedBox(height: 8),
                    ActionButtons(
                      request: widget.request,
                      onConfirmPickup: _confirmPickup,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _confirmPickup() async {
    final bool? confirm = await _showConfirmationDialog();
    if (confirm != true) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      bool? result;
      
      // Navigate to appropriate service process page based on service type
      switch (widget.request.serviceType?.id) {
        case 1: // Pick and Drop
          result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PickDropPage(request: widget.request),
            ),
          );
          break;
        case 2: // BSS
        case 5: // BSS Vault (now merged with BSS)
          result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BssSlipPage(request: widget.request),
            ),
          );
          break;
        case 3: // CDM Collection
          result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CdmCollectionPage(request: widget.request),
            ),
          );
          break;
        case 4: // ATM Loading
          result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AtmCollectionPage(request: widget.request),
            ),
          );
          break;
        case 5: // Airlift
          result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AirliftPage(request: widget.request),
            ),
          );
          break;
        case 6: // ATM Collection
          result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AtmCollectionNewPage(request: widget.request),
            ),
          );
          break;
        case 7: // Bank Transfer
          result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BankTransferPage(request: widget.request),
            ),
          );
          break;
        case 10: // Callout
          result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CalloutPage(request: widget.request),
            ),
          );
          break;
        case 11: // Maintenance
          result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MaintenancePage(request: widget.request),
            ),
          );
          break;
        default:
          _showError('Unknown service type');
          break;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _showSuccess = result == true;
        });

        if (result == true) {
          // Start location tracking for this request
          LocationTrackingService.startTrackingForRequest(context, widget.request.id);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Pickup confirmed successfully'),
                ],
              ),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(_getErrorMessage(e));
    }
  }

  Future<bool?> _showConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner, color: Color(AppConstants.primaryColorValue)),
            SizedBox(width: 8),
            Text('Confirm Pickup'),
          ],
        ),
        content: const Text('Are you sure you want to confirm this pickup?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(AppConstants.primaryColorValue),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  String _getErrorMessage(dynamic error) {
    if (error is String) {
      return error;
    } else if (error is Map<String, dynamic>) {
      return error['message'] ?? 'An error occurred';
    } else if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return 'An unexpected error occurred';
  }

  void _showError(String message) {
    if (!mounted) return;

    final errorMessage = message.contains(': ')
        ? message.split(': ').sublist(1).join(': ')
        : message;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
