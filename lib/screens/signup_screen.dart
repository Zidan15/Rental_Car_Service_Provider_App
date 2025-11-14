// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _companyController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // ✅ FIX: Initialize text via controller instead of initialValue to prevent assertion error
    _companyController.text = 'RENT.GOA Admin'; 
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _companyController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitSignUp() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! Please log in.'),
          duration: Duration(seconds: 2),
        ),
      );
      // Navigate back to the login screen
      Navigator.of(context).pop(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CREATE ACCOUNT'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 16.0, bottom: 32.0),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.black12,
                  child: Icon(Icons.person, size: 40, color: Colors.black54),
                ),
              ),
            ),

            Text(
              'Personal Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Full Name
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            
            // Company/Role
            TextFormField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: 'Company/Role',
                prefixIcon: Icon(Icons.business_outlined),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Contact Number
            TextFormField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: 'Contact Number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) => value == null || value.length < 10 ? 'Enter valid number' : null,
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 30),

            Text(
              'Security',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Password
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) => value == null || value.length < 6 ? 'Password must be 6+ chars' : null,
            ),
            const SizedBox(height: 16),

            // Confirm Password
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscurePassword,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),

            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _submitSignUp,
                child: const Text('CREATE ACCOUNT'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}