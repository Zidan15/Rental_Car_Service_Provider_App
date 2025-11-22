import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 1. ADD THIS IMPORT
import 'package:fleetwise/theme.dart';
import 'package:fleetwise/screens/login_screen.dart';

Future<void> main() async { // 2. MODIFY THIS LINE (to add async)

  // 3. ADD THESE 3 LINES
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    // Get these from your Supabase Project: Settings > API
    url: 'https://ojmzdmtpxdoaisvtefln.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qbXpkbXRweGRvYWlzdnRlZmxuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMwMTg1NTQsImV4cCI6MjA3ODU5NDU1NH0.YPU2PxWMo_9gPKuH23WaO1RVjMsQZLi8By00b4iA3rM',
  );

  runApp(const MyApp());
}

// 4. ADD THIS HELPER to access Supabase from other files
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RENT.GOA for Service Providers',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      themeMode: ThemeMode.light,
      home: const LoginScreen(),
    );
  }
}