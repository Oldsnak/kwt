// lib/core/utils/local_storage_helper.dart

import 'package:shared_preferences/shared_preferences.dart';

/// Simple wrapper around SharedPreferences
/// Reserved bill number ko store / load / clear karne ke liye.
class LocalStorageHelper {
  LocalStorageHelper._(); // private constructor (no instances)

  // Keys ka prefix (per-user bill reservation)
  static const String _reservedBillPrefix = 'reserved_bill_no_';
  static const String _reservedBillTimePrefix = 'reserved_bill_ts_';

  /// Build key using userId (taake har user ka bill alag ho)
  static String _billKey(String userId) => '$_reservedBillPrefix$userId';
  static String _billTimeKey(String userId) =>
      '$_reservedBillTimePrefix$userId';

  // ---------------------------------------------------------------------------
  // GENERIC HELPERS (agar future mein dusri cheezen bhi store karni hon)
  // ---------------------------------------------------------------------------

  static Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  // ---------------------------------------------------------------------------
  // RESERVED BILL NUMBER HELPERS
  // ---------------------------------------------------------------------------

  /// Reserved bill number save karega for given userId.
  ///
  /// Option A ke mutabiq:
  /// - app reload / restart / logout-login → same bill no. milta rahega
  /// - jab tak hum explicitly clear na karein (finalize ke baad).
  static Future<void> saveReservedBillNo({
    required String userId,
    required String billNo,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_billKey(userId), billNo);

    // Option A main timestamp zaroori nahi, lekin debug / future ke liye rakh rahe hain
    final now = DateTime.now().toIso8601String();
    await prefs.setString(_billTimeKey(userId), now);
  }

  /// Reserved bill number wapas dega.
  /// - Agar kuch nahi mila → null return karega.
  static Future<String?> getReservedBillNo({required String userId}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_billKey(userId));
  }

  /// Finalize / discard ke baad reserved bill clear karne ke liye.
  static Future<void> clearReservedBillNo({required String userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_billKey(userId));
    await prefs.remove(_billTimeKey(userId));
  }
}
