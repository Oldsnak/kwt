import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kwt/features/sales_bill/view/widgets/SalesPersonIcon.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kwt/app/theme/colors.dart';
import 'package:kwt/core/constants/app_sizes.dart';
import 'package:kwt/core/utils/helpers.dart';
import '../../../core/constants/app_images.dart';
import '../../../widgets/custom_appbar/custom_appbar.dart';
import '../../../widgets/custom_shapes/containers/primary_header_container.dart';
import '../../../widgets/texts/section_heading.dart';

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
  bool isLoading = true;

  final TextEditingController searchCtrl = TextEditingController();

  // STATIC SALESMEN LIST
  final List<Map<String, dynamic>> salesmen = [
    {"name": "All", "id": null, "img": SImages.user3},
    {"name": "Mudassar", "id": "mudassar", "img": SImages.user3},
    {"name": "Talha", "id": "talha", "img": SImages.user2},
    {"name": "Asghar", "id": "asghar", "img": SImages.user4},
    {"name": "Tayyab", "id": "tayyab", "img": SImages.user},
  ];

  @override
  void initState() {
    super.initState();
    loadBills();
  }

  // ---------------------------------------------------------------------------
  // LOAD BILLS WITH CUSTOMER NAME
  // ---------------------------------------------------------------------------
  Future<void> loadBills() async {
    try {
      setState(() => isLoading = true);

      final data = await client
          .from("bills")
          .select("""
            id,
            bill_no,
            total,
            created_at,
            salesperson_id,
            customer:customer_id(name)
          """)
          .order("created_at", ascending: false);

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
  // FILTERING
  // ---------------------------------------------------------------------------
  List<Map<String, dynamic>> get filteredBills {
    return allBills.where((bill) {
      final billNo = (bill["bill_no"] ?? "").toString().toLowerCase();
      final salesmanId = bill["salesperson_id"]?.toString() ?? "";

      bool matchSearch = billNo.contains(searchBill.toLowerCase());
      bool matchSalesman =
      selectedSalesman == "All"
          ? true
          : salesmanId == selectedSalesman;

      return matchSearch && matchSalesman;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // UI
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
                        padding: const EdgeInsets.only(left: SSizes.defaultSpace),
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
                                    salesPersonId: sm["id"] ?? "",
                                    onTap: () {
                                      setState(() {
                                        selectedSalesman = sm["id"] ?? "All";
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
                          bill["customer"]?["name"] ?? "Walking Customer";

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
                              border: Border.all(color: SColors.primary),
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
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),

                          subtitle: Text(
                            "Total Bill: ${bill["total"]}",
                            style: Theme.of(context).textTheme.labelLarge,
                          ),

                          trailing: const Icon(Icons.arrow_forward_ios,
                              color: SColors.primary),
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
