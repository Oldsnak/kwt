// lib/core/services/notification_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class NotificationService {
  final SupabaseClient client = SupabaseService.client;

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

  // Low stock detector
  Future<void> checkLowStock({int threshold = 10}) async {
    final res = await client.from('products').select().lte('stock_quantity', threshold);
    final List list = (res as List);
    for (final p in list) {
      await createNotification(
        type: 'low_stock',
        title: 'Low stock: ${p['name']}',
        message: 'Only ${p['stock_quantity']} left in store',
        meta: {'product_id': p['id']},
      );
    }
  }

  // Price rise detector: compare latest stock_entries purchase_rate with previous (simple check)
  Future<void> checkPriceRise() async {
    // simple approach: for each product get latest two stock_entries and compare
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
            title: 'Purchase price rose for ${prod['name']}',
            message: 'New purchase rate ${latest.toStringAsFixed(2)} (was ${prev.toStringAsFixed(2)})',
            meta: {'product_id': pid},
          );
        }
      }
    }
  }

  // Overdue customer detector
  Future<void> checkOverdueCustomers({int overdueDays = 30}) async {
    final rows = await client.from('customer_debts').select('*, customers(*)');
    for (final r in (rows as List)) {
      final dueDate = r['due_date'] == null ? null : DateTime.parse(r['due_date']);
      if (dueDate != null && DateTime.now().difference(dueDate).inDays >= overdueDays) {
        await createNotification(
          type: 'overdue_customer',
          title: 'Overdue customer: ${r['customers']['name']}',
          message: 'Customer has pending amount ${r['debt_amount']} since ${r['due_date']}',
          meta: {'customer_id': r['customer_id'], 'debt_id': r['id']},
        );
      }
    }
  }

  // Generate PDF and open WhatsApp share link (simplified)
  Future<void> sendStatementWhatsApp(String customerId, String phoneNumber) async {
    // 1) fetch debts & payments
    final debts = await client.from('customer_debts').select().eq('customer_id', customerId);
    final payments = await client.from('customer_payments').select().eq('customer_id', customerId);

    // 2) make a simple PDF (using pdf package)
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(build: (pw.Context ctx) {
        return pw.Column(
          children: [
            pw.Text('Statement'),
            pw.Text('Customer ID: $customerId'),
            pw.SizedBox(height: 10),
            pw.Text('Debts:'),
            pw.ListView.builder(
              itemCount: (debts as List).length,
              itemBuilder: (context, i) {
                final d = debts[i];
                return pw.Text('${d['bill_no']} - ${d['debt_amount']} - ${d['due_date']}');
              },
            ),
            pw.SizedBox(height: 10),
            pw.Text('Payments:'),
            pw.ListView.builder(
              itemCount: (payments as List).length,
              itemBuilder: (context, i) {
                final p = payments[i];
                return pw.Text('${p['payment_date']} - ${p['paid_amount']}');
              },
            ),
          ],
        );
      }),
    );

    // 3) share via whatsapp: Printing package can convert pdf to bytes
    final bytes = await pdf.save();

    // Save or share — simplest: generate data: URL and open whatsapp with prefilled text + offer user to attach pdf manually
    final encoded = Uri.encodeComponent('Your account statement attached.'); // we can't attach file via url launcher easily
    final whatsappUrl = 'https://wa.me/$phoneNumber?text=$encoded';
    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
    } else {
      throw 'Could not open WhatsApp';
    }

    // NOTE: attaching a PDF via WhatsApp programmatically is complex on Android; better to generate PDF,
    // save to device, then use share plugin to share with whatsapp. (Use `share_plus` package.)
  }
}
