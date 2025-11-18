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

  // Sign Up (Updated to only handle auth)
  Future<void> signUp(String email, String password, String fullName, String company, String contactNumber) async {
    try {
      // Only create the user in the auth system. Profile is created after email verification.
      await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'company': company,
          'contact_number': contactNumber,
        }
      );
    } catch (e) {
      // Re-throw the error to be caught in the UI
      rethrow;
    }
  }

  // Create Profile if it doesn't exist
  Future<void> createProfileIfMissing() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        return; // No user logged in
      }

      // Check if a profile already exists
      final existingProfile = await supabase
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      // If no profile, create one
      if (existingProfile == null) {
        // Extract metadata that we temporarily stored during sign-up
        final fullName = user.userMetadata?['full_name'] ?? 'N/A';
        final company = user.userMetadata?['company'] ?? 'N/A';
        final contactNumber = user.userMetadata?['contact_number'] ?? 'N/A';

        await supabase.from('profiles').insert({
          'id': user.id,
          'full_name': fullName,
          'company': company,
          'contact_number': contactNumber,
        });
      }
    } catch (e) {
      // It's better to log this error than to re-throw it,
      // as this function is a background task and shouldn't block the UI.
      // Consider using a logging framework in a real app.
      print('Error in createProfileIfMissing: $e');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // Get Current User Profile
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final String userId = supabase.auth.currentUser!.id;
      final Map<String, dynamic> userData = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return userData;
    } catch (e) {
      rethrow;
    }
  }
}