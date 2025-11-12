import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  // Auth
  static Future<AuthResponse?> signIn(String email, String password) async {
    try {
      final res = await client.auth.signInWithPassword(email: email, password: password);
      return res;
    } catch (e) {
      print('Supabase Login Error: $e');
      rethrow;
    }
  }


  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static User? get currentUser => client.auth.currentUser;
}
