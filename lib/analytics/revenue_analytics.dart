class RevenueAnalytics {
  double profit({
    required double revenue,
    required double productCost,
    required double deliveryCost,
  }) {
    return revenue - productCost - deliveryCost;
  }

  double marginPercent({required double revenue, required double profit}) {
    if (revenue == 0) return 0;
    return (profit / revenue) * 100;
  }
}
