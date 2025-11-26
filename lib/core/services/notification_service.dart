// lib/core/services/notification_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final SupabaseClient client = SupabaseService.client;

  // ===========================================================================
  // CREATE NOTIFICATION — OWNER ONLY (RLS SAFE)
  // ===========================================================================
  Future<void> createNotification({
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? meta,
    String? userId,
  }) async {
    try {
      final res = await client.functions.invoke(
        "generate_notifications",
        body: {
          "type": type,
          "payload": {
            "title": title,
            "message": message,
            "meta": meta,
            "user_id": userId,
          }
        },
      );

      final data = res.data;
      if (data == null || data["success"] != true) {
        throw Exception(data?["error"] ?? "Unable to create notification.");
      }

    } catch (e) {
      SnackBar(content: Text("❌ NotificationService.createNotification ERROR: $e"));
      throw Exception("Unable to create notification.");
    }
  }


  // ===========================================================================
  // LOW STOCK DETECTOR (OWNER FEATURE)
  // ===========================================================================
  Future<void> checkLowStock({int threshold = 10}) async {
    try {
      final res = await client
          .from('products')
          .select()
          .lte('stock_quantity', threshold);

      for (final p in (res as List)) {
        await createNotification(
          type: 'low_stock',
          title: 'Low stock: ${p['name']}',
          message: 'Only ${p['stock_quantity']} left in stock.',
          meta: {
            'product_id': p['id'],
            'stock_quantity': p['stock_quantity'],
          },
        );
      }
    } catch (e) {
      SnackBar(content:Text("❌ checkLowStock ERROR: $e"),);
      throw Exception("Cannot check low stock.");
    }
  }

  // ===========================================================================
  // PRICE RISE DETECTOR — NEW STOCK RATE COMPARED TO PREVIOUS
  // ===========================================================================
  Future<void> checkPriceRise() async {
    try {
      final products = await client.from('products').select();

      for (final prod in (products as List)) {
        final pid = prod['id'];

        final entries = await client
            .from('stock_entries')
            .select()
            .eq('product_id', pid)
            .order('received_date', ascending: false)
            .limit(2);

        final list = entries as List;
        if (list.length < 2) continue;

        final latest = (list[0]['purchase_rate'] as num).toDouble();
        final prev = (list[1]['purchase_rate'] as num).toDouble();

        if (latest > prev * 1.05) {
          await createNotification(
            type: 'price_rise',
            title: 'Purchase rate increased (${prod['name']})',
            message:
            'New: ${latest.toStringAsFixed(2)}, Old: ${prev.toStringAsFixed(2)}',
            meta: {
              'product_id': pid,
              'previous_rate': prev,
              'new_rate': latest,
            },
          );
        }
      }
    } catch (e) {
      SnackBar(content:Text("❌ checkPriceRise ERROR: $e"),);
      throw Exception("Cannot check price rise.");
    }
  }

  // ===========================================================================
  // OVERDUE CUSTOMERS DETECTOR
  // remaining_amount > 0 AND due_date older than X days
  // ===========================================================================
  Future<void> checkOverdueCustomers({int overdueDays = 30}) async {
    try {
      final now = DateTime.now().toUtc();

      final rows = await client
          .from('customer_debts')
          .select('''
            id,
            customer_id,
            debt_amount,
            remaining_amount,
            due_date,
            customers(name, phone),
            bills(bill_no)
          ''')
          .gt('remaining_amount', 0);

      if (rows == null) return;
      if ((rows as List).isEmpty) return;

      for (final r in rows) {
        if (r['due_date'] == null) continue;

        final dueDate = DateTime.parse(r['due_date']).toUtc();
        final diff = now.difference(dueDate).inDays;

        if (diff >= overdueDays) {
          final cust = r['customers'] ?? {};
          final bill = r['bills'];

          await createNotification(
            type: 'overdue_customer',
            title: 'Overdue: ${cust['name']}',
            message:
            'Pending Rs ${r['remaining_amount']} (Bill: ${bill?['bill_no'] ?? '-'}).',
            meta: {
              'customer_id': r['customer_id'],
              'debt_id': r['id'],
              'customer_name': cust['name'],
              'phone': cust['phone'],
              'due_date': r['due_date'],
              'remaining_amount': r['remaining_amount'],
            },
          );
        }
      }
    } catch (e) {
      SnackBar(content:Text("❌ checkOverdueCustomers ERROR: $e"),);
      throw Exception("Cannot detect overdue customers.");
    }
  }

  // ===========================================================================
  // PDF GENERATOR — Customer Statement
  // ===========================================================================
  Future<void> generateCustomerStatementPdfAndShare(
      String customerId, {
        String? customerName,
      }) async {
    try {
      // ------------------ CUSTOMER ------------------
      final custRow = await client
          .from('customers')
          .select()
          .eq('id', customerId)
          .maybeSingle();

      final name = customerName ??
          (custRow != null ? (custRow['name'] ?? 'Customer') : "Customer");

      // ------------------ DEBTS ------------------
      final debts = await client
          .from('customer_debts')
          .select('''
            id,
            bill_id,
            debt_amount,
            remaining_amount,
            due_date,
            bills(bill_no)
          ''')
          .eq('customer_id', customerId)
          .gt('remaining_amount', 0);

      // ------------------ PAYMENTS ------------------
      final payments = await client
          .from('customer_payments')
          .select()
          .eq('customer_id', customerId)
          .order('payment_date');

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("KWT - Customer Statement",
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text("Customer: $name"),
                if (custRow?['phone'] != null)
                  pw.Text("Phone: ${custRow!['phone']}"),
                pw.SizedBox(height: 12),

                // ------------------ DEBTS TABLE ------------------
                pw.Text("Debts",
                    style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                _buildDebtTable(debts),

                pw.SizedBox(height: 16),

                // ------------------ PAYMENTS TABLE ------------------
                pw.Text("Payments",
                    style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                _buildPaymentTable(payments),
              ],
            );
          },
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: "statement-$name.pdf",
      );
    } catch (e) {
      SnackBar(content:Text("❌ PDF Generation ERROR: $e"),);
      throw Exception("Unable to generate customer PDF.");
    }
  }

  // ===========================================================================
  // HELPERS FOR TABLE CELLS
  // ===========================================================================
  pw.Table _buildDebtTable(dynamic debts) {
    final list = debts as List;

    if (list.isEmpty) {
      return pw.Table(children: [
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text("No debts"),
            )
          ],
        )
      ]);
    }

    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFEAEAEA),
          ),
          children: [
            _cell("Bill No", header: true),
            _cell("Debt"),
            _cell("Remaining"),
            _cell("Due Date"),
          ],
        ),
        ...list.map((d) {
          final billNo = d['bills']?['bill_no'] ?? '-';

          return pw.TableRow(
            children: [
              _cell(billNo),
              _cell(d['debt_amount'].toString()),
              _cell(d['remaining_amount'].toString()),
              _cell(d['due_date']?.toString() ?? "-"),
            ],
          );
        }),
      ],
    );
  }

  pw.Table _buildPaymentTable(dynamic payments) {
    final list = payments as List;

    if (list.isEmpty) {
      return pw.Table(children: [
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text("No payments"),
            )
          ],
        )
      ]);
    }

    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFEAEAEA),
          ),
          children: [
            _cell("Bill ID", header: true),
            _cell("Date"),
            _cell("Amount"),
          ],
        ),
        ...list.map((p) {
          return pw.TableRow(
            children: [
              _cell(p['bill_id']?.toString() ?? "-"),
              _cell(p['payment_date']?.toString() ?? "-"),
              _cell(p['paid_amount'].toString()),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _cell(String text, {bool header = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
