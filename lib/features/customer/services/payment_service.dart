import '../../../services/api_service.dart';

class PaymentService {
  PaymentService({ApiService? api}) : api = api ?? ApiService();
  final ApiService api;

  Future<Map<String, dynamic>> createCashfreeOrder({
    required int amountInPaise,
    required String token,
    String currency = 'INR',
    String? receipt,
    String? email,
    String? contact,
    String? address,
  }) async {
    return await api.post(
          '/payments/cashfree/create-order',
          token: token,
          body: {
            'amount': amountInPaise,
            'currency': currency,
            if (receipt != null) 'receipt': receipt,
            if (email != null) 'email': email,
            if (contact != null) 'contact': contact,
            if (address != null) 'address': address,
          },
        )
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cashfreeOrderStatus({
    required String token,
    required String orderId,
  }) async {
    return await api.get('/payments/cashfree/status/$orderId', token: token)
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> placeCodOrder(
    double amount,
    String token,
  ) async {
    return await api.post(
          '/payments/cod',
          token: token,
          body: {'amount': amount},
        )
        as Map<String, dynamic>;
  }
}
