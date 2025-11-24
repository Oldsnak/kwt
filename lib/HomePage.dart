import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kwt/features/sales_bill/sales_bill_page.dart';
import 'package:kwt/features/settings/view/settings_page.dart';
import 'package:kwt/features/dashboard/dashboard_page.dart';
import 'package:kwt/app/theme/colors.dart';
import 'package:kwt/core/utils/helpers.dart';
import 'core/controllers/auth_controller.dart';
import 'features/sell_product/sell_page.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthController auth = Get.find<AuthController>();

  // OWNER → Full access
  late final List<Widget> ownerScreens = [
    DashboardPage(),
    SellPage(),
    SalesBillPage(),
    SettingsPage(),
  ];

  // SALESPERSON → Only Sell + Bills
  late final List<Widget> salesScreens = [
    SellPage(),
    SalesBillPage(),   // <-- Added here
  ];

  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final bool dark = SHelperFunctions.isDarkMode(context);

    final bool isSales = auth.isSalesperson;

    final List<Widget> screens =
    isSales ? salesScreens : ownerScreens;

    return Scaffold(
      body: IndexedStack(
        index: currentPage,
        children: screens,
      ),

      extendBody: true,

      bottomNavigationBar: CurvedNavigationBar(
        index: currentPage,
        onTap: (index) {
          setState(() => currentPage = index);
        },
        backgroundColor: Colors.transparent,
        color: dark ? SColors.darkSecondary : SColors.primary,
        animationDuration: Duration(milliseconds: 300),

        items: isSales
          ? [
            Icon(Icons.shopping_cart, color: dark ? SColors.primary : SColors.white),
            Icon(Icons.receipt, color: dark ? SColors.primary : SColors.white),
          ]
          : [
            Icon(Iconsax.shop, color: dark ? SColors.primary : SColors.white),
            Icon(Icons.shopping_cart, color: dark ? SColors.primary : SColors.white),
            Icon(Icons.receipt, color: dark ? SColors.primary : SColors.white),
            Icon(Icons.person, color: dark ? SColors.primary : SColors.white),
        ],
      ),
    );
  }
}
