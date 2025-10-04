import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_info_card.dart';
import '../widgets/profile_action_buttons.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(const GetProfileEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(AppConstants.primaryColorValue),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ProfileBloc>().add(const RefreshProfileEvent());
            },
          ),
        ],
      ),
      body: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is ProfileUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is PasswordChanged) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password changed successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const LoadingWidget(message: 'Loading profile...');
            } else if (state is ProfileError) {
              return ProfileErrorWidget(
                message: state.message,
                onRetry: () {
                  context.read<ProfileBloc>().add(const GetProfileEvent());
                },
              );
            } else if (state is ProfileLoaded || state is ProfileUpdated) {
              final user = state is ProfileLoaded ? state.user : (state as ProfileUpdated).user;
              return _buildProfileContent(context, user);
            }

            return const LoadingWidget(message: 'Loading profile...');
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, user) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Header
          ProfileHeader(user: user),
          
          const SizedBox(height: 16),
          
          // Profile Information
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ProfileInfoCard(
                  icon: Icons.person,
                  label: 'Name',
                  value: user.name,
                ),
                const SizedBox(height: 8),
                ProfileInfoCard(
                  icon: Icons.badge,
                  label: 'Employee Number',
                  value: user.employeeNumber,
                ),
                const SizedBox(height: 8),
                ProfileInfoCard(
                  icon: Icons.phone,
                  label: 'Phone',
                  value: user.phone.isNotEmpty ? user.phone : 'Not provided',
                ),
                const SizedBox(height: 8),
                ProfileInfoCard(
                  icon: Icons.work,
                  label: 'Role',
                  value: user.role,
                ),
                const SizedBox(height: 8),
                ProfileInfoCard(
                  icon: Icons.fingerprint,
                  label: 'ID Number',
                  value: user.idNumber?.toString() ?? 'Not provided',
                ),
                if (user.teamName != null) ...[
                  const SizedBox(height: 8),
                  ProfileInfoCard(
                    icon: Icons.group,
                    label: 'Team',
                    value: user.teamName!,
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action Buttons
          ProfileActionButtons(
            onEditProfile: () {
              _showEditProfileDialog(context, user);
            },
            onChangePassword: () {
              _showChangePasswordDialog(context);
            },
            onUploadPhoto: () {
              // TODO: Implement photo upload
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Photo upload - Coming soon'),
                  backgroundColor: Color(AppConstants.primaryColorValue),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, user) {
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ProfileBloc>().add(UpdateProfileEvent(
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
              ));
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              context.read<ProfileBloc>().add(ChangePasswordEvent(
                currentPassword: currentPasswordController.text,
                newPassword: newPasswordController.text,
              ));
              Navigator.pop(context);
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }
}
