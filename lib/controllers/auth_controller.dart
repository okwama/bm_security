import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../services/http/auth_service.dart';
import 'package:bm_security/services/location_service.dart';

class AuthController extends GetxController {
  final _storage = GetStorage();
  final _authService = AuthService();

  final _isAuthenticated = false.obs;
  bool get isAuthenticated => _isAuthenticated.value;
  set isAuthenticated(bool value) => _isAuthenticated.value = value;

  @override
  void onInit() {
    super.onInit();
    checkAuthState();
  }

  Future<void> checkAuthState() async {
    try {
      final token = _storage.read('token');
      if (token != null) {
        // Verify token validity
        final isValid = await _authService.verifyToken();
        _isAuthenticated.value = isValid;

        if (isValid) {
          // Initialize location service with auto backup for already authenticated users
          try {
            print(
                '🚀 Initializing location service with auto backup for existing session...');
            final locationService = LocationService();
            final initialized =
                await locationService.initializeWithAutoBackup();
            if (initialized) {
              print('✅ Location service initialized successfully');
            } else {
              print('⚠️ Location service initialization failed');
            }
          } catch (e) {
            print('⚠️ Warning: Could not initialize location service: $e');
            // Don't fail auth check if location service fails
          }

          Get.offAllNamed('/home');
        } else {
          await logout();
        }
      } else {
        _isAuthenticated.value = false;
        Get.offAllNamed('/login');
      }
    } catch (e) {
      print('Error checking auth state: $e');
      _isAuthenticated.value = false;
      Get.offAllNamed('/login');
    }
  }

  Future<void> login(String username, String password) async {
    try {
      final response = await _authService.login(username, password);
      if (response != null) {
        _isAuthenticated.value = true;

        // Start location auto backup system after successful login
        try {
          print('🚀 Initializing location auto backup system...');
          await LocationService().startAutoBackupSystem();
          print('✅ Location auto backup system started');
        } catch (e) {
          print('⚠️ Warning: Could not start location auto backup: $e');
          // Don't fail login if location service fails
        }

        Get.offAllNamed('/home');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      // Stop location services before logout
      try {
        print('🛑 Stopping location services...');
        await LocationService().stopAllLocationServices();
        print('✅ Location services stopped');
      } catch (e) {
        print('⚠️ Warning: Could not stop location services: $e');
      }

      await _authService.logout();
      _isAuthenticated.value = false;
      _storage.erase();
      Get.offAllNamed('/login');
    } catch (e) {
      print('Error during logout: $e');
      // Force logout even if there's an error
      _isAuthenticated.value = false;
      _storage.erase();
      Get.offAllNamed('/login');
    }
  }
}
