// lib/services/user_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fleetwise/main.dart'; // Import main.dart to get the 'supabase' helper

class UserService {

  // Sign In
  Future<void> signIn(String email, String password) async {
    try {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      // Re-throw the error to be caught in the UI
      rethrow; 
    }
  }

  // Sign Up (Updated to include all form fields)
  Future<void> signUp(String email, String password, String fullName, String company, String contactNumber) async {
    try {
      // First, create the user in the auth system
      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      // If sign up is successful, create their profile
      if (res.user != null) {
        await supabase.from('profiles').insert({
          'id': res.user!.id,
          'full_name': fullName,
          'company': company,
          'contact_number': contactNumber,
        });
      }
    } catch (e) {
      // Re-throw the error to be caught in the UI
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}