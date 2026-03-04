import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fleetwise/theme.dart';
import 'package:fleetwise/screens/login_screen.dart';
import 'package:fleetwise/screens/main_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ojmzdmtpxdoaisvtefln.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qbXpkbXRweGRvYWlzdnRlZmxuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMwMTg1NTQsImV4cCI6MjA3ODU5NDU1NH0.YPU2PxWMo_9gPKuH23WaO1RVjMsQZLi8By00b4iA3rM',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user is already logged in
    final session = supabase.auth.currentSession;

    return MaterialApp(
      title: 'RENT.GOA for Service Providers',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      themeMode: ThemeMode.light,
      home: session != null ? const MainNavigation() : const LoginScreen(),
    );
  }
}