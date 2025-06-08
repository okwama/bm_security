import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bm_security/pages/404/noConnection_page.dart';
import 'package:bm_security/pages/home/home_page.dart';
import 'package:bm_security/pages/login/login_page.dart';
import 'package:get_storage/get_storage.dart';
import 'package:bm_security/services/api_service.dart';
import 'package:bm_security/controllers/auth_controller.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

// Custom color scheme
const Color primaryBlack = Color.fromARGB(255, 34, 56, 150);
const Color secondaryGrey = Color.fromARGB(255, 0, 0, 0);
const Color accentGrey = Color.fromARGB(255, 43, 53, 60);
const Color lightGrey = Color.fromARGB(255, 95, 59, 59);
const Color backgroundColor = Color(0xFFF5F5F5);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsBinding.instance);

  await GetStorage.init(); // Initialize local storage
  Get.put(AuthController()); // Inject your controller
  FlutterNativeSplash.remove();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BM Security',
      theme: ThemeData(
        primaryColor: primaryBlack,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: const ColorScheme.light(
          primary: primaryBlack,
          secondary: secondaryGrey,
          surface: Colors.white,
          error: Colors.red,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color.fromARGB(255, 0, 0, 0),
          onError: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryBlack,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlack,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryBlack,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: lightGrey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: lightGrey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primaryBlack),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.quicksandTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home:
          Obx(() => authController.isLoggedIn.value ? HomePage() : LoginPage()),
      getPages: [
        GetPage(name: '/login', page: () => LoginPage()),
        GetPage(name: '/home', page: () => HomePage()),
        GetPage(name: '/no_connection', page: () => const NoConnectionPage()),
      ],
    );
  }
}
