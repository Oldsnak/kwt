import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class DeviceIdentifier {
  static Future<String> getId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      return info.id ?? info.device;
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      return info.identifierForVendor ?? 'unknown_ios_device';
    } else {
      return 'unknown_device';
    }
  }

  static Future<String> getName() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      return '${info.brand} ${info.model}';
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      return info.name ?? 'iOS_Device';
    } else {
      return 'Unknown Device';
    }
  }
}
