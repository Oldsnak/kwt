import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'package:kwt/core/utils/device_identifier.dart';

class AuthService {
  static SupabaseClient get _client => SupabaseService.client;

  static User? get currentUser => _client.auth.currentUser;

  /// LOGIN
  static Future<AuthResponse?> signIn(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user == null) throw Exception("Invalid login credentials.");

      // verify device after successful login
      await _verifyDevice(res.user!.id);

      return res;
    } catch (e) {
      print("AuthService.signIn error: $e");
      rethrow;
    }
  }

  /// LOGOUT
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// CHECK IF USER IS ADMIN (from user_profiles)
  static Future<bool> isAdmin() async {
    final user = currentUser;
    if (user == null) return false;

    final data = await _client
        .from('user_profiles')
        .select('is_admin')
        .eq('id', user.id)
        .maybeSingle();

    return (data?['is_admin'] ?? false) as bool;
  }

  /// DEVICE AUTHORIZATION CHECK (NEW VERSION)
  /// Reads from `devices` table
  static Future<bool> isDeviceAuthorized(String deviceUid) async {
    final user = currentUser;
    if (user == null) return false;

    final res = await _client
        .from('devices')
        .select()
        .eq('user_id', user.id)
        .eq('device_uid', deviceUid)
        .eq('is_authorized', true)
        .maybeSingle();

    return res != null;
  }

  /// VERIFY DEVICE OR REGISTER NEW DEVICE (NEW VERSION)
  /// Writes into `devices` table
  static Future<void> _verifyDevice(String userId) async {
    final deviceUid = await DeviceIdentifier.getId();
    final deviceName = await DeviceIdentifier.getName();

    // check if device entry exists
    final existing = await _client
        .from('devices')
        .select()
        .eq('user_id', userId)
        .eq('device_uid', deviceUid)
        .maybeSingle();

    if (existing == null) {
      // register new device as authorized
      await _client.from('devices').insert({
        'user_id': userId,
        'device_uid': deviceUid,
        'device_name': deviceName,
        'is_authorized': true,
      });
    } else {
      // if exists but unauthorized
      if (existing['is_authorized'] == false) {
        throw Exception("This device is not authorized.");
      }
    }
  }
}
