class DeviceModel {
  final String id;
  final String deviceName;
  final String deviceUid;
  final bool isAuthorized;
  final DateTime? createdAt;

  DeviceModel({
    required this.id,
    required this.deviceName,
    required this.deviceUid,
    required this.isAuthorized,
    this.createdAt,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) => DeviceModel(
    id: json['id'] as String,
    deviceName: json['device_name'] as String,
    deviceUid: json['device_uid'] as String,
    isAuthorized: json['is_authorized'] as bool,
    createdAt: json['created_at'] == null ? null : DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'device_name': deviceName,
    'device_uid': deviceUid,
    'is_authorized': isAuthorized,
    'created_at': createdAt?.toIso8601String(),
  };

  DeviceModel copyWith({
    String? id,
    String? deviceName,
    String? deviceUid,
    bool? isAuthorized,
    DateTime? createdAt,
  }) =>
      DeviceModel(
        id: id ?? this.id,
        deviceName: deviceName ?? this.deviceName,
        deviceUid: deviceUid ?? this.deviceUid,
        isAuthorized: isAuthorized ?? this.isAuthorized,
        createdAt: createdAt ?? this.createdAt,
      );
}