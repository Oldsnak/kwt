class UserProfile {
  final String id;
  final String fullName;
  final String? phone;
  final String role;
  final bool isAdmin;
  final bool isActive;

  UserProfile({
    required this.id,
    required this.fullName,
    this.phone,
    required this.role,
    required this.isAdmin,
    required this.isActive,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      fullName: map['full_name'] ?? '',
      phone: map['phone'],
      role: map['role'] ?? '',
      isAdmin: map['is_admin'] ?? false,
      isActive: map['is_active'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'is_admin': isAdmin,
      'is_active': isActive,
    };
  }
}
