import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class ThermalPrinterService {
  static final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  static List<BluetoothDevice> bondedDevices = [];
  static BluetoothDevice? connectedDevice;

  /// 🔹 Load paired devices
  static Future<List<BluetoothDevice>> getBondedDevices() async {
    bondedDevices = await bluetooth.getBondedDevices();
    return bondedDevices;
  }

  /// 🔹 Connect to printer
  static Future<bool> connect(BluetoothDevice device) async {
    try {
      final isConnected = await bluetooth.isConnected;
      if (isConnected == true) {
        await bluetooth.disconnect();
      }
      await bluetooth.connect(device);
      connectedDevice = device;
      return true;
    } catch (e) {
      print("ThermalPrinterService.connect error: $e");
      return false;
    }
  }

  static Future<void> disconnect() async {
    try {
      await bluetooth.disconnect();
      connectedDevice = null;
    } catch (e) {
      print("disconnect error: $e");
    }
  }

  /// 🔥 MAIN PRINT FUNCTION
  static Future<void> printBill({
    required String billNo,
    required List<Map<String, dynamic>> items,
    required double subTotal,
    required double discount,
    required double total,
    required String customer,
  }) async {
    try {
      final isConnected = await bluetooth.isConnected;
      if (!isConnected!) throw "Printer not connected.";

      final now = DateTime.now();
      final dateStr =
          "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year} | "
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      // HEADER
      bluetooth.printNewLine();
      bluetooth.printCustom("KASHMIR WAIPERS TRADORS", 3, 1);
      bluetooth.printCustom("Bansan Wala Bazar, Alam Chowk, Gujranwala", 1, 1);
      bluetooth.printCustom("Phone: 03206578951", 1, 1);
      bluetooth.printNewLine();

      // BILL INFO
      bluetooth.printLeftRight("Bill No:", billNo, 1);
      bluetooth.printLeftRight("Date:", dateStr, 1);
      bluetooth.printLeftRight("Customer:", customer.isEmpty ? "Walking Customer" : customer, 1);
      bluetooth.printNewLine();

      // BARCODE (fallback)
      try {
        bluetooth.printQRcode(billNo, 200, 200, 1);
      } catch (e) {
        bluetooth.printCustom("Code: $billNo", 1, 1);
      }

      bluetooth.printNewLine();
      bluetooth.printCustom("--------------------------------", 1, 1);
      bluetooth.printCustom("ITEM      QTY  RATE  TOTAL", 1, 0);
      bluetooth.printCustom("--------------------------------", 1, 1);

      for (var item in items) {
        bluetooth.printCustom(item["name"], 1, 0);
        bluetooth.printCustom(
          "   ${item['pieces']} x ${item['price']} = ${item['total']}",
          1,
          0,
        );
        if (item['discount'] != 0) {
          bluetooth.printCustom("   Disc: ${item['discount']}", 1, 0);
        }
      }

      bluetooth.printCustom("--------------------------------", 1, 1);

      bluetooth.printLeftRight("Sub Total:", subTotal.toStringAsFixed(2), 1);
      bluetooth.printLeftRight("Discount:", discount.toStringAsFixed(2), 1);
      bluetooth.printLeftRight("GRAND TOTAL:", total.toStringAsFixed(2), 2);

      bluetooth.printNewLine();
      bluetooth.printCustom("Thanks for shopping!", 1, 1);
      bluetooth.printCustom("KASHMIR WAIPERS TRADORS", 1, 1);
      bluetooth.printNewLine();
      bluetooth.printNewLine();
      bluetooth.paperCut();
    } catch (e) {
      print("PRINT ERROR: $e");
      rethrow;
    }
  }
}
