// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:fleetwise/services/user_service.dart'; // 1. IMPORT USER SERVICE
import 'package:supabase_flutter/supabase_flutter.dart'; // 2. IMPORT SUPABASE

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
  bool _isLoading = false; // 3. ADD LOADING STATE

  @override
  void initState() {
    super.initState();
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

  // 4. THIS IS THE NEW, UPDATED SIGNUP FUNCTION
  Future<void> _submitSignUp() async {
    // First, validate the form
    if (!_formKey.currentState!.validate()) {
      return; // If form is invalid, do nothing
    }
    
    if (_isLoading) return; // Prevent multiple taps

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    final userService = UserService();

    try {
      // Call the sign up function with all controllers
      await userService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _fullNameController.text.trim(),
        _companyController.text.trim(),
        _contactController.text.trim(),
      );

      // If successful, show success message and pop back to login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Please check your email to verify.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Go back to LoginScreen
      }

    } on AuthException catch (e) {
      // Handle errors (e.g., user already exists)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      // Handle other unexpected errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('An unexpected error occurred.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }

    // Stop loading
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
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
            // ... (Your UI code remains unchanged) ...
            
            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _submitSignUp, // Calls the real function
                // Show loading spinner
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                    : const Text('CREATE ACCOUNT'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}