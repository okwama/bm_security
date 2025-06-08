import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_storage/get_storage.dart';
import 'package:bm_security/services/api_service.dart';
import 'package:bm_security/services/profile_service.dart';
import 'package:bm_security/models/staff.dart';

class ProfileController extends GetxController {
  final storage = GetStorage();
  final _profileService = ProfileService();

  Rx<XFile?> selectedImage = Rx<XFile?>(null);
  RxBool isLoading = false.obs;
  Rx<Staff?> profile = Rx<Staff?>(null);

  // Password update fields
  final RxBool isPasswordUpdating = false.obs;
  final RxString passwordError = ''.obs;
  final RxString passwordSuccess = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
    fetchProfile();
  }

  void loadUserData() {
    final userData = storage.read('user');
    print('Loading user data from storage: $userData'); // Debug log
    if (userData != null) {
      try {
        profile.value = Staff.fromJson(userData);
        print(
            'Successfully loaded profile from storage: ${profile.value?.toJson()}'); // Debug log
      } catch (e) {
        print('Error parsing stored user data: $e'); // Debug log
      }
    } else {
      print('No user data found in storage'); // Debug log
    }
  }

  Future<void> fetchProfile() async {
    try {
      print('Fetching profile from API...'); // Debug log
      final response = await _profileService.getProfile();
      print('API Response: $response'); // Debug log

      try {
        profile.value = Staff.fromJson(response);
        print(
            'Successfully parsed profile data: ${profile.value?.toJson()}'); // Debug log
        // Update storage with full user data
        storage.write('user', response);
        print('Updated storage with profile data'); // Debug log
      } catch (e) {
        print('Error parsing API response: $e'); // Debug log
        print('Raw response data: $response'); // Debug log
        throw Exception('Failed to parse profile data: $e');
      }
    } catch (e) {
      print('Error fetching profile: $e'); // Debug log
      Get.snackbar(
        'Error',
        'Failed to fetch profile data: ${e.toString().replaceAll('Exception: ', '')}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
      );
    }
  }

  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        selectedImage.value = image;
        await updateProfilePhoto();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  Future<void> updateProfilePhoto() async {
    if (selectedImage.value == null) return;

    try {
      isLoading.value = true;

      // Pass XFile directly to handle both web and mobile platforms
      final photoUrl =
          await _profileService.updateProfilePhoto(selectedImage.value!);

      // Update profile with new photo URL
      if (profile.value != null) {
        profile.value = profile.value!.copyWith(photoUrl: photoUrl);
      }

      // Update storage
      final storedUser =
          storage.read('salesRep') as Map<String, dynamic>? ?? {};
      storedUser['photoUrl'] = photoUrl;
      storage.write('salesRep', storedUser);

      Get.snackbar(
        'Success',
        'Profile photo updated successfully',
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      // Reset status messages
      passwordError.value = '';
      passwordSuccess.value = '';
      isPasswordUpdating.value = true;

      print('PROFILE CONTROLLER: Starting password update process');

      // Validate passwords
      if (currentPassword.isEmpty ||
          newPassword.isEmpty ||
          confirmPassword.isEmpty) {
        passwordError.value = 'All fields are required';
        print('PROFILE CONTROLLER: Validation failed - Empty fields');
        return;
      }

      if (newPassword != confirmPassword) {
        passwordError.value = 'New passwords do not match';
        print('PROFILE CONTROLLER: Validation failed - Passwords do not match');
        return;
      }

      if (newPassword.length < 8) {
        passwordError.value = 'Password must be at least 8 characters long';
        print('PROFILE CONTROLLER: Validation failed - Password too short');
        return;
      }

      print('PROFILE CONTROLLER: Validation passed, calling API service');

      // Call API to update password
      final result = await _profileService.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      print('PROFILE CONTROLLER: API response received: $result');

      if (result['success']) {
        passwordSuccess.value = result['message'];
        print('PROFILE CONTROLLER: Password update successful');
      } else {
        passwordError.value = result['message'];
        print(
            'PROFILE CONTROLLER: Password update failed: ${result['message']}');
      }
    } catch (e) {
      print('PROFILE CONTROLLER: Exception during password update: $e');
      passwordError.value = 'An error occurred: ${e.toString()}';
    } finally {
      isPasswordUpdating.value = false;
      print('PROFILE CONTROLLER: Password update process completed');
    }
  }
}
