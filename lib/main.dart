import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  final prefs = await SharedPreferences.getInstance();

  final hasSeenOnboarding =
      prefs.getBool('has_seen_onboarding') ?? false;

  
  final session =
      Supabase.instance.client.auth.currentSession;

  runApp(
    PupCheckApp(
      hasSeenOnboarding: hasSeenOnboarding,
      isLoggedIn: session != null,
    ),
  );
}

class PupCheckApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  final bool isLoggedIn;

  const PupCheckApp({
    super.key,
    required this.hasSeenOnboarding,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PupCheck',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),

      initialRoute: !hasSeenOnboarding
          ? '/onboarding'
          : isLoggedIn
              ? '/home'
              : '/login',

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
        '/onboarding': (context) => const OnboardingScreen(),
      },
    );
  }
}