import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PrintBillService {
  static Future<void> printBill({
    required String billNo,
    required List<Map<String, dynamic>> items,
    required double subTotal,
    required double discount,
    required double total,
    required String customer,
  }) async {
    final pdf = pw.Document();
    final date = DateFormat("dd/MM/yyyy hh:mm a").format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text("KASHMIR WAIPERS TRADORS",
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Center(
                child: pw.Text("Bansan Wala Bazar, Alam Chowk, Gujranwala",
                    style: pw.TextStyle(fontSize: 12)),
              ),
              pw.Center(
                child: pw.Text("Phone: 03206578951", style: pw.TextStyle(fontSize: 12)),
              ),
              pw.SizedBox(height: 12),

              pw.Text("Bill No: $billNo", style: pw.TextStyle(fontSize: 14)),
              pw.Text("Date: $date", style: pw.TextStyle(fontSize: 12)),
              pw.Text("Customer: ${customer.isEmpty ? "Walking Customer" : customer}",
                  style: pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 10),

              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(),
                  data: billNo,
                  width: 180,
                  height: 60,
                ),
              ),

              pw.SizedBox(height: 12),
              pw.Divider(),

              pw.Table(
                border: pw.TableBorder(),
                columnWidths: {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(1.2),
                  2: pw.FlexColumnWidth(1.2),
                  3: pw.FlexColumnWidth(1.8),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text("Item")),
                      pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text("Qty")),
                      pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text("Rate")),
                      pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text("Total")),
                    ],
                  ),
                  ...items.map(
                        (item) => pw.TableRow(
                      children: [
                        pw.Padding(
                            padding: pw.EdgeInsets.all(3),
                            child: pw.Text(item['name'].toString())),
                        pw.Padding(
                            padding: pw.EdgeInsets.all(3),
                            child: pw.Text(item['pieces'].toString())),
                        pw.Padding(
                            padding: pw.EdgeInsets.all(3),
                            child: pw.Text(item['price'].toString())),
                        pw.Padding(
                            padding: pw.EdgeInsets.all(3),
                            child: pw.Text(item['total'].toString())),
                      ],
                    ),
                  )
                ],
              ),

              pw.SizedBox(height: 12),
              pw.Divider(),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Sub Total:"),
                  pw.Text(subTotal.toStringAsFixed(2)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Discount:"),
                  pw.Text(discount.toStringAsFixed(2)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Grand Total:",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(total.toStringAsFixed(2),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text("Thank you for shopping!")),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
