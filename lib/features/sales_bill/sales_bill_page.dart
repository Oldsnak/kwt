import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kwt/features/sales_bill/widgets/SalesPersonIcon.dart';
import 'package:kwt/features/sales_bill/widgets/customer_bill.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kwt/app/theme/colors.dart';
import 'package:kwt/core/constants/app_sizes.dart';
import 'package:kwt/core/utils/helpers.dart';
import '../../core/constants/app_images.dart';
import '../../widgets/custom_appbar/custom_appbar.dart';
import '../../widgets/custom_shapes/containers/primary_header_container.dart';
import '../../widgets/texts/section_heading.dart';

class SalesBillPage extends StatefulWidget {
  const SalesBillPage({super.key});

  @override
  State<SalesBillPage> createState() => _SalesBillPageState();
}

class _SalesBillPageState extends State<SalesBillPage> {
  final SupabaseClient client = Supabase.instance.client;

  String selectedSalesman = "All";
  String searchBill = "";

  List<Map<String, dynamic>> allBills = [];
  List<Map<String, dynamic>> salesmen = [];

  bool isLoading = true;

  final TextEditingController searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadSalesmen();
    loadBills();
  }

  // ---------------------------------------------------------------------------
  // LOAD SALESMEN (REAL SALES PERSONS FROM user_profiles)
  // ---------------------------------------------------------------------------
  Future<void> loadSalesmen() async {
    try {
      final data = await client
          .from("user_profiles")
          .select("id, full_name, role");

      final list = (data as List)
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => e['role'] == 'salesperson')
          .toList();

      salesmen = [
        {
          "name": "All",
          "id": "All",
          "img": SImages.user3,
        },
        ...list.map((s) => {
          "name": s["full_name"],
          "id": s["id"],
          "img": SImages.user,
        })
      ];

      setState(() {});
    } catch (e) {
      print("loadSalesmen error: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // LOAD BILLS WITH CUSTOMER + APPLY ROLE FILTER
  // ---------------------------------------------------------------------------
  Future<void> loadBills() async {
    try {
      setState(() => isLoading = true);

      final user = client.auth.currentUser;

      final isOwner = await _isOwner(user!.id);

      // First create the base query WITHOUT .order()
      final baseQuery = client.from("bills").select("""
      id,
      bill_no,
      total,
      created_at,
      salesperson_id,
      customer:customer_id(name)
    """);

      // Apply filter BEFORE order()
      if (!isOwner) {
        baseQuery.eq("salesperson_id", user.id);
      }

      // NOW apply order
      final data = await baseQuery.order("created_at", ascending: false);

      allBills = (data as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      print("loadBills error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }


  // ---------------------------------------------------------------------------
  // CHECK IF USER IS OWNER
  // ---------------------------------------------------------------------------
  Future<bool> _isOwner(String uid) async {
    try {
      final res = await client
          .from("user_profiles")
          .select("role")
          .eq("id", uid)
          .maybeSingle();

      if (res == null) return false;

      return res["role"] == "owner";
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // FILTERS
  // ---------------------------------------------------------------------------
  List<Map<String, dynamic>> get filteredBills {
    return allBills.where((bill) {
      final billNo = (bill["bill_no"] ?? "").toString().toLowerCase();
      final salesmanId = bill["salesperson_id"]?.toString() ?? "";

      // Search filter
      final matchSearch = billNo.contains(searchBill.toLowerCase());

      // Salesman filter
      final matchSalesman = selectedSalesman == "All"
          ? true
          : selectedSalesman == salesmanId;

      return matchSearch && matchSalesman;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // UI (UNCHANGED)
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final dark = SHelperFunctions.isDarkMode(context);

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                PrimaryHeaderContainer(
                  child: Column(
                    children: [
                      const CustomAppbar(),
                      const SizedBox(height: SSizes.spaceBtwSections),

                      // SEARCH BAR
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: SSizes.defaultSpace),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: SSizes.md, vertical: SSizes.xs),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius:
                            BorderRadius.circular(SSizes.productImageRadius),
                            border: Border.all(color: SColors.grey),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search, color: Colors.white70),
                              const SizedBox(width: SSizes.sm),
                              Expanded(
                                child: TextField(
                                  controller: searchCtrl,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "Search Bill No",
                                    hintStyle: TextStyle(color: Colors.white54),
                                  ),
                                  onChanged: (v) {
                                    setState(() => searchBill = v);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: SSizes.spaceBtwSections),

                      // SALES PERSON FILTER
                      Padding(
                        padding:
                        const EdgeInsets.only(left: SSizes.defaultSpace),
                        child: Column(
                          children: [
                            const SectionHeading(
                              title: "Sales Person",
                              showActionButton: false,
                              textColor: Colors.black,
                            ),
                            const SizedBox(height: SSizes.spaceBtwItems),

                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: salesmen.map((sm) {
                                  return SalesPersonIcon(
                                    image: sm["img"],
                                    title: sm["name"],
                                    salesPersonId: sm["id"],
                                    onTap: () {
                                      setState(() {
                                        selectedSalesman = sm["id"];
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: SSizes.spaceBtwSections),
                    ],
                  ),
                ),

                // BILL LIST
                Padding(
                  padding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
                  child: isLoading
                      ? const Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(),
                  )
                      : Column(
                    children: filteredBills.map((bill) {
                      final customerName =
                          bill["customer"]?["name"] ??
                              "Walking Customer";

                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: dark
                                ? SColors.darkerGrey
                                : SColors.accent,
                            width: 2,
                          ),
                          borderRadius:
                          BorderRadius.circular(SSizes.lg),
                          color: SColors.accent.withOpacity(0.3),
                        ),
                        margin: const EdgeInsets.all(5),
                        child: ListTile(
                          leading: Container(
                            height: 40,
                            width: 70,
                            decoration: BoxDecoration(
                              color: dark
                                  ? SColors.black
                                  : SColors.white,
                              borderRadius:
                              BorderRadius.circular(SSizes.sm),
                              border: Border.all(
                                  color: SColors.primary),
                            ),
                            child: Center(
                              child: Text(
                                bill["bill_no"] ?? "",
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: SColors.primary,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            customerName,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Total Bill: ${bill["total"]}",
                            style:
                            Theme.of(context).textTheme.labelLarge,
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: SColors.primary,
                          ),

                          // OPEN BILL DETAILS
                          onTap: () {
                            Get.to(() => CustomerBill(
                              billId: bill["id"],
                            ));
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
