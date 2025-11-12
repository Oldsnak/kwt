// lib/core/services/print_service.dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PrintService {
  // Create simple receipt PDF
  Future<pw.Document> createReceipt({
    required String billNo,
    required String cashier,
    required List<Map<String, dynamic>> items, // each: {name, qty, rate, discount, total}
    required double total,
  }) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(build: (pw.Context ctx) {
      return pw.Column(children: [
        pw.Text('Shop Name', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('Bill: $billNo'),
        pw.Text('Cashier: $cashier'),
        pw.SizedBox(height: 8),
        pw.Divider(),
        pw.Column(
          children: items.map((it) {
            return pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('${it['name']} x${it['qty']}'),
              pw.Text(it['total'].toString()),
            ]);
          }).toList(),
        ),
        pw.Divider(),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('Total'),
          pw.Text(total.toStringAsFixed(2)),
        ]),
      ]);
    }));

    return doc;
  }

  // Print directly (opens native print dialog / or sends to connected printer)
  Future<void> printReceiptPdf(pw.Document doc) async {
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

// For ESC/POS printers you must use esc_pos_printer package and network/BT specifics
}
