import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fleetwise/theme.dart';
import 'package:fleetwise/screens/login_screen.dart';
import 'package:fleetwise/screens/main_navigation.dart';

import 'package:fleetwise/services/env_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();

  await Supabase.initialize(
    url: Env.supabaseUrl, 
    anonKey: Env.supabaseAnonKey,
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