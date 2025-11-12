import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../features/auth/controller/auth_controller.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final authController = Get.put(AuthController());

  bool _isObscure = true;
  bool _rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: SSizes.spaceBtwSections),
        child: Column(
          children: [
            // Email
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email_rounded),
                labelText: STexts.email,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                return null;
              },
            ),
            const SizedBox(height: SSizes.spaceBtwInputFields),

            // Password
            TextFormField(
              controller: _passwordController,
              obscureText: _isObscure,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.security),
                labelText: STexts.password,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() {
                    _isObscure = !_isObscure;
                  }),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),
            const SizedBox(height: SSizes.spaceBtwInputFields / 2),

            // Remember Me + Forgot Password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() => _rememberMe = value ?? false);
                      },
                    ),
                    const Text(STexts.rememberMe),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Get.snackbar('Info', 'Password recovery coming soon');
                  },
                  child: const Text(STexts.forgetPassword),
                ),
              ],
            ),

            const SizedBox(height: SSizes.spaceBtwSections),

            // 🔘 Sign In Button
            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: authController.isLoading.value
                    ? null
                    : () async {
                  if (_formKey.currentState!.validate()) {
                    await authController.login(
                      _emailController.text.trim(),
                      _passwordController.text.trim(),
                    );
                  }
                },
                child: authController.isLoading.value
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                )
                    : const Text(STexts.signIn),
              ),
            )),

            const SizedBox(height: SSizes.spaceBtwItems),

            // Outlined Create Account
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Get.snackbar('Notice', 'Signup not enabled yet');
                },
                child: const Text(STexts.createAccount),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
