class ScheduledOrderModel {
  const ScheduledOrderModel({
    required this.id,
    required this.title,
    required this.frequency,
    required this.active,
  });
  final String id;
  final String title;
  final String frequency;
  final bool active;
}
