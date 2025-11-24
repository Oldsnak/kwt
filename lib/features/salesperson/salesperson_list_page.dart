import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kwt/app/theme/colors.dart';
import 'add_salesperson_page.dart';

class SalesPersonListPage extends StatefulWidget {
  const SalesPersonListPage({super.key});

  @override
  State<SalesPersonListPage> createState() => _SalesPersonListPageState();
}

class _SalesPersonListPageState extends State<SalesPersonListPage> {
  final _client = Supabase.instance.client;

  List<dynamic> salespersons = [];
  List<dynamic> filtered = [];

  final TextEditingController searchCtrl = TextEditingController();

  // -----------------------------------------
  // LOAD SALESPERSONS
  // -----------------------------------------
  Future<void> _load() async {
    try {
      final res = await _client
          .from("user_profiles")
          .select()
          .eq("role", "salesperson")
          .order("created_at", ascending: false);

      setState(() {
        salespersons = res;
        filtered = res;
      });
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  // -----------------------------------------
  // BLOCK SALESPERSON
  // -----------------------------------------
  Future<void> _block(String id) async {
    try {
      await _client
          .from("user_profiles")
          .update({"is_active": false})
          .eq("id", id);

      Get.snackbar(
        "Blocked",
        "Salesperson has been temporarily blocked.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );

      _load();
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  // -----------------------------------------
  // UNBLOCK SALESPERSON
  // -----------------------------------------
  Future<void> _unblock(String id) async {
    try {
      await _client
          .from("user_profiles")
          .update({"is_active": true})
          .eq("id", id);

      Get.snackbar(
        "Unblocked",
        "Salesperson is active again.",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      _load();
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  // -----------------------------------------
  // DELETE SALESPERSON
  // -----------------------------------------
  void _delete(String id) async {
    final confirm = await Get.dialog(
      AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this salesperson?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Delete profile
        await _client.from("user_profiles").delete().eq("id", id);

        // delete auth user
        await _client.auth.admin.deleteUser(id);

        Get.snackbar(
          "Deleted",
          "Salesperson removed successfully",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );

        _load();
      } catch (e) {
        Get.snackbar("Error", e.toString());
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _load();

    searchCtrl.addListener(() {
      final q = searchCtrl.text.toLowerCase();
      setState(() {
        filtered = salespersons
            .where((e) =>
            (e["full_name"] ?? "").toString().toLowerCase().contains(q))
            .toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales Persons"),
        backgroundColor: Colors.transparent,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: SColors.primary,
        onPressed: () async {
          final added = await Get.to(() => const AddSalesPersonPage());
          if (added == true) _load();
        },
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          // ---------------- SEARCH BAR ----------------
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: searchCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Search salesperson",
              ),
            ),
          ),

          // ---------------- LIST ----------------
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final sp = filtered[i];

                final bool isActive = sp["is_active"] == true;

                return Card(
                  child: ListTile(
                    title: Text(sp["full_name"] ?? ""),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sp["phone"] ?? ""),
                        Text(
                          isActive ? "Active" : "Blocked",
                          style: TextStyle(
                            color: isActive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // --- BLOCK / UNBLOCK BUTTON ---
                        IconButton(
                          icon: Icon(
                            isActive ? Icons.block : Icons.lock_open,
                            color: isActive ? Colors.orange : Colors.green,
                          ),
                          onPressed: () {
                            isActive
                                ? _block(sp["id"])
                                : _unblock(sp["id"]);
                          },
                        ),

                        // --- DELETE ---
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _delete(sp["id"]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
