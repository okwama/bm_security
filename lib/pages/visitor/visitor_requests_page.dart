import 'package:flutter/material.dart';
import 'package:bm_security/models/visitor_model.dart';
import 'package:bm_security/services/visitor_service.dart';
import 'package:bm_security/utils/date_formatter.dart';
import 'package:bm_security/widgets/loading_indicator.dart';
import 'package:bm_security/widgets/error_view.dart';
import 'package:bm_security/widgets/success_view.dart';

class VisitorRequestsPage extends StatefulWidget {
  const VisitorRequestsPage({super.key});

  @override
  _VisitorRequestsPageState createState() => _VisitorRequestsPageState();
}

class _VisitorRequestsPageState extends State<VisitorRequestsPage> {
  bool _isLoading = false;
  List<Visitor> _visitorRequests = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVisitorRequests();
  }

  Future<void> _loadVisitorRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Get only the visitor requests made by the current user
      final requests = await VisitorService.getVisitorRequests(onlyCurrentUser: true);
      setState(() => _visitorRequests = requests);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateVisitorStatus(
      Visitor visitor, VisitorStatus status) async {
    if (visitor.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot update status: Invalid visitor ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(visitor, status);
    if (!confirmed) return;

    setState(() => _isLoading = true);
    try {
      await VisitorService.updateVisitorStatus(visitor.id!, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Visitor request ${status.toString().split('.').last}'),
            backgroundColor:
                status == VisitorStatus.approved ? Colors.green : Colors.red,
          ),
        );
        _loadVisitorRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to update status: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _showConfirmationDialog(
      Visitor visitor, VisitorStatus status) async {
    final String action =
        status == VisitorStatus.approved ? 'approve' : 'reject';
    final Color headerColor =
        status == VisitorStatus.approved ? Colors.green : Colors.red;
    final IconData headerIcon =
        status == VisitorStatus.approved ? Icons.check_circle : Icons.cancel;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(headerIcon, color: headerColor),
                const SizedBox(width: 8),
                Text('Confirm $action'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to $action this visitor request?'),
                const SizedBox(height: 16),
                _buildDialogInfoRow('Visitor Name:', visitor.visitorName),
                _buildDialogInfoRow('Phone:', visitor.visitorPhone),
                _buildDialogInfoRow(
                    'Visit Time:', formatDateTime(visitor.scheduledVisitTime)),
                _buildDialogInfoRow('Reason:', visitor.reasonForVisit),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: headerColor,
                  foregroundColor: Colors.white,
                ),
                child: Text('Yes, $action'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildDialogInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVisitorRequests,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _error != null
              ? ErrorView(
                  title: 'Failed to Load Requests',
                  message: _error!,
                  onRetry: _loadVisitorRequests,
                )
              : _visitorRequests.isEmpty
                  ? const SuccessView(
                      title: 'No Visitor Requests',
                      message: 'There are no visitor requests at the moment.',
                      icon: Icons.people_outline,
                    )
                  : RefreshIndicator(
                      onRefresh: _loadVisitorRequests,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _visitorRequests.length,
                        itemBuilder: (context, index) {
                          final visitor = _visitorRequests[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(visitor.status),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getStatusIcon(visitor.status),
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        visitor.status
                                            .toString()
                                            .split('.')
                                            .last
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        formatDateTime(
                                            visitor.scheduledVisitTime),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          visitor.idPhotoUrl != null
                                              ? Stack(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 20,
                                                      backgroundImage:
                                                          NetworkImage(visitor
                                                              .idPhotoUrl!),
                                                      onBackgroundImageError:
                                                          (_, __) {
                                                        setState(() {});
                                                      },
                                                    ),
                                                    Positioned(
                                                      right: 0,
                                                      bottom: 0,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(3),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.green,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons.check,
                                                          color: Colors.white,
                                                          size: 10,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      const Icon(
                                                        Icons.person,
                                                        size: 20,
                                                        color: Colors.grey,
                                                      ),
                                                      const SizedBox(height: 1),
                                                      Text(
                                                        'No Photo',
                                                        style: TextStyle(
                                                          fontSize: 7,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  visitor.visitorName,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  visitor.visitorPhone,
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildInfoRow(Icons.description,
                                                visitor.reasonForVisit),
                                            if (visitor.user != null &&
                                                visitor.user!['apartment_no'] !=
                                                    null)
                                              _buildInfoRow(
                                                Icons.home,
                                                'Apartment: ${visitor.user!['apartment_no']}',
                                              ),
                                            if (visitor.notes != null &&
                                                visitor.notes!.isNotEmpty)
                                              _buildInfoRow(
                                                  Icons.note, visitor.notes!),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (visitor.status == VisitorStatus.pending)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(8),
                                        bottomRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          icon: const Icon(Icons.check,
                                              color: Colors.green, size: 16),
                                          label: const Text('Approve',
                                              style: TextStyle(fontSize: 13)),
                                          onPressed: () => _updateVisitorStatus(
                                              visitor, VisitorStatus.approved),
                                        ),
                                        TextButton.icon(
                                          icon: const Icon(Icons.close,
                                              color: Colors.red, size: 16),
                                          label: const Text('Reject',
                                              style: TextStyle(fontSize: 13)),
                                          onPressed: () => _updateVisitorStatus(
                                              visitor, VisitorStatus.rejected),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(VisitorStatus status) {
    switch (status) {
      case VisitorStatus.pending:
        return Colors.orange;
      case VisitorStatus.approved:
        return Colors.green;
      case VisitorStatus.rejected:
        return Colors.red;
      case VisitorStatus.completed:
        return Colors.blue;
      case VisitorStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(VisitorStatus status) {
    switch (status) {
      case VisitorStatus.pending:
        return Icons.schedule;
      case VisitorStatus.approved:
        return Icons.check_circle;
      case VisitorStatus.rejected:
        return Icons.cancel;
      case VisitorStatus.completed:
        return Icons.done_all;
      case VisitorStatus.cancelled:
        return Icons.block;
    }
  }
}
