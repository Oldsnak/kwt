import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import 'supabase_service.dart';
import 'package:kwt/core/utils/device_identifier.dart';

class AuthService {
  static SupabaseClient get _client => SupabaseService.client;

  static User? get currentUser => _client.auth.currentUser;

  // ----------------------------------------------------------
  // LOGIN
  // ----------------------------------------------------------
  static Future<AuthResponse> signIn(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user == null) {
        throw Exception("Invalid login credentials.");
      }

      return res;
    } catch (e) {
      print("AuthService.signIn error: $e");
      rethrow;
    }
  }

  // ----------------------------------------------------------
  // LOGOUT
  // ----------------------------------------------------------
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ----------------------------------------------------------
  // CHECK ADMIN FLAG
  // ----------------------------------------------------------
  static Future<bool> isAdmin() async {
    final user = currentUser;
    if (user == null) return false;

    final data = await _client
        .from("user_profiles")
        .select("is_admin")
        .eq("id", user.id)
        .maybeSingle();

    return (data?["is_admin"] ?? false) as bool;
  }

  // ----------------------------------------------------------
  // DEVICE AUTHORIZATION — Owner strict, Salesperson always allowed
  // ----------------------------------------------------------
  static Future<bool> verifyDeviceWithEdge(String userId) async {
    // Current user ka profile nikaal lo
    final profile = await fetchCurrentUserProfile();
    if (profile == null) {
      // Agar profile hi nahi mila to device ke basis pe block mat karo
      return true;
    }

    // ------------------------------------------
    // SALESPERSON → ALWAYS ALLOW (never block)
    // ------------------------------------------
    if (profile.role == 'salesperson') {
      try {
        final deviceUid = await DeviceIdentifier.getId();
        final deviceName = await DeviceIdentifier.getName();

        // Sirf notification / device register ke liye call
        await _client.functions.invoke(
          "device_authorization",
          body: {
            "action": "register_device",
            "payload": {
              "device_uid": deviceUid,
              "device_name": deviceName,
              "user_id": userId,
            },
          },
        );
      } catch (e) {
        print("verifyDeviceWithEdge salesperson error: $e");
      }

      // Hamesha allow
      return true;
    }

    // ------------------------------------------
    // OWNER → strict device check
    // ------------------------------------------
    try {
      final deviceUid = await DeviceIdentifier.getId();
      final deviceName = await DeviceIdentifier.getName();

      final result = await _client.functions.invoke(
        "device_authorization",
        body: {
          "action": "register_device",
          "payload": {
            "device_uid": deviceUid,
            "device_name": deviceName,
            "user_id": userId,
          },
        },
      );

      final data = result.data;

      // Owner ke liye device authorized hona zaroori hai
      return data?['is_authorized'] == true;
    } catch (e) {
      print("verifyDeviceWithEdge owner error: $e");
      return false;
    }
  }

  // ----------------------------------------------------------
  // FETCH USER PROFILE — SAFE VERSION
  // ----------------------------------------------------------
  static Future<UserProfile?> fetchCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final res = await _client
          .from("user_profiles")
          .select()
          .eq("id", user.id)
          .maybeSingle();

      if (res == null) return null;

      if (res is! Map) {
        print("Profile is not Map: $res");
        return null;
      }

      return UserProfile.fromMap(res);
    } catch (e) {
      print("fetchCurrentUserProfile error: $e");
      return null;
    }
  }
}
