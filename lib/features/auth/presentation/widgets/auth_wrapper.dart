import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../pages/login_page.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../../services/http/auth_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authService = AuthService();
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
  }

  Future<void> _checkAuthenticationStatus() async {
    try {
      
      // First check if user has a valid token locally
      final isAuthenticated = await _authService.isAuthenticated();
      
      if (isAuthenticated) {
        
        // Check if token needs refresh and attempt refresh if needed
        final refreshSuccess = await _authService.refreshTokenIfNeeded();
        
        if (refreshSuccess) {
          // Verify token with server by getting current user
          if (mounted) {
            context.read<AuthBloc>().add(const GetCurrentUserEvent());
          }
        } else {
          // Clear any invalid cached data
          await _authService.cleartoken();
        }
      } else {
        // Clear any invalid cached data
        await _authService.cleartoken();
      }
    } catch (e) {
      // Clear auth data on error to ensure clean state
      await _authService.cleartoken();
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return const HomePage();
        } else if (state is AuthLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Verifying authentication...'),
                ],
              ),
            ),
          );
        } else if (state is AuthError) {
          // Handle authentication errors (e.g., expired token)
          return const LoginPage();
        } else if (state is AuthTokenExpired) {
          // Handle token expiration
          return const LoginPage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
