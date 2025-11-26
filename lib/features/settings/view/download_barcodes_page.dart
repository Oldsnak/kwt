import 'dart:typed_data';
import 'dart:io';
import 'package:barcode/barcode.dart';
import 'package:barcode_image/barcode_image.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
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

  // ------------------------------------------------------------
  // PERMISSIONS
  // ------------------------------------------------------------
  Future<bool> _ensurePermission() async {
    if (!GetPlatform.isAndroid) return true;

    // Try photos permission (Android 13+), then storage (older)
    final photosStatus = await Permission.photos.request();
    if (photosStatus.isGranted) return true;

    final storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted) return true;

    Get.snackbar("Permission Required", "Please allow storage permission.");
    openAppSettings();
    return false;
  }

  // ------------------------------------------------------------
  // SAVE IMAGE TO TEMP FILE
  // ------------------------------------------------------------
  Future<String> _saveTempImage(Uint8List bytes, String name) async {
    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/$name.png");
    await file.writeAsBytes(bytes);
    return file.path;
  }

  // ------------------------------------------------------------
  // MAIN DOWNLOAD LOGIC
  // ------------------------------------------------------------
  Future<void> _downloadAllBarcodes() async {
    if (isDownloading) return;

    setState(() {
      isDownloading = true;
      downloaded = 0;
      skipped = 0;
    });

    try {
      // 🔹 If permission denied, stop and reset state
      final ok = await _ensurePermission();
      if (!ok) {
        setState(() => isDownloading = false);
        return;
      }

      final res = await _client.from("products").select("id, name, barcode");

      final List<Map<String, dynamic>> products =
      (res as List).map((e) => Map<String, dynamic>.from(e)).toList();

      if (products.isEmpty) {
        Get.snackbar("No Products", "No products found in database");
        return;
      }

      final barcode = Barcode.code128();

      for (final p in products) {
        final code = p["barcode"];
        if (code == null || code.toString().isEmpty) {
          skipped++;
          continue;
        }

        // CREATE IMAGE
        final img.Image canvas = img.Image(width: 600, height: 200);
        img.fill(canvas, color: img.ColorRgb8(255, 255, 255));

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

        final Uint8List pngBytes =
        Uint8List.fromList(img.encodePng(canvas));

        // SAVE TO TEMP FILE FIRST
        final path = await _saveTempImage(pngBytes, "KWT_$code");

        // SAVE TO GALLERY
        final saved = await GallerySaver.saveImage(
          path,
          albumName: "KWT Barcodes",
        );

        if (saved == true) {
          downloaded++;
        } else {
          skipped++;
        }
      }

      Get.snackbar(
        "Completed",
        "$downloaded saved, $skipped skipped.",
        backgroundColor: SColors.primary,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      setState(() => isDownloading = false);
    }
  }

  // ------------------------------------------------------------
  // UI (UNCHANGED)
  // ------------------------------------------------------------
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
            Text("Downloading & saving barcodes..."),
          ],
        )
            : ElevatedButton.icon(
          onPressed: _downloadAllBarcodes,
          icon: const Icon(Icons.download),
          label: const Text("Download All Barcodes"),
          style: ElevatedButton.styleFrom(
            backgroundColor: SColors.primary,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }
}
