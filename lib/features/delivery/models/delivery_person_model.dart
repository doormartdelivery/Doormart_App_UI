class DeliveryPersonModel {
  const DeliveryPersonModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicleNumber,
    required this.status,
    required this.isOnline,
    required this.active,
    required this.completedOrders,
    required this.todayEarnings,
    this.vendorId = 'main',
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String phone;
  final String vehicleNumber;
  final String status;
  final bool isOnline;
  final bool active;
  final int completedOrders;
  final double todayEarnings;
  final String vendorId;
  final String? avatarUrl;

  factory DeliveryPersonModel.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String? ?? 'offline';
    return DeliveryPersonModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Delivery Person',
      phone: json['phone'] as String? ?? '',
      vehicleNumber:
          json['vehicleNumber'] as String? ??
          json['vehicle_number'] as String? ??
          '',
      status: status,
      isOnline: json['isOnline'] as bool? ?? status.toLowerCase() == 'online',
      active: json['active'] as bool? ?? status.toLowerCase() == 'active',
      completedOrders:
          (json['completedOrders'] as num? ??
                  json['todayCompletedOrders'] as num? ??
                  0)
              .toInt(),
      todayEarnings: (json['todayEarnings'] as num? ?? 0).toDouble(),
      vendorId: json['vendorId'] as String? ?? 'main',
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar'] as String?,
    );
  }
}
