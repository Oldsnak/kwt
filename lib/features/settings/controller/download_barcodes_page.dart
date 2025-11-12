import 'dart:io';
import 'dart:typed_data';
import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  Future<bool> _ensureStoragePermission() async {
    if (!Platform.isAndroid) return true;

    // ✅ Android 13+ uses different permission types
    final manage = await Permission.manageExternalStorage.request();
    if (manage.isGranted) return true;

    final storage = await Permission.storage.request();
    if (storage.isGranted) return true;

    final photos = await Permission.photos.request();
    if (photos.isGranted) return true;

    final videos = await Permission.videos.request();
    if (videos.isGranted) return true;

    // If all denied
    await openAppSettings();
    return false;
  }

  Future<void> _downloadAllBarcodes() async {
    setState(() => isDownloading = true);

    try {
      final granted = await _ensureStoragePermission();
      if (!granted) {
        Get.snackbar("Permission Denied", "Cannot save barcodes without permission");
        setState(() => isDownloading = false);
        return;
      }

      // Create directory
      final dir = Directory("/storage/emulated/0/Download/KWT_Barcodes");
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Fetch all products
      final products = await _client.from('products').select('id, name, barcode');

      if (products.isEmpty) {
        Get.snackbar("No Products", "No products found in database");
        setState(() => isDownloading = false);
        return;
      }

      final barcodeGenerator = Barcode.code128();

      for (final product in products) {
        final code = product['barcode'];
        if (code == null || code.toString().isEmpty) continue;

        final filePath = "${dir.path}/${code.toString()}.png";
        final file = File(filePath);

        // Skip if already exists
        if (await file.exists()) {
          skipped++;
          continue;
        }

        // Generate barcode image
        final svg = barcodeGenerator.toSvg(code, width: 300, height: 120);
        final bytes = Uint8List.fromList(svg.codeUnits);

        await file.writeAsBytes(bytes);
        downloaded++;
      }

      Get.snackbar(
        "Download Complete",
        "$downloaded new barcodes saved, $skipped skipped.",
        backgroundColor: SColors.primary,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar("Error", "Failed to download barcodes: $e");
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
            Text("Downloading barcodes..."),
          ],
        )
            : ElevatedButton.icon(
          icon: const Icon(Icons.download),
          label: const Text("Download All Barcodes"),
          style: ElevatedButton.styleFrom(
            backgroundColor: SColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          onPressed: _downloadAllBarcodes,
        ),
      ),
    );
  }
}
