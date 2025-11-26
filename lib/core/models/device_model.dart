class DeviceModel {
  final String id;              // Supabase uuid
  final String deviceName;      // Friendly device name
  final String deviceUid;       // Unique Device Identifier
  final bool isAuthorized;      // Approved by owner?
  final DateTime? createdAt;    // Auto timestamp from Supabase

  DeviceModel({
    required this.id,
    required this.deviceName,
    required this.deviceUid,
    required this.isAuthorized,
    this.createdAt,
  });

  // ---------------------------------------------------------------------------
  // FROM JSON (safe)
  // ---------------------------------------------------------------------------
  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String,
      deviceName: json['device_name'] ?? '',
      deviceUid: json['device_uid'] ?? '',
      isAuthorized: json['is_authorized'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // TO JSON (insert/update)
  // ⚠️ Do NOT send `id` or `created_at` → Supabase auto handles
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      'device_name': deviceName,
      'device_uid': deviceUid,
      'is_authorized': isAuthorized,
    };
  }

  // ---------------------------------------------------------------------------
  // COPY WITH
  // ---------------------------------------------------------------------------
  DeviceModel copyWith({
    String? id,
    String? deviceName,
    String? deviceUid,
    bool? isAuthorized,
    DateTime? createdAt,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      deviceName: deviceName ?? this.deviceName,
      deviceUid: deviceUid ?? this.deviceUid,
      isAuthorized: isAuthorized ?? this.isAuthorized,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
