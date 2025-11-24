import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kwt/app/theme/colors.dart';
import 'package:kwt/core/constants/app_sizes.dart';
import 'package:kwt/core/constants/app_strings.dart';
import 'package:kwt/core/utils/helpers.dart';

import 'package:kwt/widgets/custom_appbar/appbar.dart';
import 'package:kwt/widgets/notification_icon/notification_Icon.dart';
import 'package:kwt/widgets/custom_shapes/containers/primary_header_container.dart';

import 'add_customer_page.dart';
import 'customer_debt_page.dart';

/// ---------------------------------------------------------------------------
/// SEARCH MODE
/// ---------------------------------------------------------------------------
enum CustomerSearchMode {
  name,
  phone,
  customerCode,
}

/// ---------------------------------------------------------------------------
/// REGISTERED CUSTOMERS PAGE
/// ---------------------------------------------------------------------------
class RegisteredCustomersPage extends StatefulWidget {
  const RegisteredCustomersPage({super.key});

  @override
  State<RegisteredCustomersPage> createState() =>
      _RegisteredCustomersPageState();
}

class _RegisteredCustomersPageState extends State<RegisteredCustomersPage> {
  final SupabaseClient _client = Supabase.instance.client;

  final TextEditingController _searchCtrl = TextEditingController();

  /// All customers + aggregated debt
  List<Map<String, dynamic>> _allCustomers = [];

  bool _isLoading = true;

  CustomerSearchMode _searchMode = CustomerSearchMode.name;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  // ---------------------------------------------------------------------------
  // LOAD CUSTOMERS + THEIR TOTAL DEBT
  // ---------------------------------------------------------------------------
  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);

    try {
      final res = await _client
          .from('customers')
          .select('''
            id,
            name,
            phone,
            address,
            customer_debts(remaining_amount, debt_amount)
          ''').eq('is_active', true);

      final list = (res as List).map<Map<String, dynamic>>((raw) {
        final map = Map<String, dynamic>.from(raw);

        final List<dynamic> debts =
            (map['customer_debts'] as List?) ?? const [];

        double totalDebt = 0;
        for (final d in debts) {
          final row = d as Map<String, dynamic>;
          final num remaining = (row['remaining_amount'] as num?) ??
              (row['debt_amount'] as num?) ??
              0;
          totalDebt += remaining.toDouble();
        }

        // A short, user-friendly customer code derived from UUID
        final String id = (map['id'] ?? '').toString();
        final String code = _buildCustomerCode(id);

        return {
          'id': id,
          'code': code,
          'name': (map['name'] ?? '').toString(),
          'phone': (map['phone'] ?? '').toString(),
          'address': (map['address'] ?? '').toString(),
          'total_debt': totalDebt,
        };
      }).toList();

      setState(() {
        _allCustomers = list;
      });
    } catch (e) {
      debugPrint('RegisteredCustomersPage._loadCustomers error: $e');
      Get.snackbar('Error', 'Failed to load customers.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Create a short code like "A0S54" from a UUID.
  String _buildCustomerCode(String id) {
    if (id.isEmpty) return '--';
    final cleaned = id.replaceAll('-', '').toUpperCase();
    if (cleaned.length <= 5) return cleaned;
    return cleaned.substring(0, 5);
  }

  // ---------------------------------------------------------------------------
  // DERIVED STATS
  // ---------------------------------------------------------------------------
  int get _totalAccounts => _allCustomers.length;

  double get _totalDebt => _allCustomers.fold<double>(
      0,
          (sum, c) =>
      sum + ((c['total_debt'] as num?)?.toDouble() ?? 0.0));

  // ---------------------------------------------------------------------------
  // FILTERED LIST BASED ON SEARCH MODE
  // ---------------------------------------------------------------------------
  List<Map<String, dynamic>> get _filteredCustomers {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return _allCustomers;

    return _allCustomers.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final phone = (c['phone'] ?? '').toString().toLowerCase();
      final code = (c['code'] ?? '').toString().toLowerCase();

      switch (_searchMode) {
        case CustomerSearchMode.name:
          return name.contains(query);
        case CustomerSearchMode.phone:
          return phone.contains(query);
        case CustomerSearchMode.customerCode:
          return code.contains(query);
      }
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final bool dark = SHelperFunctions.isDarkMode(context);

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                /// ------------------------------------------------------------
                /// HEADER AREA (Green curved background)
                /// ------------------------------------------------------------
                PrimaryHeaderContainer(
                  child: Column(
                    children: [
                      // Custom appbar with notification icon
                      SAppBar(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              STexts.homeAppbarTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.apply(color: SColors.black),
                            ),
                            Text(
                              'Registered Customers',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.apply(color: SColors.black),
                            ),
                          ],
                        ),
                        actions: const [NotificationIcon()],
                      ),

                      const SizedBox(height: SSizes.spaceBtwSections),

                      /// ---------------- SEARCH BAR ---------------------------
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: SSizes.defaultSpace),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SSizes.md,
                            vertical: SSizes.xs,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(
                              SSizes.productImageRadius,
                            ),
                            border: Border.all(color: SColors.grey),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search,
                                  color: Colors.white70),
                              const SizedBox(width: SSizes.sm),
                              Expanded(
                                child: TextField(
                                  controller: _searchCtrl,
                                  style: const TextStyle(
                                      color: Colors.white),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    hintText: _hintForMode(_searchMode),
                                    hintStyle: const TextStyle(
                                        color: Colors.white54),
                                  ),
                                  onChanged: (_) {
                                    setState(() {});
                                  },
                                ),
                              ),

                              /// Dropdown icon for search mode
                              PopupMenuButton<CustomerSearchMode>(
                                icon: const Icon(
                                  Icons.filter_list,
                                  color: Colors.white,
                                ),
                                onSelected: (mode) {
                                  setState(() {
                                    _searchMode = mode;
                                  });
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: CustomerSearchMode.name,
                                    child: Text('Search by Name'),
                                  ),
                                  PopupMenuItem(
                                    value: CustomerSearchMode.phone,
                                    child: Text('Search by Mobile'),
                                  ),
                                  PopupMenuItem(
                                    value:
                                    CustomerSearchMode.customerCode,
                                    child: Text('Search by Customer ID'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: SSizes.spaceBtwSections),

                      /// ---------------- INFORMATION BLOCK --------------------
                      Padding(
                        padding: const EdgeInsets.only(
                            left: SSizes.defaultSpace),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Information:',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(
                                height: SSizes.spaceBtwItems / 4),

                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const SizedBox(width: double.infinity),
                                _DebtInfoCard(
                                  title: 'Accounts: ',
                                  value: _totalAccounts,
                                ),
                                const SizedBox(
                                    height: SSizes.spaceBtwItems / 2),
                                _DebtInfoCard(
                                  title: 'Total Debt: ',
                                  value: _totalDebt.round(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: SSizes.spaceBtwSections),
                    ],
                  ),
                ),

                /// ------------------------------------------------------------
                /// CUSTOMERS LIST
                /// ------------------------------------------------------------
                Padding(
                  padding:
                  const EdgeInsets.fromLTRB(5, 0, 5, 5),
                  child: _isLoading
                      ? const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(
                      child:
                      CircularProgressIndicator(),
                    ),
                  )
                      : Column(
                    children: _filteredCustomers
                        .map((cust) =>
                        _buildCustomerTile(context, cust, dark))
                        .toList(),
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),

      /// ----------------------------------------------------------------------
      /// FAB: Register New Customer (no navigation yet → just message)
      /// ----------------------------------------------------------------------
      floatingActionButton: FloatingActionButton(
        backgroundColor: dark
            ? SColors.darkPrimaryContainer
            : SColors.buttonPrimary,
        foregroundColor: dark ? SColors.primary : Colors.white,
        tooltip: 'Register New Customer',
        onPressed: () async {
          try {
            /// Navigate to Add Customer Page
            await Get.to(() => AddCustomerPage());
          } catch (e) {
            Get.snackbar(
              'Error',
              'Failed to open registration page.',
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        },
        child: const Icon(Icons.app_registration, size: 35),
      ),

    );
  }

  // Helper to build each customer row
  Widget _buildCustomerTile(
      BuildContext context, Map<String, dynamic> cust, bool dark) {
    final String code = (cust['code'] ?? '').toString();
    final String name = (cust['name'] ?? '').toString();
    final String phone = (cust['phone'] ?? '').toString();
    final String address = (cust['address'] ?? '').toString();
    final double totalDebt =
        (cust['total_debt'] as num?)?.toDouble() ?? 0.0;
    final String customerId = cust['id'];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: dark ? SColors.darkerGrey : SColors.accent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(SSizes.lg),
        color: SColors.accent.withOpacity(0.3),
      ),
      margin: const EdgeInsets.all(5),
      child: ListTile(
        leading: Container(
          height: 40,
          width: 70,
          decoration: BoxDecoration(
            color: dark ? SColors.black : SColors.white,
            borderRadius: BorderRadius.circular(SSizes.sm),
            border: Border.all(color: SColors.primary),
          ),
          child: Center(
            child: Text(
              code,
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
          name,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Total Debt: ${totalDebt.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: SColors.primary,
        ),
        onTap: () async {
          /// ⭐ Navigate to full debt details page
          await Get.to(() => CustomerDebtPage(
            customerId: customerId,
            customerName: name,
            customerPhone: phone,
            customerAddress: address,
            customerCode: code,
          ));
        },
      ),
    );
  }


  static String _hintForMode(CustomerSearchMode mode) {
    switch (mode) {
      case CustomerSearchMode.name:
        return 'Search by Customer Name';
      case CustomerSearchMode.phone:
        return 'Search by Mobile Number';
      case CustomerSearchMode.customerCode:
        return 'Search by Customer ID';
    }
  }
}

/// ---------------------------------------------------------------------------
/// INFO ROW WIDGET (Accounts / Total Debt)
/// ---------------------------------------------------------------------------
class _DebtInfoCard extends StatelessWidget {
  const _DebtInfoCard({
    required this.title,
    required this.value,
  });

  final String title;
  final int value;

  @override
  Widget build(BuildContext context) {
    final bool dark = SHelperFunctions.isDarkMode(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 10,
          width: 10,
          decoration: BoxDecoration(
            color: dark ? SColors.black : SColors.white,
            border: Border.all(color: SColors.accent, width: 1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: SSizes.spaceBtwItems / 2),
        SizedBox(
          width: 250,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: SColors.black,
                ),
              ),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: SColors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
