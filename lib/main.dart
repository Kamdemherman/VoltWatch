import 'package:flutter/material.dart';
import 'package:voltwatch/theme.dart';
import 'package:voltwatch/supabase/supabase_config.dart';
import 'package:voltwatch/services/auth_service.dart';
import 'package:voltwatch/screens/auth/login_screen.dart';
import 'package:voltwatch/screens/dashboard/dashboard_screen.dart';
import 'package:intl/date_symbol_data_local.dart'; // Ajoutez ceci

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ajoutez cette ligne pour initialiser la locale (ex: 'fr_FR')
  await initializeDateFormatting('fr_FR', null);

  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    print('Error initializing Supabase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VoltWatch - Suivi de consommation électrique',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.authStateStream,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check if user is authenticated
        final isAuthenticated = AuthService.isAuthenticated;
        
        if (isAuthenticated) {
          return const DashboardScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
