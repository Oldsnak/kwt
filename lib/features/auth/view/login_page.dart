import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:kwt/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:kwt/widgets/login_signup/login_form.dart';
import 'package:kwt/widgets/login_signup/formDivider.dart';
import 'package:kwt/core/constants/app_sizes.dart';
import 'package:kwt/core/constants/app_images.dart';
import 'package:kwt/core/utils/device_utility.dart';
import 'package:kwt/features/auth/controller/auth_controller.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.put(AuthController());

    return Scaffold(
      body: GestureDetector(
        onTap: () => SDeviceUtils.hideKeyboard(context),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ===== Top curved / header area =====
              PrimaryHeaderContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: SSizes.appBarHeight),
                    const SizedBox(width: double.infinity),
                    Padding(
                      padding: const EdgeInsets.only(left: SSizes.defaultSpace),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // App logo
                          SizedBox(
                            height: 70,
                            child: Image.asset(SImages.darkAppLogo), // adjust if different
                          ),
                          const SizedBox(height: SSizes.spaceBtwItems),

                          Text(
                            'Welcome back 👋',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: SSizes.spaceBtwItems / 2),
                          Text(
                            'Login to manage your store, stock & billing.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: SSizes.spaceBtwSections),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ===== Body card area =====
              Padding(
                padding: const EdgeInsets.all(SSizes.defaultSpace),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Your old styled login form widget
                    LoginForm(),

                    const SizedBox(height: SSizes.spaceBtwSections),

                    const FormDivider(dividerText: 'or continue with'),

                    const SizedBox(height: SSizes.spaceBtwItems),

                    // (Optional) social buttons row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.facebook_outlined),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.g_mobiledata),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
