import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class WhatsAppShareService {

  /// 🔥 Generate a BILL PDF and Share via WhatsApp
  static Future<void> shareBillViaWhatsApp({
    required String billNo,
    required String customer,
    required double subTotal,
    required double discount,
    required double total,
    required List<Map<String, dynamic>> items,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) =>
            _buildBillLayout(billNo, customer, subTotal, discount, total, items),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/BILL_$billNo.pdf");

    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: "Here's your bill: $billNo",
    );
  }

  /// 🔥 BILL PDF LAYOUT
  static pw.Widget _buildBillLayout(
      String billNo,
      String customer,
      double subTotal,
      double discount,
      double total,
      List<Map<String, dynamic>> items,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [

        pw.Center(
          child: pw.Text("KWT",
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              )),
        ),

        pw.SizedBox(height: 10),

        pw.Text("Bill No: $billNo"),
        pw.Text("Customer: $customer"),
        pw.SizedBox(height: 20),

        pw.Text("Items:",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.Divider(),

        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(children: [
              pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text("Item")),
              pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text("Qty")),
              pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text("Price")),
              pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text("Total")),
            ]),
            ...items.map((e) {
              return pw.TableRow(children: [
                pw.Padding(
                    padding: pw.EdgeInsets.all(4), child: pw.Text(e['name'])),
                pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text("${e['pieces']}")),
                pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text("${e['price']}")),
                pw.Padding(
                    padding: pw.EdgeInsets.all(4),
                    child: pw.Text("${e['total']}")),
              ]);
            }).toList(),
          ],
        ),

        pw.SizedBox(height: 20),
        pw.Divider(),

        pw.Text("Subtotal: Rs $subTotal"),
        pw.Text("Discount: Rs $discount"),
        pw.Text("Grand Total: Rs $total",
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}
