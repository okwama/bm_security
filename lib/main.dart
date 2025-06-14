import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:bm_security/pages/login/login_page.dart';
import 'package:bm_security/pages/home/home_page.dart';
import 'package:bm_security/pages/debug_location_page.dart';
import 'package:bm_security/controllers/auth_controller.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'BM Security',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color.fromARGB(255, 12, 90, 153),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.quicksandTextTheme(
          Theme.of(context).textTheme,
        ),
        // Apply Quicksand to specific text styles
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: GoogleFonts.quicksand(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: GoogleFonts.quicksand(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      defaultTransition: Transition.fade,
      initialRoute: '/login',
      getPages: [
        GetPage(
          name: '/login',
          page: () => const LoginPage(),
          transition: Transition.fade,
        ),
        GetPage(
          name: '/home',
          page: () => const HomePage(),
          transition: Transition.fade,
        ),
        GetPage(
          name: '/debug-location',
          page: () => const DebugLocationPage(),
          transition: Transition.fade,
        ),
      ],
      initialBinding: BindingsBuilder(() {
        Get.put(AuthController());
      }),
    );
  }
}

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();

    // If not authenticated and trying to access protected route
    if (!authController.isAuthenticated && route != '/login') {
      return const RouteSettings(name: '/login');
    }

    // If authenticated and trying to access login
    if (authController.isAuthenticated && route == '/login') {
      return const RouteSettings(name: '/home');
    }

    return null;
  }
}
