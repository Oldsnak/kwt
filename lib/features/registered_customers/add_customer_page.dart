import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kwt/widgets/custom_shapes/containers/glossy_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme/colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/mobile_number_formatter.dart';

class AddCustomerPage extends StatefulWidget {
  const AddCustomerPage({super.key});

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final SupabaseClient client = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();

  bool saving = false;

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => saving = true);

    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final address = addressCtrl.text.trim();

    try {
      final inserted = await client.from("customers").insert({
        'name': name,
        'phone': phone.isEmpty ? null : phone,
        'address': address,
      }).select().single();

      Get.snackbar("Success", "Customer Registered Successfully!",
          snackPosition: SnackPosition.BOTTOM);

      Navigator.pop(context, inserted);
    } catch (e) {
      Get.snackbar("Error", "Failed to register customer: $e");
    }

    setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final dark = SHelperFunctions.isDarkMode(context);

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text("Register Customer"),
      //   backgroundColor: SColors.primary,
      //   foregroundColor: Colors.white,
      // ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(SSizes.defaultSpace),
          child: GlossyContainer(
            child: Form(
              key: _formKey,
              child: Column(
                children: [

                  // SizedBox(height: SHelperFunctions.screenHeight()/3.5,),
                  // CUSTOMER NAME
                  TextFormField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: "Customer Name",
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Name is required";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: SSizes.spaceBtwItems),

                  // MOBILE NUMBER
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      MobileNumberFormatter(),
                    ],
                    decoration: const InputDecoration(
                      labelText: "Mobile Number (Optional)",
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),


                  const SizedBox(height: SSizes.spaceBtwItems),

                  // ADDRESS
                  TextFormField(
                    controller: addressCtrl,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Address",
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Address is required";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 40),

                  // BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving ? null : _saveCustomer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: saving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        "Register Customer",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
