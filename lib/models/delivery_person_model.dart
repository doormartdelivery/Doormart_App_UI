class DeliveryPersonModel {
  const DeliveryPersonModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.active,
    required this.completedOrders,
    this.vendorId = 'main',
  });

  final String id;
  final String name;
  final String phone;
  final bool active;
  final int completedOrders;
  final String vendorId;
}
