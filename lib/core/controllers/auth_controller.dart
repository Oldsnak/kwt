// lib/core/controllers/auth_controller.dart

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

class AuthController extends GetxController {
  // Supabase client
  final SupabaseClient _client = Supabase.instance.client;

  // Observable user profile
  final Rxn<UserProfile> userProfile = Rxn<UserProfile>();
  final RxBool isLoading = false.obs;

  // -----------------------------
  // ROLE CHECKS
  // -----------------------------
  bool get isOwner => userProfile.value?.role == 'owner';
  bool get isSalesperson => userProfile.value?.role == 'salesperson';
  bool get isActive => userProfile.value?.isActive ?? false;

  // ============================================================
  // SET PROFILE (used by SplashPage and Login)
  // ============================================================
  void setUserProfile(UserProfile? p) {
    userProfile.value = p;
  }

  // ============================================================
  // SIGN-IN
  // ============================================================
  Future<bool> signIn(String email, String password) async {
    try {
      isLoading.value = true;

      // 1) AUTH LOGIN
      final res = await AuthService.signIn(email, password);
      if (res.user == null) {
        Get.snackbar("Login Failed", "Invalid credentials");
        return false;
      }

      final user = res.user!;

      // 2) FETCH USER PROFILE
      final profile = await AuthService.fetchCurrentUserProfile();
      if (profile == null) {
        Get.snackbar("Error", "User profile missing");
        await AuthService.signOut();
        return false;
      }

      setUserProfile(profile);

      // 3) ACCOUNT ACTIVE CHECK
      if (!isActive) {
        Get.snackbar("Access Denied", "Your account has been disabled.");
        await AuthService.signOut();
        return false;
      }

      // 4) DEVICE AUTH CHECK
      final allowed = await AuthService.verifyDeviceWithEdge(user.id);

      if (isOwner && !allowed) {
        Get.snackbar(
          "Device Not Authorized",
          "Please approve this device from the owner dashboard.",
        );
        await AuthService.signOut();
        return false;
      }

      return true;
    } catch (e) {
      Get.snackbar("Login Error", e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // SESSION RESTORE
  // ============================================================
  Future<bool> loadExistingSession() async {
    final user = _client.auth.currentUser;

    if (user == null) return false;

    try {
      // Always fetch latest profile (role change support)
      final profile = await AuthService.fetchCurrentUserProfile();
      if (profile == null) {
        await AuthService.signOut();
        return false;
      }

      setUserProfile(profile);

      if (!isActive) {
        await AuthService.signOut();
        return false;
      }

      // Strict check for owner
      final allowed = await AuthService.verifyDeviceWithEdge(user.id);

      if (isOwner && !allowed) {
        await AuthService.signOut();
        return false;
      }

      return true;

    } catch (e) {
      await AuthService.signOut();
      return false;
    }
  }
}
