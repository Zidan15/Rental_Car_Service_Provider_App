import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 1. ADD THIS IMPORT
import 'package:fleetwise/theme.dart';
import 'package:fleetwise/screens/login_screen.dart';

Future<void> main() async { // 2. MODIFY THIS LINE (to add async)

  // 3. ADD THESE 3 LINES
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    // Get these from your Supabase Project: Settings > API
    url: 'YOUR_SUPABASE_URL', 
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
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