import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'core/controllers/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Load the .env file first
  await dotenv.load(fileName: ".env");

  // print("✅ SUPABASE_URL: ${dotenv.env['SUPABASE_URL']}");
  // print("✅ SUPABASE_ANON_KEY: ${dotenv.env['SUPABASE_ANON_KEY']?.substring(0, 10)}...");

  // ✅ Initialize Supabase with values from .env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  Get.put(AuthController(), permanent: true);

  runApp(MyApp());
}
