import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class ProfileActionButtons extends StatelessWidget {
  final VoidCallback onEditProfile;
  final VoidCallback onChangePassword;
  final VoidCallback onUploadPhoto;

  const ProfileActionButtons({
    super.key,
    required this.onEditProfile,
    required this.onChangePassword,
    required this.onUploadPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Edit Profile Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onEditProfile,
              icon: const Icon(Icons.edit, size: 20),
              label: const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppConstants.primaryColorValue),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Change Password Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onChangePassword,
              icon: const Icon(Icons.lock, size: 20),
              label: const Text(
                'Change Password',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(AppConstants.primaryColorValue),
                side: const BorderSide(
                  color: Color(AppConstants.primaryColorValue),
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Upload Photo Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onUploadPhoto,
              icon: const Icon(Icons.camera_alt, size: 20),
              label: const Text(
                'Upload Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(AppConstants.primaryColorValue),
                side: const BorderSide(
                  color: Color(AppConstants.primaryColorValue),
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
