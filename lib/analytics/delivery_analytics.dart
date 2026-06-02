class DeliveryAnalytics {
  int averageDeliveryMinutes(List<int> deliveryMinutes) {
    if (deliveryMinutes.isEmpty) return 0;
    final total = deliveryMinutes.reduce((a, b) => a + b);
    return (total / deliveryMinutes.length).round();
  }
}
