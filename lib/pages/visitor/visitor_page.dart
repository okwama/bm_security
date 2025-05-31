import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bm_security/models/visitor_model.dart';
import 'package:bm_security/services/api_service.dart';
import 'package:bm_security/services/visitor_service.dart';
import 'package:bm_security/utils/date_formatter.dart';
import 'package:bm_security/widgets/loading_indicator.dart';
import 'package:bm_security/widgets/error_dialog.dart';
import 'package:get_storage/get_storage.dart';
import 'package:bm_security/pages/visitor/visitor_requests_page.dart';
import 'package:bm_security/widgets/error_view.dart';
import 'package:bm_security/widgets/success_view.dart';
import 'dart:io';

class VisitorPage extends StatefulWidget {
  const VisitorPage({super.key});

  @override
  _VisitorPageState createState() => _VisitorPageState();
}

class _VisitorPageState extends State<VisitorPage> {
  final _formKey = GlobalKey<FormState>();
  final _visitorNameController = TextEditingController();
  final _visitorPhoneController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _idPhotoUrl;
  bool _isLoading = false;
  List<Visitor> _visitorRequests = [];
  final _imagePicker = ImagePicker();
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVisitorRequests();
  }

  @override
  void dispose() {
    _visitorNameController.dispose();
    _visitorPhoneController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadVisitorRequests() async {
    setState(() => _isLoading = true);
    try {
      final requests = await VisitorService.getVisitorRequests();
      setState(() {
        _visitorRequests = requests;
        // Clear any previous errors
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image =
          await _imagePicker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() => _isLoading = true);
        try {
          // Upload the image first
          final filePath =
              await VisitorService.uploadVisitorPhoto(File(image.path));
          setState(() => _idPhotoUrl = filePath);
        } catch (e) {
          if (mounted) {
            showErrorDialog(context, 'Error', 'Failed to upload image: $e');
            // Clear the photo URL if upload fails
            setState(() => _idPhotoUrl = null);
          }
        } finally {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, 'Error', 'Failed to capture image: $e');
      }
    }
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _submitVisitorRequest() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      print('Form validation failed or required fields are missing');
      return;
    }

    // Show confirmation dialog before submitting
    final bool confirmed = await _showSubmitConfirmationDialog();
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Get user information from local storage
      final box = GetStorage();
      final userData = box.read('user');
      print('User data from storage: $userData');

      if (userData == null) {
        throw Exception('User information not found');
      }

      final visitor = Visitor(
        userId: userData['id'],
        userName: userData['name'],
        userPhone: userData['phoneNumber'],
        visitorName: _visitorNameController.text,
        visitorPhone: _visitorPhoneController.text,
        reasonForVisit: _reasonController.text,
        idPhotoUrl: _idPhotoUrl,
        scheduledVisitTime: _selectedDate!,
        createdAt: DateTime.now(),
        status: VisitorStatus.pending,
        notes: _notesController.text,
      );

      print('Submitting visitor request with data: ${visitor.toJson()}');

      await VisitorService.createVisitorRequest(visitor);
      print('Visitor request submitted successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visitor request submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _resetForm();
      }
    } catch (e) {
      print('Error submitting visitor request: $e');
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _showSubmitConfirmationDialog() async {
    final box = GetStorage();
    final userData = box.read('user');
    final apartmentNo = userData?['apartment_no'];

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('Confirm Submission'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Are you sure you want to submit this visitor request?'),
                const SizedBox(height: 16),
                _buildConfirmationInfoRow(
                    'Visitor Name:', _visitorNameController.text),
                _buildConfirmationInfoRow(
                    'Visitor Phone:', _visitorPhoneController.text),
                _buildConfirmationInfoRow(
                    'Visit Time:', formatDateTime(_selectedDate!)),
                _buildConfirmationInfoRow('Reason:', _reasonController.text),
                if (apartmentNo != null)
                  _buildConfirmationInfoRow('Apartment:', apartmentNo),
                if (_notesController.text.isNotEmpty)
                  _buildConfirmationInfoRow('Notes:', _notesController.text),
                if (_idPhotoUrl != null)
                  _buildConfirmationInfoRow('ID Photo:', 'Captured'),
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
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Yes, Submit'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildConfirmationInfoRow(String label, String value) {
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

  void _resetForm() {
    _formKey.currentState?.reset();
    _selectedDate = null;
    _idPhotoUrl = null;
  }

  Future<void> _updateVisitorStatus(
      Visitor visitor, VisitorStatus status) async {
    setState(() => _isLoading = true);
    try {
      await VisitorService.updateVisitorStatus(visitor.id!, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Visitor request ${status.toString().split('.').last}')),
        );
        _loadVisitorRequests();
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(
            context, 'Error', 'Failed to update visitor status: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Visit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VisitorRequestsPage(),
                ),
              );
            },
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
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildScheduleVisitForm(),
                ),
    );
  }

  Widget _buildScheduleVisitForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_add, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Schedule a Visit',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _visitorNameController,
                decoration: const InputDecoration(
                  labelText: 'Visitor Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter visitor name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _visitorPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Visitor Phone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter visitor phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for Visit',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter reason for visit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_selectedDate == null
                    ? 'Select Visit Date & Time'
                    : 'Visit: ${formatDateTime(_selectedDate!)}'),
                subtitle: const Text('* Required'),
                leading: const Icon(Icons.calendar_today),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _selectDateTime,
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 1,
                child: ListTile(
                  title: Text(_idPhotoUrl == null
                      ? 'Capture ID Photo'
                      : 'ID Photo Captured'),
                  subtitle: Text(
                    _idPhotoUrl == null
                        ? 'Optional - Tap to capture visitor\'s ID photo'
                        : 'Tap to retake photo',
                  ),
                  leading: _idPhotoUrl == null
                      ? const Icon(Icons.camera_alt)
                      : const Icon(Icons.check_circle, color: Colors.green),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_idPhotoUrl != null)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() => _idPhotoUrl = null);
                          },
                        ),
                      const Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                  onTap: _pickImage,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _submitVisitorRequest,
                  icon: const Icon(Icons.send),
                  label: const Text('Submit Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
