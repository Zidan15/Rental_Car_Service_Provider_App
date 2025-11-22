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
      rethrow; 
    }
  }

  // Sign Up (Updated to only handle auth)
  Future<void> signUp(String email, String password, String fullName, String company, String contactNumber) async {
    try {
      // 1. Create the user in the auth system
      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'company': company,
          'contact_number': contactNumber,
        }
      );

      // 2. IMMEDIATELY create the profile in the public.profiles table
      // This bridges the gap between auth.users and public.profiles
      final User? user = res.user;
      if (user != null) {
        // We try to insert. If it fails (e.g. RLS issue because user not logged in yet),
        // we catch it silently so we don't block the signup flow.
        // The fallback in getCurrentUser will handle it later.
        try {
          await supabase.from('profiles').insert({
            'id': user.id,
            'full_name': fullName,
            'company': company,
            'contact_number': contactNumber,
          });
        } catch (insertError) {
          print('Error inserting profile immediately: $insertError');
        }
      }
    } catch (e) {
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
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }
      final String userId = user.id;
      
      // Use maybeSingle() to avoid PGRST116
      Map<String, dynamic>? userData = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      // If profile is missing, create it from metadata
      if (userData == null) {
        await createProfileIfMissing();
        // Retry fetching
        userData = await supabase
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
      }

      // Return data or a fallback object
      return userData ?? {
        'id': userId,
        'full_name': user.userMetadata?['full_name'] ?? '',
        'company': user.userMetadata?['company'] ?? '',
        'contact_number': user.userMetadata?['contact_number'] ?? '',
      };
    } catch (e) {
      rethrow;
    }
  }

  // Update User Profile
  Future<void> updateUserProfile(String fullName, String company, String contactNumber) async {
    try {
      final String userId = supabase.auth.currentUser!.id;
      // Use upsert to create the record if it doesn't exist, or update it if it does.
      await supabase.from('profiles').upsert({
        'id': userId,
        'full_name': fullName,
        'company': company,
        'contact_number': contactNumber,
      });
    } catch (e) {
      rethrow;
    }
  }
}