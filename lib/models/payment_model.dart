class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.method,
    required this.status,
    required this.amount,
  });
  final String id;
  final String method;
  final String status;
  final double amount;
}
