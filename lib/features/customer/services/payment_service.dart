import '../../../services/api_service.dart';

class PaymentService {
  PaymentService({ApiService? api}) : api = api ?? ApiService();
  final ApiService api;

  /// Creates a Stripe Checkout Session.
  /// Returns a map with { sessionId, url }.
  Future<Map<String, dynamic>> createStripeCheckoutSession({
    required int amountInPaise,
    required String token,
    String currency = 'inr',
    String? receipt,
    String? email,
    String? contact,
    String? address,
    String? description,
  }) async {
    return await api.post(
          '/payments/stripe/create-checkout-session',
          token: token,
          body: {
            'amount': amountInPaise,
            'currency': currency,
            if (receipt != null) 'receipt': receipt,
            if (email != null) 'email': email,
            if (contact != null) 'contact': contact,
            if (address != null) 'address': address,
            if (description != null) 'description': description,
          },
        )
        as Map<String, dynamic>;
  }

  /// Places a Cash on Delivery order.
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
