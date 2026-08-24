import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/env.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/analyze_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/results_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/vets_screen.dart';
import 'screens/vet_details_screen.dart';
import 'screens/reset_password_screen.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );
  runApp(const PupCheckApp());
}

class PupCheckApp extends StatelessWidget {
  const PupCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PupCheck',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/analyze': (context) => const AnalyzeScreen(),
        '/scan': (context) => const ScanScreen(),
        '/results': (context) => const ResultsScreen(),
        '/history': (context) => const HistoryScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/vets': (context) => const VetsScreen(),
        '/vet-details': (context) => const VetDetailsScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
      },
    );
  }
}
