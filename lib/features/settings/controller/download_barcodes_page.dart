import 'dart:io';
import 'dart:typed_data';
import 'package:barcode/barcode.dart';
import 'package:barcode_image/barcode_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kwt/app/theme/colors.dart';


class DownloadBarcodesPage extends StatefulWidget {
  const DownloadBarcodesPage({super.key});

  @override
  State<DownloadBarcodesPage> createState() => _DownloadBarcodesPageState();
}

class _DownloadBarcodesPageState extends State<DownloadBarcodesPage> {
  final SupabaseClient _client = Supabase.instance.client;

  bool isDownloading = false;
  int downloaded = 0;
  int skipped = 0;

  Future<bool> _ensurePermission() async {
    if (!Platform.isAndroid) return true;

    var status = await Permission.storage.request();
    if (status.isGranted) return true;

    await openAppSettings();
    return false;
  }

  Future<void> _downloadAllBarcodes() async {
    setState(() => isDownloading = true);

    try {
      if (!await _ensurePermission()) {
        Get.snackbar("Permission Required", "Cannot save barcodes");
        return;
      }

      // Save directory
      final dir = Directory("/storage/emulated/0/Download/KWT_Barcodes");
      if (!await dir.exists()) await dir.create(recursive: true);

      // Fetch products
      final products =
      await _client.from("products").select("id, name, barcode");

      if (products.isEmpty) {
        Get.snackbar("No Products", "No products found");
        return;
      }

      final barcode = Barcode.code128();

      for (final p in products) {
        final code = p["barcode"];
        if (code == null || code.toString().isEmpty) continue;

        final path = "${dir.path}/$code.png";
        final file = File(path);

        if (await file.exists()) {
          skipped++;
          continue;
        }

        // Create blank image (white background)
        final img.Image canvas =
        img.Image(width: 600, height: 200); // RGB image
        img.fill(canvas, color: img.ColorRgb8(255, 255, 255));

        // Draw barcode on image
        drawBarcode(
          canvas,
          barcode,
          code.toString(),
          font: img.arial24,
          x: 40,
          y: 20,
          width: 520,
          height: 140,
        );

        // Convert to PNG
        final Uint8List pngBytes = Uint8List.fromList(img.encodePng(canvas));

        // Save file
        await file.writeAsBytes(pngBytes);
        downloaded++;
      }

      Get.snackbar(
        "Done",
        "$downloaded barcodes saved, $skipped skipped.",
        backgroundColor: SColors.primary,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      setState(() => isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: isDownloading
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Downloading..."),
          ],
        )
            : ElevatedButton.icon(
          onPressed: _downloadAllBarcodes,
          icon: const Icon(Icons.download),
          label: const Text("Download All Barcodes"),
          style: ElevatedButton.styleFrom(
            backgroundColor: SColors.primary,
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 14),
          ),
        ),
      ),
    );
  }
}
