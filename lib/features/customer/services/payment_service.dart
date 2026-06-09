import '../../../services/api_service.dart';

class PaymentService {
  PaymentService({ApiService? api}) : api = api ?? ApiService();
  final ApiService api;

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
