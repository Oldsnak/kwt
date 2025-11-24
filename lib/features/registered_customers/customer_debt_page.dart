import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kwt/features/registered_customers/pay_debt_page.dart';
import 'package:kwt/widgets/custom_shapes/containers/glossy_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kwt/app/theme/colors.dart';
import 'package:kwt/core/constants/app_sizes.dart';
import 'package:kwt/core/utils/helpers.dart';

/// Arguments you’ll pass from Registered Customers page:
/// Get.to(() => CustomerDebtPage(
///   customerId: c['id'],
///   customerName: c['name'],
///   customerPhone: c['phone'],
///   customerAddress: c['address'],
///   customerCode: c['customer_code'], // optional if you add such a column
/// ));
class CustomerDebtPage extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final String? customerAddress;

  /// Optional human-readable code like A0S54.
  /// If null, we’ll derive a short code from the UUID.
  final String? customerCode;

  const CustomerDebtPage({
    super.key,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.customerCode,
  });

  @override
  State<CustomerDebtPage> createState() => _CustomerDebtPageState();
}

class _CustomerDebtPageState extends State<CustomerDebtPage> {
  final SupabaseClient _client = Supabase.instance.client;

  bool _loading = true;

  /// All rows from customer_debts for this customer (with embedded bill).
  List<Map<String, dynamic>> _debts = [];

  /// Payment history rows with computed remaining after each payment.
  /// Each map: { 'date': String, 'paid': double, 'remaining': double }
  List<Map<String, dynamic>> _paidHistory = [];

  double _totalRemainingDebt = 0;
  DateTime? _sinceDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('dd-MM-yyyy').format(dt);
  }

  String _shortCustomerCode() {
    if (widget.customerCode != null && widget.customerCode!.trim().isNotEmpty) {
      return widget.customerCode!;
    }
    // fallback: first 5 chars of UUID, uppercase
    final id = widget.customerId;
    if (id.length <= 5) return id.toUpperCase();
    return id.substring(0, 5).toUpperCase();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _loading = true);

      // 1) Fetch debts with related bill numbers
      final debtsRes = await _client
          .from('customer_debts')
          .select('''
            id,
            bill_id,
            debt_amount,
            remaining_amount,
            created_at,
            due_date,
            bills(bill_no, created_at)
          ''')
          .eq('customer_id', widget.customerId)
          .order('created_at', ascending: true);

      final debtsList = (debtsRes as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      // 2) Compute totals + "since" date
      double totalDebtAmount = 0;
      double totalRemaining = 0;
      DateTime? earliest;

      for (final d in debtsList) {
        final debtAmount = _toDouble(d['debt_amount']);
        final remaining = _toDouble(d['remaining_amount']);

        totalDebtAmount += debtAmount;
        totalRemaining += remaining;

        final createdAt = _toDate(d['created_at']);
        if (createdAt != null) {
          if (earliest == null || createdAt.isBefore(earliest!)) {
            earliest = createdAt;
          }
        }
      }

      // If no debts, fall back to customer.created_at
      if (earliest == null) {
        final custRow = await _client
            .from('customers')
            .select('created_at')
            .eq('id', widget.customerId)
            .maybeSingle();

        if (custRow != null) {
          earliest = _toDate(custRow['created_at']);
        }
      }

      // 3) Fetch payments & build running remaining
      final payRes = await _client
          .from('customer_payments')
          .select('bill_id, paid_amount, payment_date')
          .eq('customer_id', widget.customerId)
          .order('payment_date', ascending: true);

      final paymentsList = (payRes as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final List<Map<String, dynamic>> paidHistory = [];
      double runningPaid = 0;

      for (final p in paymentsList) {
        final paid = _toDouble(p['paid_amount']);
        runningPaid += paid;

        final remainingAfter = (totalDebtAmount - runningPaid);
        final paymentDate = _toDate(p['payment_date']);

        paidHistory.add({
          'date': paymentDate,
          'paid': paid,
          'remaining': remainingAfter < 0 ? 0 : remainingAfter,
        });
      }

      setState(() {
        _debts = debtsList;
        _paidHistory = paidHistory;
        _totalRemainingDebt = totalRemaining;
        _sinceDate = earliest;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('CustomerDebtPage._loadData error: $e\n$st');
      setState(() => _loading = false);
      Get.snackbar('Error', 'Failed to load customer debt information.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = SHelperFunctions.isDarkMode(context);

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SSizes.defaultSpace,
            vertical: SSizes.appBarHeight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: SSizes.appBarHeight),

              // ----------------- CUSTOMER INFORMATION CARD -----------------
              GlossyContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Customer Information',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: SColors.primary,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    SizedBox(height: SSizes.sm),
                    Divider(
                      color: dark
                          ? SColors.darkGrey
                          : SColors.primary,
                      thickness: 1,
                    ),
                    SizedBox(height: SSizes.sm),

                    _infoRow(
                      icon: Iconsax.personalcard,
                      label: 'Customer ID',
                      value: _shortCustomerCode(),
                    ),

                    SizedBox(height: SSizes.sm),
                    Divider(
                      color: dark
                          ? SColors.darkGrey
                          : SColors.primary,
                      thickness: 1,
                    ),
                    SizedBox(height: SSizes.sm),

                    _infoRow(
                      icon: Icons.person,
                      label: 'Customer Name',
                      value: widget.customerName,
                    ),

                    SizedBox(height: SSizes.sm),
                    Divider(
                      color: dark
                          ? SColors.darkGrey
                          : SColors.primary,
                      thickness: 1,
                    ),
                    SizedBox(height: SSizes.sm),

                    _infoRow(
                      icon: Iconsax.call,
                      label: 'Mobile Number',
                      value: widget.customerPhone?.isNotEmpty == true
                          ? widget.customerPhone!
                          : '-',
                    ),

                    SizedBox(height: SSizes.sm),
                    Divider(
                      color: dark
                          ? SColors.darkGrey
                          : SColors.primary,
                      thickness: 1,
                    ),
                    SizedBox(height: SSizes.sm),

                    _infoRow(
                      icon: Icons.calendar_month,
                      label: 'Address',
                      value: widget.customerAddress?.isNotEmpty == true
                          ? widget.customerAddress!
                          : '-',
                    ),

                    SizedBox(height: SSizes.sm),
                    Divider(
                      color: dark
                          ? SColors.darkGrey
                          : SColors.primary,
                      thickness: 1,
                    ),
                    SizedBox(height: SSizes.sm),

                    _infoRow(
                      icon: Icons.payments_outlined,
                      label: 'Remaining Debt',
                      value: _totalRemainingDebt
                          .toStringAsFixed(0),
                    ),

                    SizedBox(height: SSizes.sm),
                    Divider(
                      color: dark
                          ? SColors.darkGrey
                          : SColors.primary,
                      thickness: 1,
                    ),
                    SizedBox(height: SSizes.sm),

                    _infoRow(
                      icon: Icons.hourglass_top,
                      label: 'Since',
                      value: _formatDate(_sinceDate),
                    ),

                    SizedBox(height: SSizes.sm),
                  ],
                ),
              ),

              SizedBox(height: SSizes.md,),
              // ----------------- DEBT INFORMATION CARD -----------------
              GlossyContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Debt Information',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: SColors.primary,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    SizedBox(height: SSizes.sm),
                    Divider(
                      color: dark
                          ? SColors.darkGrey
                          : SColors.primary,
                      thickness: 1,
                    ),
                    SizedBox(height: SSizes.sm),

                    if (_debts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 8.0),
                        child: Text(
                          'No active debts.',
                          style: TextStyle(fontSize: 14),
                        ),
                      )
                    else
                      ..._buildDebtRows(dark),
                  ],
                ),
              ),

              SizedBox(height: SSizes.spaceBtwSections),

              // ----------------- PAID DEBT INFORMATION TITLE -----------------
              Text(
                'Paid Debt Information',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: SColors.primary,
                ),
              ),

              // ----------------- PAID DEBT CARDS -----------------
              if (_paidHistory.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No payments recorded yet.',
                    style: TextStyle(fontSize: 14),
                  ),
                )
              else
                ..._paidHistory.map(
                      (p) => _paidDebtCard(
                    date: _formatDate(p['date'] as DateTime?),
                    debtPaid: (_toDouble(p['paid'])).toInt(),
                    dark: dark,
                  ),
                ),

              SizedBox(height: SSizes.spaceBtwSections),
            ],
          ),
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) {
          final dark = SHelperFunctions.isDarkMode(context);
          return FloatingActionButton(
            backgroundColor: dark
                ? SColors.darkPrimaryContainer
                : SColors.buttonPrimary,
            foregroundColor:
            dark ? SColors.primary : Colors.white,
            tooltip: 'Pay Debt',
            onPressed: () async {
              final result = await Get.to(() => PayDebtPage(
                customerId: widget.customerId,
                remainingDebt: _totalRemainingDebt,
              ));
              // Refresh page after successful payment
              if (result == true) {
                _loadData();
              }
            },
            child: const Icon(Icons.receipt_long_sharp, size: 35),
          );
        },
      ),
    );
  }

  // ----------------- UI HELPERS -----------------

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: SColors.primary, size: 26),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        if (value.isNotEmpty)
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey.shade300,
            ),
          ),
      ],
    );
  }

  List<Widget> _buildDebtRows(bool dark) {
    final List<Widget> children = [];

    for (int i = 0; i < _debts.length; i++) {
      final d = _debts[i];

      final bill = d['bills'] as Map<String, dynamic>?;
      final billNo = bill?['bill_no']?.toString() ??
          d['bill_id']?.toString() ??
          '-';

      final remaining = _toDouble(
        d['remaining_amount'] ?? d['debt_amount'],
      ).toInt();

      children.add(
        _debtInfoRow(
          billNumber: billNo,
          debt: remaining,
          dark: dark,
        ),
      );

      if (i != _debts.length - 1) {
        children.add(const SizedBox(height: 8));
        children.add(
          Divider(
            color: dark ? SColors.darkGrey : SColors.primary,
            thickness: 1,
          ),
        );
        children.add(const SizedBox(height: 8));
      }
    }

    return children;
  }

  Widget _debtInfoRow({
    required String billNumber,
    required int debt,
    required bool dark,
  }) {
    return Row(
      children: [
        Container(
          height: 40,
          width: 70,
          decoration: BoxDecoration(
            color: dark ? SColors.black : Colors.white,
            borderRadius: BorderRadius.circular(SSizes.sm),
            border: Border.all(color: SColors.primary),
          ),
          child: Center(
            child: Text(
              billNumber,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: SColors.primary,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: SSizes.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Debt:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: SColors.grey,
                  ),
                ),
                Text(
                  debt.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: SColors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _paidDebtCard({
    required String date,
    required int debtPaid,
    required bool dark,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GlossyContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                date,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: SColors.primary,
                  letterSpacing: 1,
                ),
              ),
            ),
            SizedBox(height: SSizes.sm),
            Divider(
              color: dark ? SColors.darkGrey : SColors.primary,
              thickness: 1,
            ),
            const SizedBox(height: SSizes.sm),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: SSizes.xs),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Paid Debt: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: dark
                          ? Colors.grey
                          : SColors.dark,
                    ),
                  ),
                  Text("$debtPaid", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: dark ? Colors.grey : SColors.dark,),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
