import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import 'supabase_service.dart';
import 'package:kwt/core/utils/device_identifier.dart';

class AuthService {
  static SupabaseClient get _client => SupabaseService.client;

  static User? get currentUser => _client.auth.currentUser;

  // ============================================================
  // LOGIN (Safe)
  // ============================================================
  static Future<AuthResponse> signIn(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (res.user == null) {
        throw Exception("Invalid login credentials");
      }

      // --------------------------------------------------------
      // 🔔 Trigger NEW LOGIN notification
      // --------------------------------------------------------
      try {
        await _client.functions.invoke(
          "generate_notifications",
          body: {
            "type": "new_login",
            "payload": {"user_id": res.user!.id},
          },
        );
      } catch (_) {}

      return res;
    } catch (e) {
      Get.snackbar("Error", "❌ AuthService.signIn ERROR: $e");
      rethrow;
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================
  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      Get.snackbar("Error", "❌ AuthService.signOut ERROR: $e");
    }
  }

  // ============================================================
  // CHECK ADMIN (owner)
  // ============================================================
  static Future<bool> isAdmin() async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final data = await _client
          .from("user_profiles")
          .select("role")
          .eq("id", user.id)
          .maybeSingle();

      return data?["role"] == "owner";
    } catch (e) {
      Get.snackbar("Error", "❌ AuthService.isAdmin ERROR: $e");
      return false;
    }
  }

  // ============================================================
  // DEVICE AUTHORIZATION (updated logic + new edge API)
  // ============================================================
  static Future<bool> verifyDeviceWithEdge(String userId) async {
    final profile = await fetchCurrentUserProfile();

    if (profile == null) {
      return true; // Invalid profile → let RLS handle it
    }

    // ------------------------------------------------------------
    // 1️⃣ SALESPERSON ALWAYS ALLOWED
    // ------------------------------------------------------------
    if (profile.role == "salesperson") {
      try {
        final deviceUid = await DeviceIdentifier.getId();
        final deviceName = await DeviceIdentifier.getName();

        // Only register, NOT enforce authorization
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
        Get.snackbar(
            "Error", "⚠️ Salesperson device register ERROR: $e");
      }

      return true;
    }

    // ------------------------------------------------------------
    // 2️⃣ OWNER MUST BE AUTHORIZED
    // ------------------------------------------------------------
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

      // Owner is allowed only if edge function returned authorized = true
      return data?["is_authorized"] == true;
    } catch (e) {
      Get.snackbar("Error", "❌ Owner device check failed: $e");
      return false; // Owners must be blocked if check fails
    }
  }

  // ============================================================
  // FETCH CURRENT USER PROFILE
  // ============================================================
  static Future<UserProfile?> fetchCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final res = await _client
          .from("user_profiles")
          .select()
          .eq("id", user.id)
          .maybeSingle();

      if (res == null || res is! Map) return null;

      return UserProfile.fromMap(res);
    } catch (e) {
      Get.snackbar("Error", "❌ fetchCurrentUserProfile ERROR: $e");
      return null;
    }
  }
}
