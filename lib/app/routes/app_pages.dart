import 'package:get/get.dart';
import 'package:kwt/features/auth/view/login_page.dart';
import 'package:kwt/features/auth/view/splash_page.dart';
import 'package:kwt/features/dashboard/view/dashboard_page.dart';
import 'package:kwt/features/sell_product/view/sell_page.dart';
import 'package:kwt/features/sell_product/view/checkout_page.dart';
import 'package:kwt/features/sales_bill/view/sales_bill_page.dart';
import 'package:kwt/features/settings/view/settings_page.dart';
import 'package:kwt/features/settings/view/add_item_page.dart';
import 'package:kwt/features/settings/view/notifications_page.dart';
import 'package:kwt/features/settings/view/salesmen_page.dart';
import 'package:kwt/features/settings/view/registered_customers_page.dart';
import '../../HomePage.dart';
import 'app_routes.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(name: AppRoutes.splash, page: () => const SplashPage()),
    GetPage(name: AppRoutes.login, page: () => const LoginPage()),


    GetPage(name: AppRoutes.home, page: () => HomePage()),
    GetPage(name: AppRoutes.splash, page: () => const SplashPage()),
    GetPage(name: AppRoutes.login, page: () => const LoginPage()),
    GetPage(name: AppRoutes.dashboard, page: () => DashboardPage()),
    GetPage(name: AppRoutes.sell, page: () => const SellPage()),
    GetPage(name: AppRoutes.checkout, page: () => const CheckoutPage()),
    GetPage(name: AppRoutes.salesBill, page: () => const SalesBillPage()),
    GetPage(name: AppRoutes.settings, page: () => const SettingsPage()),
    GetPage(name: AppRoutes.addItem, page: () => const AddItemPage()),
    GetPage(name: AppRoutes.notifications, page: () => const NotificationsPage()),
    GetPage(name: AppRoutes.salesmen, page: () => const SalesmenPage()),
    GetPage(name: AppRoutes.registeredCustomers, page: () => const RegisteredCustomersPage()),
  ];
}
