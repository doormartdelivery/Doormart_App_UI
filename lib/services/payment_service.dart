import 'api_service.dart';

class PaymentService {
  PaymentService({ApiService? api}) : api = api ?? ApiService();
  final ApiService api;

  Future<Map<String, dynamic>> createRazorpayOrder(
    double amount,
    String token,
  ) async {
    return await api.post(
          '/payments/razorpay/order',
          token: token,
          body: {'amount': amount},
        )
        as Map<String, dynamic>;
  }
}
