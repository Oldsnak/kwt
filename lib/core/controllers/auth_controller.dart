import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

class AuthController extends GetxController {
  final SupabaseClient _client = Supabase.instance.client;

  Rx<UserProfile?> userProfile = Rx<UserProfile?>(null);
  RxBool isLoading = false.obs;

  bool get isOwner => userProfile.value?.role == 'owner';
  bool get isSalesperson => userProfile.value?.role == 'salesperson';
  bool get isActive => userProfile.value?.isActive ?? false;

  // ---------------------------------------------------------------------------
  // LOGIN FLOW
  // ---------------------------------------------------------------------------
  Future<void> signIn(String email, String password) async {
    try {
      isLoading.value = true;

      // 1) SIGN IN
      final res = await AuthService.signIn(email, password);
      if (res.session == null || res.user == null) {
        Get.snackbar('Error', 'Invalid login credentials');
        return;
      }

      final user = res.user!;

      // 2) FETCH USER PROFILE (VERY IMPORTANT)
      final profile = await AuthService.fetchCurrentUserProfile();
      if (profile == null) {
        Get.snackbar('Error', 'No profile found for this user');
        await AuthService.signOut();
        return;
      }

      userProfile.value = profile;

      // 3) ACTIVE STATUS CHECK
      if (!isActive) {
        Get.snackbar('Access Denied', 'Your account has been disabled.');
        await AuthService.signOut();
        return;
      }

      // 4) DEVICE AUTHORIZATION
      final ok = await AuthService.verifyDeviceWithEdge(user.id);

      // OWNER → MUST BE AUTHORIZED
      if (isOwner && !ok) {
        Get.snackbar(
          'Device Not Authorized',
          'Please approve this device first.',
        );
        await AuthService.signOut();
        return;
      }

      // SALESPERSON → ALWAYS ALLOWED (no blocking)

      // 5) NAVIGATE
      _navigateByRole();

    } catch (e) {
      Get.snackbar('Login Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // SESSION RESTORE ON APP START
  // ---------------------------------------------------------------------------
  Future<void> loadExistingSession() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      Get.offAllNamed('/login');
      return;
    }

    // ALWAYS fetch profile fresh (fixes wrong role issue)
    final profile = await AuthService.fetchCurrentUserProfile();

    if (profile == null) {
      await AuthService.signOut();
      Get.offAllNamed('/login');
      return;
    }

    userProfile.value = profile;

    if (!isActive) {
      await AuthService.signOut();
      Get.offAllNamed('/login');
      return;
    }

    // DEVICE CHECK (owner strict)
    final ok = await AuthService.verifyDeviceWithEdge(user.id);

    if (isOwner && !ok) {
      await AuthService.signOut();
      Get.offAllNamed('/login');
      return;
    }

    // CORRECT ROLE NAVIGATION
    _navigateByRole();
  }

  // ---------------------------------------------------------------------------
  // ROLE-BASED ROUTING
  // ---------------------------------------------------------------------------
  void _navigateByRole() {
    if (isOwner) {
      Get.offAllNamed('/home');   // Owner → 4 tabs
    } else if (isSalesperson) {
      Get.offAllNamed('/home');   // Salesperson → 2 tabs
    } else {
      Get.snackbar('Error', 'Unknown role');
      AuthService.signOut();
    }
  }
}
