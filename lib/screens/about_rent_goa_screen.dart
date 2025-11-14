// lib/screens/about_rent_goa_screen.dart

import 'package:flutter/material.dart';

class AboutRentGoaScreen extends StatelessWidget {
  const AboutRentGoaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About RENT.GOA'),
        // Adds a back button
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 60, color: Colors.blue),
            const SizedBox(height: 20),
            Text(
              'RENT.GOA Service Provider App',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Version 1.0.0 (Build 20251114)',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            const Text(
              'RENT.GOA is dedicated to providing efficient vehicle management services for our partners in Goa. Our goal is to ensure safety, compliance, and optimized fleet operations.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),
            Text(
              'Contact Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 5),
            const Text('Email: support@rentgoa.com'),
          ],
        ),
      ),
    );
  }
}