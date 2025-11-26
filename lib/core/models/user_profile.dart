class UserProfile {
  final String id;          // auth.user.id (uuid)
  final String fullName;
  final String? phone;
  final String? email;       // NEW (sometimes needed in UI)
  final String role;        // owner / salesperson
  final bool isAdmin;       // owner = true, salesperson = false
  final bool isActive;      // blocked/unblocked
  final DateTime? createdAt;

  UserProfile({
    required this.id,
    required this.fullName,
    this.phone,
    this.email,
    required this.role,
    required this.isAdmin,
    required this.isActive,
    this.createdAt,
  });

  // ---------------------------------------------------------------------------
  // Factory: Safe Map → Model conversion
  // ---------------------------------------------------------------------------
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id']?.toString() ?? "",
      fullName: map['full_name']?.toString() ?? "",
      phone: map['phone']?.toString(),
      email: map['email']?.toString(),                // NEW
      role: map['role']?.toString() ?? "",
      isAdmin: map['is_admin'] as bool? ?? false,
      isActive: map['is_active'] as bool? ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Convert Model → Map (for insert/update)
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'role': role,
      'is_admin': isAdmin,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------
  UserProfile copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    String? role,
    bool? isAdmin,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      isAdmin: isAdmin ?? this.isAdmin,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
