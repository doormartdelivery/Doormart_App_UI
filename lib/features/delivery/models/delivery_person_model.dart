class DeliveryPersonModel {
  const DeliveryPersonModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicleNumber,
    required this.status,
    required this.active,
    required this.completedOrders,
    required this.todayEarnings,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String phone;
  final String vehicleNumber;
  final String status;
  final bool active;
  final int completedOrders;
  final double todayEarnings;
  final String? avatarUrl;

  bool get isOnline => status.toLowerCase() == 'online';

  factory DeliveryPersonModel.fromJson(Map<String, dynamic> json) {
    return DeliveryPersonModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Delivery Person',
      phone: json['phone'] as String? ?? '',
      vehicleNumber: json['vehicleNumber'] as String? ?? json['vehicle_number'] as String? ?? '',
      status: json['status'] as String? ?? 'offline',
      active: json['active'] as bool? ?? (json['status'] as String? ?? 'offline').toLowerCase() == 'active',
      completedOrders: (json['completedOrders'] as num? ?? json['todayCompletedOrders'] as num? ?? 0).toInt(),
      todayEarnings: (json['todayEarnings'] as num? ?? 0).toDouble(),
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar'] as String?,
    );
  }
}
