import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'package:kwt/core/utils/device_identifier.dart';

class AuthService {
  static SupabaseClient get _client => SupabaseService.client;

  static User? get currentUser => _client.auth.currentUser;

  /// ✅ User login
  static Future<AuthResponse?> signIn(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = res.user;
      if (user == null) throw Exception('Login failed');

      await _verifyDevice(user.id);
      return res;
    } catch (e) {
      print('AuthService.signIn error: $e');
      rethrow;
    }
  }

  /// ✅ Logout
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// ✅ Check admin role (reads from user_profiles table)
  static Future<bool> isAdmin() async {
    final user = currentUser;
    if (user == null) return false;

    final res = await _client
        .from('user_profiles')
        .select('is_admin')
        .eq('id', user.id)
        .maybeSingle();

    return (res?['is_admin'] ?? false) as bool;
  }

  /// ✅ Device authorization check
  static Future<bool> isDeviceAuthorized(String deviceUid) async {
    final user = currentUser;
    if (user == null) return false;

    final resp = await _client
        .from('authorized_devices')
        .select()
        .eq('user_id', user.id)
        .eq('device_id', deviceUid)
        .maybeSingle();

    if (resp == null) return false;
    return (resp['is_active'] ?? false) as bool;
  }

  /// ✅ Internal: register device if not found
  static Future<void> _verifyDevice(String userId) async {
    final deviceId = await DeviceIdentifier.getId();
    final deviceName = await DeviceIdentifier.getName();

    final existing = await _client
        .from('authorized_devices')
        .select()
        .eq('user_id', userId)
        .eq('device_id', deviceId)
        .maybeSingle();

    if (existing == null) {
      await _client.from('authorized_devices').insert({
        'user_id': userId,
        'device_id': deviceId,
        'device_name': deviceName,
        'is_active': true,
      });
    } else if (!(existing['is_active'] ?? true)) {
      throw Exception('Device not authorized.');
    }
  }
}
