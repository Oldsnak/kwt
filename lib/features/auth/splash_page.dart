// lib/features/auth/splash_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kwt/app/routes/app_routes.dart';
import 'package:kwt/core/services/supabase_service.dart';
import 'package:kwt/core/services/auth_service.dart';
import 'package:kwt/core/controllers/auth_controller.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      _checkSession();
    });
  }

  Future<void> _checkSession() async {
    final user = SupabaseService.currentUser;

    if (user != null) {
      // ✅ Logged-in user exists → profile reload karo
      final profile = await AuthService.fetchCurrentUserProfile();

      // AuthController me profile set karo
      final auth = Get.find<AuthController>();
      auth.setUserProfile(profile);

      // ✅ Ab role sahi set ho chuka → Home pe jao
      Get.offAllNamed(AppRoutes.home);
    } else {
      // No session → Login
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
