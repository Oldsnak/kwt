import 'package:get/get.dart';

import '../../features/registered_customers/registered_customers_page.dart';
import '../../features/sell_product/sell_page.dart';
import 'app_routes.dart';

// Auth & Splash
import 'package:kwt/features/auth/login_page.dart';
import 'package:kwt/features/auth/splash_page.dart';

// Dashboard / Home
import 'package:kwt/features/dashboard/dashboard_page.dart';
import '../../HomePage.dart';

// Sales
import 'package:kwt/features/sales_bill/sales_bill_page.dart';

// Settings
import 'package:kwt/features/settings/view/settings_page.dart';
import 'package:kwt/features/settings/view/add_item_page.dart';
import 'package:kwt/features/settings/view/notifications_page.dart';
import 'package:kwt/features/settings/view/remove_items_page.dart';

// Salesperson Management
import 'package:kwt/features/salesperson/salesperson_list_page.dart';
import 'package:kwt/features/salesperson/add_salesperson_page.dart';

// Registered Customers

class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = <GetPage>[
    // Splash + Login
    GetPage(name: AppRoutes.splash, page: () => const SplashPage()),
    GetPage(name: AppRoutes.login, page: () => const LoginPage()),

    // Home / Dashboard / Sell
    GetPage(name: AppRoutes.home, page: () => HomePage()),
    GetPage(name: AppRoutes.dashboard, page: () => DashboardPage()),
    GetPage(name: AppRoutes.sell, page: () => SellPage()),

    // Sales Bills
    GetPage(name: AppRoutes.salesBill, page: () => const SalesBillPage()),

    // Settings
    GetPage(name: AppRoutes.settings, page: () => const SettingsPage()),
    GetPage(name: AppRoutes.addItem, page: () => AddItemPage()),
    GetPage(name: AppRoutes.notifications, page: () => const NotificationsPage()),
    GetPage(name: AppRoutes.removeItems, page: () => const RemoveItemsPage()),

    // Salesperson Management
    GetPage(name: AppRoutes.salesmen, page: () => const SalesPersonListPage()),
    GetPage(name: AppRoutes.addSalesmen, page: () => const AddSalesPersonPage()),

    // Registered Customers
    GetPage(name: AppRoutes.registeredCustomers, page: () => const RegisteredCustomersPage()),
  ];
}
