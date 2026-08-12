import 'dart:convert';

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.vendorId = 'main',
    this.email,
    this.avatarUrl = '',
    this.status = 'active',
    this.approvalStatus = 'approved',
    this.isActive = true,
    this.rejectionReason = '',
    this.approvedBy,
    this.approvedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String phone;
  final String role;
  final String vendorId;
  final String? email;
  final String avatarUrl;
  final String status;
  final String approvalStatus;
  final bool isActive;
  final String rejectionReason;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String? ?? json['id'] as String,
      name: json['name'] as String? ?? 'User',
      phone: json['phone'] as String? ?? '',
      role: _normalizeRole(json['role'] as String?),
      vendorId: json['vendorId'] as String? ?? 'main',
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      approvalStatus: json['approvalStatus'] as String? ?? 'approved',
      isActive: json['isActive'] as bool? ?? true,
      rejectionReason: json['rejectionReason'] as String? ?? '',
      approvedBy: json['approvedBy']?.toString(),
      approvedAt: DateTime.tryParse(json['approvedAt'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'role': role,
    'vendorId': vendorId,
    'email': email,
    'avatarUrl': avatarUrl,
    'status': status,
    'approvalStatus': approvalStatus,
    'isActive': isActive,
    'rejectionReason': rejectionReason,
    'approvedBy': approvedBy,
    'approvedAt': approvedAt?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  String toStorage() => jsonEncode(toJson());

  factory UserModel.fromStorage(String raw) {
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}

String _normalizeRole(String? role) {
  switch ((role ?? '').toLowerCase()) {
    case 'delivery':
    case 'delivery_person':
      return 'delivery_person';
    case 'superadmin':
    case 'super_admin':
      return 'super_admin';
    case 'admin':
      return 'admin';
    case 'vendor':
      return 'vendor';
    case 'user':
    default:
      return 'user';
  }
}
