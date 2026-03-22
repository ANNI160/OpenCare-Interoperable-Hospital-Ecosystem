class UserModel {
  final String id;
  final String name;
  final String email;
  final String employeeId;
  final String role;
  final String? assignedWard;
  final String? profileImage;
  final String? specialization;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isOnline;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.employeeId,
    required this.role,
    this.assignedWard,
    this.profileImage,
    this.specialization,
    this.isActive = true,
    required this.createdAt,
    this.lastLoginAt,
    this.isOnline = false,
  });

  bool get isNurse => role == 'nurse';
  bool get isDoctor => role == 'doctor';
  bool get isAdmin => role == 'admin';
  bool get isPatient => role == 'patient';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      employeeId: json['employee_id'] ?? '',
      role: json['role'] ?? '',
      assignedWard: json['assigned_ward'],
      profileImage: json['profile_image'],
      specialization: json['specialization'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      lastLoginAt: json['last_login_at'] != null ? DateTime.parse(json['last_login_at']) : null,
      isOnline: json['is_online'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'employee_id': employeeId,
    'role': role,
    'assigned_ward': assignedWard,
    'profile_image': profileImage,
    'specialization': specialization,
    'is_active': isActive,
    'is_online': isOnline,
  };
}
