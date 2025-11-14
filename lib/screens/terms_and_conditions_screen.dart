// lib/screens/terms_and_conditions_screen.dart

import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
        // Adds a back button
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'General Terms',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            const Text(
              'These terms govern your use of the RENT.GOA Service Provider App. By using the app, you agree to these terms. (Placeholder content)',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Text(
              'Vehicle Usage',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            const Text(
              'All vehicles must be operated in accordance with local traffic laws. Unauthorized use of vehicle data is prohibited. (Placeholder content)',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}