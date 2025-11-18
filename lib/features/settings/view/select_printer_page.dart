import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:kwt/core/services/thermal_printer_service.dart';

class SelectPrinterPage extends StatefulWidget {
  const SelectPrinterPage({super.key});

  @override
  State<SelectPrinterPage> createState() => _SelectPrinterPageState();
}

class _SelectPrinterPageState extends State<SelectPrinterPage> {
  List<BluetoothDevice> devices = [];
  BluetoothDevice? selected;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => isLoading = true);
    final list = await ThermalPrinterService.getBondedDevices();
    setState(() {
      devices = list;
      isLoading = false;
    });
  }

  Future<void> _connect() async {
    if (selected == null) return;

    setState(() => isLoading = true);
    final ok = await ThermalPrinterService.connect(selected!);
    setState(() => isLoading = false);

    if (ok) {
      Get.snackbar("Printer", "Connected to ${selected!.name}");
      Get.back(); // close page
    } else {
      Get.snackbar("Printer", "Failed to connect");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Bluetooth Printer"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          if (devices.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("No paired Bluetooth devices found.\n"
                  "Pair your printer from phone Bluetooth settings."),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (_, i) {
                  final d = devices[i];
                  final isSelected = d == selected;
                  return ListTile(
                    title: Text(d.name ?? "Unknown"),
                    subtitle: Text(d.address ?? ""),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () {
                      setState(() {
                        selected = d;
                      });
                    },
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selected == null ? null : _connect,
                child: const Text("Connect"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
