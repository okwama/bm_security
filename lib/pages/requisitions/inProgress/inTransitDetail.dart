import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bm_security/models/branch.dart';
import 'package:bm_security/services/http/auth_service.dart';
import 'package:get_storage/get_storage.dart';
import 'package:bm_security/models/request.dart';
import 'package:bm_security/models/staff.dart';
import 'package:bm_security/services/requisitions/requisitions_service.dart';
import 'package:bm_security/services/staff_service.dart';
import 'package:bm_security/services/location_service.dart';
import 'package:bm_security/widgets/error_dialog.dart' show showErrorDialog;
import 'dart:async';

class InTransitDetail extends StatefulWidget {
  final dynamic requisition;

  const InTransitDetail({super.key, required this.requisition});

  @override
  State<InTransitDetail> createState() => _InTransitDetailState();
}

class _InTransitDetailState extends State<InTransitDetail> {
  // Main form key
  final _formKey = GlobalKey<FormState>();
  // Bank details form key
  final _bankDetailsFormKey = GlobalKey<FormState>();

  final _sealNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAddressController = TextEditingController();
  final _receivingOfficerIdController = TextEditingController();
  final _receivingOfficerNameController = TextEditingController();
  final _receivingOfficerPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;
  bool _isVaultDelivery = false;
  bool _isBankDetailsExpanded = false;

  File? _imageFile;
  String? _imageUrl;
  Position? _currentPosition;
  Staff? _selectedVaultOfficer;
  List<Staff> _vaultOfficers = [];

  final RequisitionsService _requisitionsService = RequisitionsService();
  final GetStorage _storage = GetStorage();
  final StaffService _staffService = StaffService();
  final ImagePicker _picker = ImagePicker();
  final LocationService _locationService = LocationService();

  StreamSubscription<Position>? _locationSubscription;
  Timer? _locationUpdateTimer;
  List<Position> _locationHistory = [];
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _isVaultDelivery = widget.requisition.serviceType == 'CDM' ||
        widget.requisition.serviceType == 'BSS';
    _loadVaultOfficers();
    if (!_locationService.isTrackingRequest(widget.requisition.id.toString())) {
      _startLocationTracking();
    }
  }

  @override
  void dispose() {
    if (!_isSubmitting) {
      _stopLocationTracking();
    }
    _sealNumberController.dispose();
    _bankNameController.dispose();
    _bankAddressController.dispose();
    _receivingOfficerIdController.dispose();
    _receivingOfficerNameController.dispose();
    _receivingOfficerPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadVaultOfficers() async {
    if (mounted) {
      setState(() => _isSubmitting = true);
    }
    try {
      final officers = await _staffService.getVaultOfficers();
      if (mounted) {
        setState(() {
          _vaultOfficers = officers;
        });
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context,
          'Error',
          'Failed to load vault officers: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _startLocationTracking() async {
    try {
      // Request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Start continuous location updates
      _isTracking = true;
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1, // Update every 1 meters
        ),
      ).listen(
        (Position position) {
          setState(() {
            _currentPosition = position;
            _locationHistory.add(position);

            // Keep only last 100 locations to prevent memory issues
            if (_locationHistory.length > 100) {
              _locationHistory.removeAt(0);
            }
          });
        },
        onError: (error) {
          print('Location tracking error: $error');
          if (mounted) {
            showErrorDialog(
              context,
              'Location Error',
              'Error tracking location: $error',
            );
          }
        },
      );

      // Start periodic location updates to server
      _locationUpdateTimer =
          Timer.periodic(const Duration(minutes: 5), (timer) {
        if (_currentPosition != null) {
          _updateLocationToServer();
        }
      });
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context,
          'Location Error',
          'Failed to start location tracking: $e',
        );
      }
    }
  }

  Future<void> _stopLocationTracking() async {
    _isTracking = false;
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
  }

  Future<void> _updateLocationToServer() async {
    if (_currentPosition == null) return;

    try {
      // TODO: Implement API call to update location
      // await _requisitionsService.updateDeliveryLocation(
      //   widget.requisition.id,
      //   _currentPosition!.latitude,
      //   _currentPosition!.longitude,
      // );
      print(
          'Location updated to server: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
    } catch (e) {
      print('Failed to update location to server: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _imageUrl = 'https://example.com/uploaded-image.jpg';
        });
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context,
          'Camera Error',
          'Failed to capture image: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text(
          'In-Transit Delivery',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.requisition.serviceType != "Pick & Drop") ...[
                _buildPhotoSealSection(),
                const SizedBox(height: 16),
              ],
              if (_isVaultDelivery) ...[
                _buildBankDetailsButton(),
                const SizedBox(height: 16),
              ],
              if (_vaultOfficers.isNotEmpty) ...[
                _buildVaultOfficerSection(),
                const SizedBox(height: 16),
              ],
              _buildNotesField(),
              const SizedBox(height: 24),
              _buildCompleteButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSealSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seal Number & Photo',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _sealNumberController,
                  decoration: InputDecoration(
                    hintText: 'Enter seal number',
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(6),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.security,
                        color: Colors.blue.shade700,
                        size: 14,
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Seal number is required';
                    }
                    return null;
                  },
                ),
              ),
              Container(
                width: 50,
                height: 50,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _takePhoto,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: _imageFile == null
                            ? LinearGradient(
                                colors: [
                                  Colors.grey.shade100,
                                  Colors.grey.shade50,
                                ],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _imageFile == null
                          ? Icon(
                              Icons.camera_alt,
                              color: Colors.grey.shade600,
                              size: 24,
                            )
                          : Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _imageFile!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBankDetailsButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade50, Colors.blue]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _showBankDetailsDialog,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.account_balance,
                      color: Colors.blue.shade700, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add Bank Details',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    color: Colors.blue.shade700, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVaultOfficerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vault Officer (Optional)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonFormField<Staff>(
            decoration: InputDecoration(
              hintText: 'Select vault officer',
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.purple.shade700,
                  size: 16,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
            ),
            value: _selectedVaultOfficer,
            items: _vaultOfficers.map((officer) {
              return DropdownMenuItem<Staff>(
                value: officer,
                child: Text(officer.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedVaultOfficer = value;
              });
            },
            validator: (value) {
              if (_isVaultDelivery && value == null) {
                return 'Please select a vault officer';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comments',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
        ),
        const SizedBox(height: 2),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Comments...',
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(
                  Icons.note,
                  color: Colors.grey.shade600,
                  size: 16,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _completeDelivery,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSubmitting)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else ...[
              const Icon(Icons.check_circle, size: 20),
              const SizedBox(width: 8),
              Text(
                'COMPLETE DELIVERY',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showBankDetailsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 24,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.account_balance,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bank Details',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Enter your banking information',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _bankDetailsFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildModernTextField(
                          controller: _bankNameController,
                          label: 'Bank Name',
                          icon: Icons.account_balance,
                          isRequired: true,
                        ),
                        const SizedBox(height: 16),
                        _buildModernTextField(
                          controller: _bankAddressController,
                          label: 'Bank Address',
                          icon: Icons.location_on,
                          maxLines: 3,
                          isRequired: true,
                        ),
                        const SizedBox(height: 16),
                        _buildModernTextField(
                          controller: _receivingOfficerIdController,
                          label: 'Receiving Officer ID',
                          icon: Icons.badge,
                          isRequired: true,
                        ),
                        const SizedBox(height: 16),
                        _buildModernTextField(
                          controller: _receivingOfficerNameController,
                          label: 'Receiving Officer Name',
                          icon: Icons.person,
                          isRequired: true,
                        ),
                        const SizedBox(height: 16),
                        _buildModernTextField(
                          controller: _receivingOfficerPhoneController,
                          label: 'Receiving Officer Phone',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          isRequired: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_bankDetailsFormKey.currentState?.validate() ??
                              false) {
                            setState(() => _isBankDetailsExpanded = true);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text('Bank details saved successfully'),
                                  ],
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save, size: 18),
                            const SizedBox(width: 8),
                            Text('Save Details',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: isRequired
              ? (value) => value?.trim().isEmpty ?? true
                  ? 'This field is required'
                  : null
              : null,
          decoration: InputDecoration(
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            hintText: 'Enter $label',
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _completeDelivery() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    if (_isVaultDelivery && _isBankDetailsExpanded) {
      if (_bankNameController.text.isEmpty ||
          _bankAddressController.text.isEmpty ||
          _receivingOfficerIdController.text.isEmpty ||
          _receivingOfficerNameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all bank details'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = _storage.read('user_id');
      final userName = _storage.read('user_name');

      if (userId == null || userName == null) {
        try {
          final authService = AuthService();
          await authService.refreshToken();

          final newUserId = _storage.read('user_id');
          final newUserName = _storage.read('user_name');

          if (newUserId == null || newUserName == null) {
            throw Exception('User information not found after token refresh');
          }

          await _completeDeliveryWithUser(newUserId, newUserName);
        } catch (e, stackTrace) {
          print('=== UI Layer: Complete Delivery Error ===');
          print('Error type: ${e.runtimeType}');
          print('Error message: $e');
          print('Stack trace: $stackTrace');
          
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Session Expired'),
                  ],
                ),
                content: Text(
                    'Your session has expired. Please login again to continue.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).pop();
                    },
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/login',
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Login Again'),
                  ),
                ],
              ),
            );
          }
        }
        return;
      }

      await _completeDeliveryWithUser(userId, userName);
    } catch (e, stackTrace) {
      print('=== UI Layer: Complete Delivery Error ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Error'),
              ],
            ),
            content: Text('Failed to complete delivery: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _completeDelivery();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text('Retry'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _completeDeliveryWithUser(int userId, String userName) async {
    print('=== UI Layer: Complete Delivery Debug ===');
    print('Request ID type: ${widget.requisition.id.runtimeType}');
    print('Request ID value: ${widget.requisition.id}');
    print('User ID: $userId');
    print('User Name: $userName');
    print('Is Vault Delivery: $_isVaultDelivery');
    print('Is Bank Details Expanded: $_isBankDetailsExpanded');

    // Ensure requestId is a string
    final requestId = widget.requisition.id.toString();
    print('Parsed Request ID type: ${requestId.runtimeType}');
    print('Parsed Request ID value: $requestId');

    final deliveryData = {
      'requestId': requestId,
      'status': 'completed',
      'completedById': userId,
      'completedByName': userName,
      'sealNumber': _sealNumberController.text.trim(),
      'photoUrl': _imageUrl,
      'latitude': _currentPosition?.latitude,
      'longitude': _currentPosition?.longitude,
      'locationHistory': _locationHistory
          .map((pos) => {
                'latitude': pos.latitude,
                'longitude': pos.longitude,
                'timestamp': pos.timestamp?.toIso8601String(),
              })
          .toList(),
      'notes': _notesController.text.trim(),
      'isVaultDelivery': _isVaultDelivery,
      'receivingOfficerName': _receivingOfficerNameController.text.trim(),
      'receivingOfficerId':
          int.tryParse(_receivingOfficerIdController.text.trim()),
      if (_isVaultDelivery && _isBankDetailsExpanded) ...{
        'bankDetails': {
          'bankName': _bankNameController.text.trim(),
          'bankAddress': _bankAddressController.text.trim(),
          'receivingOfficerId':
              int.tryParse(_receivingOfficerIdController.text.trim()),
          'receivingOfficerName': _receivingOfficerNameController.text.trim(),
          'receivingOfficerPhone': _receivingOfficerPhoneController.text.trim(),
        },
      },
    };

    print('Delivery Data: $deliveryData');

    // Stop location tracking before completing delivery
    await _locationService.stopTracking();

    try {
      if (_isVaultDelivery) {
        print('Calling completeVaultDelivery...');
        await _requisitionsService.completeVaultDelivery(
          requestId,
          isVaultDelivery: true,
          photoUrl: deliveryData['photoUrl'] as String?,
          bankDetails: deliveryData['bankDetails'] as Map<String, dynamic>?,
          latitude: deliveryData['latitude'] as double?,
          longitude: deliveryData['longitude'] as double?,
          notes: deliveryData['notes'] as String?,
        );
      } else {
        print('Calling completeRequisition...');
        await _requisitionsService.completeRequisition(
          requestId,
          photoUrl: deliveryData['photoUrl'] as String?,
          bankDetails: deliveryData['bankDetails'] as Map<String, dynamic>?,
          latitude: deliveryData['latitude'] as double?,
          longitude: deliveryData['longitude'] as double?,
          notes: deliveryData['notes'] as String?,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e, stackTrace) {
      print('=== UI Layer: Complete Delivery Error ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete delivery: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
