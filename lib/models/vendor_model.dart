import 'dart:convert';

class VendorModel {
  const VendorModel({
    required this.id,
    required this.name,
    required this.vendorId,
    this.ownerName = '',
    this.phone = '',
    this.email,
    this.businessType = '',
    this.gstin = '',
    this.panNumber = '',
    this.address = '',
    this.pickupAddress = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.pickupLatitude,
    this.pickupLongitude,
    this.logoUrl = '',
    this.gstCertificateUrl = '',
    this.panCardUrl = '',
    this.cancelledChequeUrl = '',
    this.bankAccountHolderName = '',
    this.bankAccountNumber = '',
    this.ifscCode = '',
    this.commissionPercent = 0,
    this.approvalStatus = 'pending',
    this.isActive = true,
    this.rejectionReason = '',
    this.approvedBy,
    this.approvedAt,
    this.adminCount = 0,
    this.productCount = 0,
    this.orderCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String vendorId;
  final String ownerName;
  final String phone;
  final String? email;
  final String businessType;
  final String gstin;
  final String panNumber;
  final String address;
  final String pickupAddress;
  final String city;
  final String state;
  final String pincode;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String logoUrl;
  final String gstCertificateUrl;
  final String panCardUrl;
  final String cancelledChequeUrl;
  final String bankAccountHolderName;
  final String bankAccountNumber;
  final String ifscCode;
  final double commissionPercent;
  final String approvalStatus;
  final bool isActive;
  final String rejectionReason;
  final String? approvedBy;
  final DateTime? approvedAt;
  final int adminCount;
  final int productCount;
  final int orderCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      id: json['_id'] as String? ?? json['id'] as String,
      name: json['name'] as String? ?? '',
      vendorId: json['vendorId'] as String? ?? '',
      ownerName: json['ownerName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      businessType: json['businessType'] as String? ?? '',
      gstin: json['gstin'] as String? ?? '',
      panNumber: json['panNumber'] as String? ?? '',
      address: json['address'] as String? ?? '',
      pickupAddress: json['pickupAddress'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      pickupLatitude: _asDouble(json['pickupLatitude'] ?? json['latitude']),
      pickupLongitude: _asDouble(json['pickupLongitude'] ?? json['longitude']),
      logoUrl: json['logoUrl'] as String? ?? '',
      gstCertificateUrl: json['gstCertificateUrl'] as String? ?? '',
      panCardUrl: json['panCardUrl'] as String? ?? '',
      cancelledChequeUrl: json['cancelledChequeUrl'] as String? ?? '',
      bankAccountHolderName: json['bankAccountHolderName'] as String? ?? '',
      bankAccountNumber: json['bankAccountNumber'] as String? ?? '',
      ifscCode: json['ifscCode'] as String? ?? '',
      commissionPercent: (json['commissionPercent'] as num?)?.toDouble() ?? 0,
      approvalStatus: json['approvalStatus'] as String? ?? 'pending',
      isActive: json['isActive'] as bool? ?? true,
      rejectionReason: json['rejectionReason'] as String? ?? '',
      approvedBy: json['approvedBy']?.toString(),
      approvedAt: DateTime.tryParse(json['approvedAt'] as String? ?? ''),
      adminCount: (json['adminCount'] as num?)?.toInt() ?? 0,
      productCount: (json['productCount'] as num?)?.toInt() ?? 0,
      orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'vendorId': vendorId,
    'ownerName': ownerName,
    'phone': phone,
    'email': email,
    'businessType': businessType,
    'gstin': gstin,
    'panNumber': panNumber,
    'address': address,
    'pickupAddress': pickupAddress,
    'city': city,
    'state': state,
    'pincode': pincode,
    'pickupLatitude': pickupLatitude,
    'pickupLongitude': pickupLongitude,
    'logoUrl': logoUrl,
    'gstCertificateUrl': gstCertificateUrl,
    'panCardUrl': panCardUrl,
    'cancelledChequeUrl': cancelledChequeUrl,
    'bankAccountHolderName': bankAccountHolderName,
    'bankAccountNumber': bankAccountNumber,
    'ifscCode': ifscCode,
    'commissionPercent': commissionPercent,
    'approvalStatus': approvalStatus,
    'isActive': isActive,
    'rejectionReason': rejectionReason,
    'approvedBy': approvedBy,
    'approvedAt': approvedAt?.toIso8601String(),
  };

  String toStorage() => jsonEncode(toJson());

  factory VendorModel.fromStorage(String raw) {
    return VendorModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  String get status => isActive ? 'active' : 'inactive';
}

double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
