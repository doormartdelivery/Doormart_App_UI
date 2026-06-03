import '../models/product_model.dart';
import 'api_service.dart';

class ProductService {
  ProductService({ApiService? api}) : api = api ?? ApiService();
  final ApiService api;

  Future<List<ProductModel>> list() async {
    final data = await api.get('/products') as List<dynamic>;
    return data
        .cast<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList();
  }
}
