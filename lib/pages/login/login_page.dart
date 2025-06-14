import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:bm_security/services/api_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:bm_security/controllers/auth_controller.dart';
import 'package:get_storage/get_storage.dart';
import '../../components/loading_spinner.dart';
import 'package:bm_security/services/location_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthController _authController = Get.find<AuthController>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showToast(String message, bool isError) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: isError ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: isError ? 3 : 1,
      backgroundColor: isError ? Colors.red : Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.login(
        _phoneNumberController.text.trim(),
        _passwordController.text,
      );

      if (result['success']) {
        _authController.isAuthenticated = true;

        // Initialize location service with auto backup
        try {
          debugPrint('🚀 Initializing location service with auto backup');
          final locationService = LocationService();
          final initialized = await locationService.initializeWithAutoBackup();
          if (initialized) {
            debugPrint('✅ Location service initialized successfully');
          } else {
            debugPrint('⚠️ Location service initialization failed');
          }
        } catch (e) {
          debugPrint('⚠️ Could not initialize location service: $e');
        }

        Get.offAllNamed('/home');
        _showToast('Login successful', false);
      } else {
        _showToast(result['message'] ?? 'Login failed', true);
      }
    } catch (e) {
      _showToast(e.toString(), true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Center(
                  child: Container(
                      height: 120,
                      width: 120,
                      margin: const EdgeInsets.only(bottom: 40),
                      child: Image.asset('assets/bm.png', fit: BoxFit.contain)),
                ),

                // Welcome Text
                const Text(
                  'BM Security',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE21923),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                const Text(
                  'Sign in to continue',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF00568F),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Login Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email Field
                      _buildPhoneNumberField(),

                      const SizedBox(height: 20),

                      // Password Field
                      _buildPasswordField(),

                      const SizedBox(height: 12),

                      // Forgot Password
                      _buildForgotPasswordButton(),

                      const SizedBox(height: 24),

                      // Login Button
                      _buildLoginButton(),

                      const SizedBox(height: 24),

                      // Don't have an account
                      _buildSignUpRow(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneNumberField() {
    return TextFormField(
      controller: _phoneNumberController,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: 'Employee No',
        hintText: 'employee No',
        prefixIcon: const Icon(Icons.badge_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your employee number';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          Get.toNamed('/forgot-password');
        },
        child: const Text(
          'Forgot Password?',
          style: TextStyle(
            color: Color(0xFFE21923),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE21923),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: LoadingSpinner.button(),
              )
            : const Text(
                'SIGN IN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildSignUpRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account? ",
          style: TextStyle(
            color: Color(0xFF666666),
          ),
        ),
        GestureDetector(
          onTap: () {
            Get.toNamed('/register');
          },
          child: const Text(
            'Contact Us',
            style: TextStyle(
              color: Color(0xFFE21923),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
