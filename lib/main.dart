// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/controllers/auth_controller.dart';
import 'core/controllers/product_scan_controller.dart';
import 'core/controllers/sell_controller.dart';
import 'core/services/product_scan_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Load the .env file first
  await dotenv.load(fileName: ".env");

  // ✅ Initialize Supabase with values from .env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // ✅ Register AuthController globally
  Get.put(AuthController(), permanent: true);
  Get.put(ProductScanController(), permanent: true);
  Get.put(SellController(), permanent: true);
  Get.lazyPut<ProductScanService>(() => ProductScanService(), fenix: true);


  print(Supabase.instance.client.auth.currentUser?.id);
  print(Supabase.instance.client.auth.currentUser?.email);

  runApp(const MyApp());
}
