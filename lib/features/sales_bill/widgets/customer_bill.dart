import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kwt/widgets/custom_shapes/containers/glossy_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kwt/app/theme/colors.dart';
import 'package:kwt/core/constants/app_sizes.dart';
import 'package:kwt/core/utils/helpers.dart';
import '../../../../core/controllers/auth_controller.dart';
import '../../sell_product/sell_page.dart';

class CustomerBill extends StatefulWidget {
  final String billId;

  const CustomerBill({super.key, required this.billId});

  @override
  State<CustomerBill> createState() => _CustomerBillState();
}

class _CustomerBillState extends State<CustomerBill> {
  final SupabaseClient _client = Supabase.instance.client;
  final auth = Get.find<AuthController>();

  Map<String, dynamic>? bill;
  List<Map<String, dynamic>> items = [];
  bool loading = true;

  String salespersonName = "Unknown";

  @override
  void initState() {
    super.initState();
    _loadBill();
  }

  Future<void> _loadBill() async {
    try {
      setState(() => loading = true);

      final billRes = await _client
          .from('bills')
          .select('''
            id,
            bill_no,
            total,
            total_items,
            total_discount,
            sub_total,
            total_paid,
            is_fully_paid,
            created_at,
            salesperson_id,
            salesperson:salesperson_id(full_name),
            customers:customer_id(name, phone)
          ''')
          .eq('id', widget.billId)
          .single();

      // ---- Fix salesperson name handling ----
      final sp = billRes['salesperson'];
      final spId = billRes['salesperson_id'];

      if (sp != null && sp['full_name'] != null) {
        salespersonName = sp['full_name'];
      } else if (spId == null) {
        salespersonName = "Owner";
      } else {
        salespersonName = "Sales Person";
      }

      // ---- Load items ----
      final itemsRes = await _client
          .from('sales')
          .select('''
            quantity,
            selling_rate,
            discount_per_piece,
            line_total,
            products(name)
          ''')
          .eq('bill_id', widget.billId);

      setState(() {
        bill = billRes;
        items = (itemsRes as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        loading = false;
      });
    } catch (e) {
      loading = false;
      Get.snackbar("Error", "Failed to load bill: $e");
    }
  }

  // ---------- Role-based Edit Permission ----------
  bool get canEditBill {
    if (auth.isOwner) return true;

    final billSalesperson = bill?["salesperson_id"];
    final currentUserId = auth.userProfile.value?.id;

    return billSalesperson != null && billSalesperson == currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = SHelperFunctions.isDarkMode(context);

    if (loading || bill == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final total = (bill!["total"] as num).toDouble();
    final totalPaid = (bill!["total_paid"] as num).toDouble();
    final isPaid = bill!["is_fully_paid"] == true;

    final double pending = (total - totalPaid).clamp(0, double.infinity);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SSizes.sm,
            vertical: SSizes.appBarHeight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: SSizes.defaultSpace),

              SizedBox(
                width: 150,
                height: 150,
                child: Image.asset(
                  isPaid
                      ? "assets/images/paid.png"
                      : "assets/images/unpaid.png",
                ),
              ),

              SizedBox(height: SSizes.spaceBtwItems),

              _buildCustomerCard(dark, pending),

              SizedBox(height: SSizes.spaceBtwSections),

              _buildDataTable(),

              SizedBox(height: 100),
            ],
          ),
        ),
      ),

      floatingActionButton: canEditBill
          ? FloatingActionButton(
        backgroundColor: dark
            ? SColors.darkPrimaryContainer
            : SColors.buttonPrimary,
        foregroundColor: dark ? SColors.primary : Colors.white,
        tooltip: "Edit Bill",
        onPressed: () {
          Get.to(
                () => SellPage(
              editingBillId: widget.billId,
              editingBillNo: bill!["bill_no"],
              editingCustomerName:
              bill!["customers"]?["name"] ?? "",
              editingItems: items,
            ),
          );
        },
        child: const Icon(Icons.edit, size: 35),
      )
          : null,
    );
  }

  // -------------------------------------------------------------------
  Widget _buildCustomerCard(bool dark, double pending) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SSizes.defaultSpace),
      child: GlossyContainer(
        child: Column(
          children: [
            Text(
              "Bill No: ${bill!["bill_no"]}",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: SColors.primary,
              ),
            ),
            const SizedBox(height: SSizes.sm),
            Divider(
              color: dark ? SColors.darkGrey : SColors.primary,
              thickness: 1,
            ),

            _row(
              Icons.person,
              "Customer Name",
              bill!["customers"]?["name"] ?? "Walking Customer",
            ),

            _row(
              Icons.phone,
              "Mobile Number",
              bill!["customers"]?["phone"] ?? "-",
            ),

            _row(
              Icons.payments,
              "Total Amount",
              bill!["total"].toString(),
            ),

            _row(
              Icons.date_range,
              "Date & Time",
              DateFormat("dd-MM-yyyy • hh:mm a")
                  .format(DateTime.parse(bill!["created_at"])),
            ),

            _row(
              Icons.person_4,
              "Sales Person",
              salespersonName,
            ),

            _row(
              Icons.hourglass_bottom,
              "Pending Dues",
              pending.toStringAsFixed(0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Column(
      children: [
        const SizedBox(height: SSizes.xs),
        Row(
          children: [
            Icon(icon, color: SColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: SSizes.xs),
        Divider(
          color: SColors.primary,
          thickness: 1,
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text("Items", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Price", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Disc.", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Pcs.", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Total", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: items.map((data) {
          return DataRow(
            cells: [
              DataCell(Text(data["products"]["name"].toString())),
              DataCell(Text("${data["selling_rate"]}")),
              DataCell(Text("${data["discount_per_piece"]}")),
              DataCell(Text("${data["quantity"]}")),
              DataCell(Text("${data["line_total"]}")),
            ],
          );
        }).toList(),
      ),
    );
  }
}
