// lib/core/services/notification_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class NotificationService {
  final SupabaseClient client = SupabaseService.client;

  // ----------------------------------------------------------
  // CREATE NOTIFICATION (generic)
  // ----------------------------------------------------------
  Future<void> createNotification({
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? meta,
  }) async {
    await client.from('notifications').insert({
      'type': type,
      'title': title,
      'message': message,
      'meta': meta,
      'is_read': false,
    });
  }

  // ----------------------------------------------------------
  // LOW STOCK DETECTOR
  // ----------------------------------------------------------
  Future<void> checkLowStock({int threshold = 10}) async {
    final res = await client
        .from('products')
        .select()
        .lte('stock_quantity', threshold);

    final List list = (res as List);
    for (final p in list) {
      await createNotification(
        type: 'low_stock',
        title: 'Low stock: ${p['name']}',
        message: 'Only ${p['stock_quantity']} left in store.',
        meta: {
          'product_id': p['id'],
          'stock_quantity': p['stock_quantity'],
        },
      );
    }
  }

  // ----------------------------------------------------------
  // PRICE RISE DETECTOR
  // ----------------------------------------------------------
  Future<void> checkPriceRise() async {
    final products = await client.from('products').select();
    for (final prod in (products as List)) {
      final pid = prod['id'];
      final entries = await client
          .from('stock_entries')
          .select()
          .eq('product_id', pid)
          .order('received_date', ascending: false)
          .limit(2);

      final eList = entries as List;
      if (eList.length >= 2) {
        final latest = (eList[0]['purchase_rate'] as num).toDouble();
        final prev = (eList[1]['purchase_rate'] as num).toDouble();

        if (latest > prev * 1.05) {
          await createNotification(
            type: 'price_rise',
            title: 'Purchase price rose: ${prod['name']}',
            message:
            'New rate: ${latest.toStringAsFixed(2)} (was ${prev.toStringAsFixed(2)}).',
            meta: {
              'product_id': pid,
              'latest_rate': latest,
              'previous_rate': prev,
            },
          );
        }
      }
    }
  }


  // ----------------------------------------------------------
  // CHECK OVERDUE CUSTOMERS (NEW SCHEMA: remaining_amount)
  // ----------------------------------------------------------
  Future<void> checkOverdueCustomers({int overdueDays = 30}) async {
    final now = DateTime.now().toUtc();

    // remaining_amount > 0 matlab abhi bhi qarz baqi hai
    final rows = await client
        .from('customer_debts')
        .select('''
          id,
          customer_id,
          debt_amount,
          remaining_amount,
          due_date,
          customers(name, phone)
        ''')
        .gt('remaining_amount', 0); // 👈 NO is_cleared ANYMORE

    if (rows == null || (rows as List).isEmpty) return;

    for (final r in rows) {
      final dueDateStr = r['due_date'] as String?;
      if (dueDateStr == null) continue;

      final dueDate = DateTime.parse(dueDateStr).toUtc();
      final diffDays = now.difference(dueDate).inDays;

      // sirf woh customers jinka due X din se zyada purana ho
      if (diffDays >= overdueDays) {
        final cust = r['customers'] ?? {};

        await createNotification(
          type: 'overdue_customer',
          title: 'Overdue: ${cust['name']}',
          message:
          'Customer has pending amount ${r['debt_amount']} since ${r['due_date']}.',
          meta: {
            'customer_id': r['customer_id'],
            'debt_id': r['id'],
            'customer_name': cust['name'],
            'phone': cust['phone'],
          },
        );
      }
    }
  }


  // ----------------------------------------------------------
  // GENERATE CUSTOMER STATEMENT PDF + SHARE
  // (used by action notification)
  // ----------------------------------------------------------
  Future<void> generateCustomerStatementPdfAndShare(
      String customerId, {
        String? customerName,
      }) async {
    // 1) Fetch customer info (optional)
    final custRow = await client
        .from('customers')
        .select()
        .eq('id', customerId)
        .maybeSingle();

    final name = customerName ??
        (custRow != null ? (custRow['name'] ?? 'Customer') : 'Customer');

    // 2) Fetch debts with bills
    final debts = await client
        .from('customer_debts')
        .select('id, customer_id, bill_id, debt_amount, paid_amount, remaining_amount, due_date, customers(name)')
        .gt('remaining_amount', 0)          // ✅ only unpaid debts
        .lte('due_date', DateTime.now().add(const Duration(days: 2)).toIso8601String());


    // 3) Fetch payments (assuming customer_payments has bill_id + payment_date)
    final payments = await client
        .from('customer_payments')
        .select('bill_id, payment_date, paid_amount')
        .eq('customer_id', customerId)
        .order('payment_date', ascending: true);

    final debtsList = debts as List;
    final paymentsList = payments as List;

    // 4) Build PDF
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'KWT - Customer Statement',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text('Customer: $name'),
              if (custRow != null && custRow['phone'] != null)
                pw.Text('Phone: ${custRow['phone']}'),
              pw.SizedBox(height: 12),
              pw.Text(
                'Generated: ${DateTime.now()}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 16),

              // Debts section
              pw.Text(
                'Debts by Bill',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              debtsList.isEmpty
                  ? pw.Text('No debts found.')
                  : pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFE0E0E0),
                    ),
                    children: [
                      _cell('Bill No', isHeader: true),
                      _cell('Debt Amount', isHeader: true),
                      _cell('Remaining', isHeader: true),
                      _cell('Due Date', isHeader: true),
                    ],
                  ),
                  ...debtsList.map((d) {
                    final b = d['bills'];
                    final billNo = b != null ? b['bill_no'] : d['bill_id'];
                    final debtAmount =
                        (d['debt_amount'] as num?)?.toDouble() ?? 0;
                    final remaining =
                        (d['remaining_amount'] as num?)?.toDouble() ??
                            debtAmount;
                    final dueDateStr =
                        d['due_date']?.toString() ?? '-';

                    return pw.TableRow(
                      children: [
                        _cell(billNo.toString()),
                        _cell(debtAmount.toStringAsFixed(2)),
                        _cell(remaining.toStringAsFixed(2)),
                        _cell(dueDateStr),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 20),

              // Payments section
              pw.Text(
                'Payments History',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              paymentsList.isEmpty
                  ? pw.Text('No payments recorded.')
                  : pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFE0E0E0),
                    ),
                    children: [
                      _cell('Bill', isHeader: true),
                      _cell('Payment Date', isHeader: true),
                      _cell('Amount', isHeader: true),
                    ],
                  ),
                  ...paymentsList.map((p) {
                    final billId = p['bill_id'];
                    final payDate = p['payment_date']?.toString() ?? '-';
                    final amt =
                        (p['paid_amount'] as num?)?.toDouble() ?? 0;

                    return pw.TableRow(
                      children: [
                        _cell(billId?.toString() ?? '-'),
                        _cell(payDate),
                        _cell(amt.toStringAsFixed(2)),
                      ],
                    );
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );

    // 5) Share PDF (system share sheet)
    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'statement-$name.pdf',
    );
  }

  // Small helper cell
  pw.Widget _cell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
