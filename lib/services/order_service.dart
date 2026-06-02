import '../models/order_model.dart';
import 'api_service.dart';

class OrderService {
  const OrderService({this.api = const ApiService()});
  final ApiService api;

  Future<List<OrderModel>> mine(String token) async {
    final data = await api.get('/orders/mine', token: token) as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(OrderModel.fromJson).toList();
  }
}
