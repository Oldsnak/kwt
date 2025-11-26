class Salesperson {
  final String id;               // auth + profile uuid
  final String fullName;
  final String? email;           // mostly null for salesperson
  final String? phone;
  final bool? isActive;          // safe-parsed bool
  final DateTime? createdAt;

  Salesperson({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.isActive,
    this.createdAt,
  });

  // =============================================================
  // FROM MAP (safe for Supabase dynamic rows)
  // =============================================================
  factory Salesperson.fromJson(Map<String, dynamic> json) {
    // --- Safe bool parser (fix) ---
    bool? parseBool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is String) return v.toLowerCase() == "true";
      return null;
    }

    return Salesperson(
      id: json['id'] as String,
      fullName: json['full_name'] ?? '',
      email: json['email'], // unused but preserved
      phone: json['phone'],
      isActive: parseBool(json['is_active']), // FIXED
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  // =============================================================
  // TO MAP
  // =============================================================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  // =============================================================
  // COPY WITH
  // =============================================================
  Salesperson copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Salesperson(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
