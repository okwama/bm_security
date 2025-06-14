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
import '../../../components/loading_spinner.dart';

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
        imageQuality: 80, // Optimized for performance
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _imageUrl = null; // Reset URL until uploaded
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

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    try {
      // Convert File to XFile for upload
      final xFile = XFile(_imageFile!.path);
      final imageUrl = await _requisitionsService.uploadImage(xFile);

      if (mounted) {
        setState(() {
          _imageUrl = imageUrl;
        });
      }

      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Location permissions are permanently denied. Please enable in settings.');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      throw Exception('Failed to get current location: $e');
    }
  }

  bool _validateDeliveryForm() {
    // Basic form validation
    if (_formKey.currentState?.validate() != true) {
      _showErrorSnackBar('Please fill all required fields');
      return false;
    }

    // Vault delivery specific validations
    if (_isVaultDelivery && _isBankDetailsExpanded) {
      if (_bankNameController.text.trim().isEmpty ||
          _bankAddressController.text.trim().isEmpty ||
          _receivingOfficerIdController.text.trim().isEmpty ||
          _receivingOfficerNameController.text.trim().isEmpty) {
        _showErrorSnackBar('Please fill all bank details');
        return false;
      }
    }

    return true;
  }

  Future<void> _prepareDeliveryData() async {
    print('=== Preparing Delivery Data ===');

    // Step 1: Get current location
    await _getCurrentLocation();
    if (_currentPosition == null) {
      throw Exception(
          'Unable to get current location. Please ensure GPS is enabled.');
    }
    print(
        'Location obtained: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
  }

  Future<Map<String, dynamic>?> _validateUserAuthentication() async {
    final userId = _storage.read('user_id');
    final userName = _storage.read('user_name');

    if (userId != null && userName != null) {
      return {'userId': userId, 'userName': userName};
    }

    // Try to refresh token
    try {
      print('Refreshing authentication token...');
      final authService = AuthService();
      await authService.refreshAccessToken();

      final newUserId = _storage.read('user_id');
      final newUserName = _storage.read('user_name');

      if (newUserId != null && newUserName != null) {
        return {'userId': newUserId, 'userName': newUserName};
      }
    } catch (e) {
      print('Token refresh failed: $e');
    }

    // Show session expired dialog
    if (mounted) {
      await _showSessionExpiredDialog();
    }
    return null;
  }

  Map<String, dynamic>? _buildBankDetails() {
    if (_isVaultDelivery && _isBankDetailsExpanded) {
      return {
        'bankName': _bankNameController.text.trim(),
        'bankAddress': _bankAddressController.text.trim(),
        'receivingOfficerId':
            int.tryParse(_receivingOfficerIdController.text.trim()),
        'receivingOfficerName': _receivingOfficerNameController.text.trim(),
        'receivingOfficerPhone': _receivingOfficerPhoneController.text.trim(),
      };
    }
    return null;
  }

  Future<void> _handleDeliverySuccess() async {
    print('=== Delivery Completed Successfully ===');

    if (mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Delivery completed successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      // Navigate back with success result
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _handleDeliveryError(dynamic error) async {
    String errorMessage = 'Failed to complete delivery';
    bool showRetry = true;

    if (error.toString().contains('location')) {
      errorMessage = 'Location error: ${error.toString()}';
      showRetry = true;
    } else if (error.toString().contains('upload')) {
      errorMessage = 'Image upload failed: ${error.toString()}';
      showRetry = true;
    } else if (error.toString().contains('network') ||
        error.toString().contains('connection')) {
      errorMessage = 'Network error. Please check your connection.';
      showRetry = true;
    } else {
      errorMessage = error.toString();
    }

    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Delivery Error'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(errorMessage),
              SizedBox(height: 8),
              Text(
                'Please try again or contact support if the problem persists.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            if (showRetry)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _completeDelivery(); // Retry
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
  }

  Future<void> _showSessionExpiredDialog() async {
    return showDialog(
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
        content:
            Text('Your session has expired. Please login again to continue.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.of(context).pop(); // Close delivery screen
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/login', (route) => false);
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

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final primaryColorLight = primaryColor.withOpacity(0.1);
    final primaryColorMedium = primaryColor.withOpacity(0.2);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: primaryColor,
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
              // Status Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColorLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColorMedium),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColorMedium,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.local_shipping,
                          color: primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery in Progress',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Complete the delivery details below',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_isVaultDelivery) ...[
                _buildBankDetailsButton(
                    primaryColor, primaryColorLight, primaryColorMedium),
                const SizedBox(height: 16),
              ],
              _buildNotesField(),
              const SizedBox(height: 24),
              _buildCompleteButton(primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankDetailsButton(
      Color primaryColor, Color primaryColorLight, Color primaryColorMedium) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryColorLight, primaryColor]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColorMedium),
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
                    color: primaryColorMedium,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.account_balance,
                      color: primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add Bank Details',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: primaryColor, size: 16),
              ],
            ),
          ),
        ),
      ),
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

  Widget _buildCompleteButton(Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _completeDelivery,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
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
                child: LoadingSpinner.button(),
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
    print('=== Starting Delivery Completion Process ===');
    print('Service Type: ${widget.requisition.serviceType}');
    print('Is Vault Delivery: $_isVaultDelivery');
    print(
        'Current Position: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');

    // Check if location is available
    if (_currentPosition == null) {
      try {
        // Try to get current location if not available
        await _getCurrentLocation();
        if (_currentPosition == null) {
          _showErrorSnackBar(
              'Unable to get location. Please ensure GPS is enabled and try again.');
          return;
        }
      } catch (e) {
        _showErrorSnackBar('Location error: ${e.toString()}');
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await _requisitionsService.confirmDelivery(
        widget.requisition.id.toString(),
        bankDetails: _isVaultDelivery ? _buildBankDetails() : null,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        notes: _notesController.text.trim(),
      );

      print('Delivery completion response: ${response.toJson()}');
      await _handleDeliverySuccess();
    } catch (e) {
      print('=== Delivery Completion Error ===');
      print('Error: $e');
      await _handleDeliveryError(e);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
