import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kwt/app/theme/colors.dart';
import '../../core/utils/mobile_number_formatter.dart';

class AddSalesPersonPage extends StatefulWidget {
  const AddSalesPersonPage({super.key});

  @override
  State<AddSalesPersonPage> createState() => _AddSalesPersonPageState();
}

class _AddSalesPersonPageState extends State<AddSalesPersonPage> {
  final _client = Supabase.instance.client;

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();

  bool isSaving = false;

  Future<void> _save() async {
    final name = nameCtrl.text.trim();
    final rawPhone = phoneCtrl.text.trim();
    final password = passwordCtrl.text.trim();

    // BASIC VALIDATIONS
    if (name.isEmpty || rawPhone.isEmpty || password.length < 6) {
      Get.snackbar(
        "Invalid Input",
        "Name, Phone aur kam az kam 6 characters ka password required hai.",
      );
      return;
    }

    // CLEAN PHONE (REMOVE ALL NON-DIGITS)
    final phone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');

    if (phone.length < 10) {
      Get.snackbar("Invalid Phone", "Phone number sahi format me nahi hai.");
      return;
    }

    // FIXED EMAIL FORMAT: MUST START WITH LETTER
    final email = "sp_$phone@salesperson.kwt.com";

    setState(() => isSaving = true);

    try {
      // 1) Create Supabase Auth user
      final authRes = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (authRes.user == null) {
        throw Exception("Failed to create salesperson authentication account");
      }

      final uid = authRes.user!.id;

      // 2) Insert into user_profiles
      await _client.from("user_profiles").insert({
        "id": uid,
        "full_name": name,
        "phone": phone,
        "role": "salesperson",
        "is_admin": false,
        "is_active": true,
      });

      Get.back(result: true);

      Get.snackbar(
        "Success",
        "Salesperson added successfully!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Sales Person"),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Phone Number"),
              inputFormatters: [MobileNumberFormatter()],
            ),
            const SizedBox(height: 10),

            TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password (min 6 characters)",
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
