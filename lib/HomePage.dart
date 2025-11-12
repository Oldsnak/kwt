import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kwt/features/sales_bill/view/sales_bill_page.dart';
import 'package:kwt/features/sell_product/view/sell_page.dart';
import 'package:kwt/features/settings/view/settings_page.dart';
import 'app/theme/colors.dart';
import 'core/utils/helpers.dart';
import 'features/dashboard/view/dashboard_page.dart';


class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  int current_page=0;
  List<Widget> screens=[
    DashboardPage(),
    SellPage(),
    SalesBillPage(),
    SettingsPage(),
  ];
  @override
  Widget build(BuildContext context) {
    final bool dark = SHelperFunctions.isDarkMode(context);
    // return WillPopScope(
    //   onWillPop: () async => false,
    //   child: Scaffold(
    //     // your existing code
    //   ),
    // );

    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: current_page,
        children:screens,
      ),



      extendBody: true,
      bottomNavigationBar: CurvedNavigationBar(
        onTap: (index){
          setState(() {
            current_page=index;
          });
        },
        backgroundColor: Colors.transparent,
        // color: Colors.grey.shade900,
        color: dark ? SColors.darkSecondary : SColors.primary,
        animationDuration: Duration(milliseconds: 300),
        items: [
          Icon(Iconsax.shop, color: dark ? SColors.primary : SColors.white),
          Icon(Icons.shopping_cart, color: dark ? SColors.primary : SColors.white,),
          Icon(Icons.receipt, color: dark ? SColors.primary : SColors.white),
          Icon(Icons.person, color: dark ? SColors.primary : SColors.white),
        ],
      ),
    );
  }
}
