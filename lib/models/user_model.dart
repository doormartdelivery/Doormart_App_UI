import 'dart:convert';

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.email,
    this.avatarUrl = '',
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String phone;
  final String role;
  final String? email;
  final String avatarUrl;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String? ?? json['id'] as String,
      name: json['name'] as String? ?? 'User',
      phone: json['phone'] as String? ?? '',
      role: _normalizeRole(json['role'] as String?),
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'role': role,
    'email': email,
    'avatarUrl': avatarUrl,
    'status': status,
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
    case 'user':
    default:
      return 'user';
  }
}
