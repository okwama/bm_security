import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundColorValue),
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: const Color(AppConstants.errorColorValue),
                ),
              );
            } else if (state is AuthTokenExpired) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: const Color(AppConstants.errorColorValue),
                  duration: const Duration(seconds: 5),
                ),
              );
            } else if (state is AuthAuthenticated) {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          },
          child: const LoginForm(),
        ),
      ),
    );
  }
}
