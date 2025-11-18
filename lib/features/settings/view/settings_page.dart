import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kwt/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:kwt/widgets/list_tiles/settings_menu_tile.dart';
import 'package:kwt/widgets/list_tiles/user_profile_tile.dart';
import 'package:kwt/widgets/texts/section_heading.dart';
import 'package:kwt/core/constants/app_sizes.dart';
import 'package:kwt/app/theme/colors.dart';
import 'package:kwt/features/settings/view/add_item_page.dart';
import 'package:kwt/features/settings/view/registered_customers_page.dart';
import 'package:kwt/features/settings/view/salesmen_page.dart';
import 'package:kwt/features/settings/view/notifications_page.dart';
import '../../../widgets/custom_appbar/appbar.dart';
import '../controller/download_barcodes_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// 🟢 Header
            PrimaryHeaderContainer(
              child: Column(
                children: [

                  SAppBar(
                    title: Text(
                      "Admin Account",
                      style: Theme.of(context).textTheme.headlineMedium!.apply(color: SColors.white),
                    ),
                  ),

                  UserProfileTile(onPressed: (){},),
                  const SizedBox(height: SSizes.spaceBtwSections),
                ],
              ),
            ),

            /// 🟢 Body
            Padding(
              padding: const EdgeInsets.all(SSizes.defaultSpace),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeading(
                    title: "Store Tabs",
                    showActionButton: false,
                  ),
                  const SizedBox(height: SSizes.spaceBtwItems),

                  /// MENU ITEMS
                  SettingsMenuTile(
                    icon: Iconsax.shopping_cart,
                    title: "Add New Item",
                    subTitle: "Add new item in store",
                    onTap: () => Get.to(() => AddItemPage()),
                  ),
                  SettingsMenuTile(
                    icon: Iconsax.bank,
                    title: "Registered Customers",
                    subTitle:
                    "Registered customers and their pending dues",
                    onTap: () => Get.to(() => const RegisteredCustomersPage()),
                  ),
                  const SettingsMenuTile(
                    icon: Iconsax.trash,
                    title: "Remove Item",
                    subTitle: "Remove item from store",
                  ),
                  SettingsMenuTile(
                    icon: Iconsax.people,
                    title: "Sales Men",
                    subTitle: "Handle application access",
                    onTap: () => Get.to(() => const SalesmenPage()),
                  ),
                  SettingsMenuTile(
                    icon: Iconsax.notification,
                    title: "Notifications",
                    subTitle: "Set any kind of notification message",
                    onTap: () => Get.to(() => const NotificationsPage()),
                  ),
                  const SettingsMenuTile(
                    icon: Iconsax.security_card,
                    title: "Account Privacy",
                    subTitle: "Manage data usage and connected accounts",
                  ),
                  SettingsMenuTile(
                    icon: Iconsax.barcode,
                    title: "Download Barcode",
                    subTitle: "Download all product barcodes to your phone",
                    onTap: () => Get.to(() => const DownloadBarcodesPage()),
                  ),

                  const SizedBox(height: SSizes.spaceBtwSections),

                  /// ⚙️ App Settings
                  const SectionHeading(
                    title: "App Settings",
                    showActionButton: false,
                  ),
                  const SizedBox(height: SSizes.spaceBtwItems),
                  SettingsMenuTile(
                    icon: Iconsax.location,
                    title: "Dark Theme",
                    subTitle: "Turn on/off to switch theme",
                    trailing: Switch(
                      value: dark,
                      onChanged: (value) {
                        Get.changeThemeMode(
                            value ? ThemeMode.dark : ThemeMode.light);
                      },
                      activeColor: SColors.dark,              // thumb color when ON
                      activeTrackColor: SColors.darkGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SSizes.spaceBtwSections * 2),
          ],
        ),
      ),
    );
  }
}
