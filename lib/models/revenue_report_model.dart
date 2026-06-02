class RevenueReportModel {
  const RevenueReportModel({
    required this.revenue,
    required this.deliveryCost,
    required this.productCost,
  });
  final double revenue;
  final double deliveryCost;
  final double productCost;
  double get profit => revenue - deliveryCost - productCost;
}
