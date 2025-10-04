import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

// Core
import 'core/di/injection_container.dart' as di;
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';

// Features
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/requests/presentation/bloc/requests_bloc.dart';
import 'features/sos/presentation/bloc/sos_bloc.dart';
import 'features/cash_count/presentation/bloc/cash_count_bloc.dart';
import 'features/teams/presentation/bloc/teams_bloc.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'features/auth/presentation/widgets/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection
  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => di.sl<AuthBloc>(),
        ),
        BlocProvider<RequestsBloc>(
          create: (context) => di.sl<RequestsBloc>(),
        ),
        BlocProvider<SOSBloc>(
          create: (context) => di.sl<SOSBloc>(),
        ),
        BlocProvider<CashCountBloc>(
          create: (context) => di.sl<CashCountBloc>(),
        ),
        BlocProvider<TeamsBloc>(
          create: (context) => di.sl<TeamsBloc>(),
        ),
        BlocProvider<ProfileBloc>(
          create: (context) => di.sl<ProfileBloc>(),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/home': (context) => const HomePage(),
        },
      ),
    );
  }
}
