import 'package:get/get.dart';
import 'package:kwt/core/services/auth_service.dart';
import 'package:kwt/app/routes/app_routes.dart';
import 'package:kwt/core/utils/device_identifier.dart';

class AuthController extends GetxController {
  var isLoading = false.obs;

  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      final res = await AuthService.signIn(email, password);
      final user = AuthService.currentUser;

      if (user != null) {
        // ✅ Device authorization check
        final deviceId = await DeviceIdentifier.getId();
        final isAuthorized = await AuthService.isDeviceAuthorized(deviceId);

        if (!isAuthorized) {
          Get.snackbar('Access Denied', 'This device is not authorized.');
          await AuthService.signOut();
          return;
        }

        Get.offAllNamed(AppRoutes.home);
      } else {
        Get.snackbar('Login Failed', 'Invalid credentials.');
      }
    } catch (e) {
      Get.snackbar('Login Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await AuthService.signOut();
    Get.offAllNamed(AppRoutes.login);
  }
}
