import 'package:flutter/material.dart';
import 'package:fleetwise/theme.dart';
import 'package:fleetwise/screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

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
