import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class CartLine {
  CartLine({required this.product, this.quantity = 1});

  final ProductModel product;
  int quantity;

  double get total => product.price * quantity;

  Map<String, dynamic> toOrderJson() => {
    'productId': product.id,
    'name': product.name,
    'quantity': quantity,
    'price': product.price,
  };
}

class AppState extends ChangeNotifier {
  AppState({ApiService? apiService}) : apiService = apiService ?? ApiService();

  final ApiService apiService;

  bool loading = false;
  String? error;
  String? token;
  UserModel? user;
  List<ProductModel> products = [];
  List<OrderModel> orders = [];
  final List<CartLine> cart = [];

  double get subtotal => cart.fold(0, (sum, line) => sum + line.total);
  double get deliveryFee => cart.isEmpty ? 0 : 35;
  double get total => subtotal + deliveryFee;
  int get cartCount => cart.fold(0, (sum, line) => sum + line.quantity);
  bool get signedIn => token != null && user != null;

  Future<void> bootstrap() async {
    await loadProducts();
  }

  Future<void> login({
    required String phone,
    required String password,
    bool silent = false,
  }) async {
    await _run(() async {
      final data =
          await apiService.post(
                '/auth/login',
                body: {'phone': phone, 'password': password},
              )
              as Map<String, dynamic>;
      token = data['token'] as String;
      user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await loadOrders();
    }, silent: silent);
  }

  Future<void> refreshProfile() async {
    if (token == null) return;
    final data = await apiService.get('/auth/me', token: token) as Map<String, dynamic>;
    final currentUser = data['user'];
    if (currentUser is Map<String, dynamic>) {
      user = UserModel.fromJson(currentUser);
      notifyListeners();
    }
  }

  Future<void> loadProducts({String? category, String? search}) async {
    await _run(() async {
      final query = <String>[
        if (category != null && category != 'All') 'category=$category',
        if (search != null && search.isNotEmpty) 'search=$search',
      ].join('&');
      final data =
          await apiService.get('/products${query.isEmpty ? '' : '?$query'}')
              as List<dynamic>;
      products = data
          .cast<Map<String, dynamic>>()
          .map(ProductModel.fromJson)
          .toList();
    });
  }

  Future<void> loadOrders() async {
    if (token == null) return;
    final data =
        await apiService.get('/orders/mine', token: token) as List<dynamic>;
    orders = data
        .cast<Map<String, dynamic>>()
        .map(OrderModel.fromJson)
        .toList();
    notifyListeners();
  }

  void addToCart(ProductModel product) {
    final index = cart.indexWhere((line) => line.product.id == product.id);
    if (index == -1) {
      cart.add(CartLine(product: product));
    } else {
      cart[index].quantity += 1;
    }
    notifyListeners();
  }

  void decrement(ProductModel product) {
    final index = cart.indexWhere((line) => line.product.id == product.id);
    if (index == -1) return;
    cart[index].quantity -= 1;
    if (cart[index].quantity <= 0) cart.removeAt(index);
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }

  Future<OrderModel> checkout({
    required String address,
    String paymentMethod = 'razorpay',
    DateTime? scheduledFor,
  }) async {
    if (token == null) throw StateError('Please login first');
    final data =
        await apiService.post(
              '/orders',
              token: token,
              body: {
                'products': cart.map((line) => line.toOrderJson()).toList(),
                'deliveryFee': deliveryFee,
                'address': address,
                'paymentMethod': paymentMethod,
                if (scheduledFor != null)
                  'scheduledFor': scheduledFor.toIso8601String(),
              },
            )
            as Map<String, dynamic>;
    final order = OrderModel.fromJson(data);
    orders.insert(0, order);
    clearCart();
    return order;
  }

  Future<Map<String, dynamic>> adminDashboard() async {
    if (token == null || user?.role != UserRoles.admin) {
      throw StateError('Admin login required');
    }
    return await apiService.get('/admin/dashboard', token: token)
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> superAdminAnalytics() async {
    if (token == null || user?.role != UserRoles.superAdmin) {
      throw StateError('Super admin login required');
    }
    return await apiService.get('/super-admin/analytics', token: token)
        as Map<String, dynamic>;
  }

  Future<List<dynamic>> categories() async {
    return await apiService.get('/categories') as List<dynamic>;
  }

  Future<List<OrderModel>> allOrdersForRole(String role) async {
    if (token == null || user?.role != role) {
      throw StateError('Login required');
    }
    final data = await apiService.get('/orders', token: token) as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(OrderModel.fromJson).toList();
  }

  Future<List<dynamic>> notificationsForRole(String role) async {
    if (token == null || user?.role != role) {
      throw StateError('Login required');
    }
    return await apiService.get('/notifications', token: token)
        as List<dynamic>;
  }

  Future<List<dynamic>> addresses() async {
    if (token == null) throw StateError('Please login first');
    return await apiService.get('/addresses', token: token) as List<dynamic>;
  }

  Future<List<dynamic>> scheduledOrders() async {
    if (token == null) throw StateError('Please login first');
    return await apiService.get('/orders/scheduled', token: token) as List<dynamic>;
  }

  Future<Map<String, dynamic>> deliveryEarnings() async {
    if (token == null || user?.role != UserRoles.delivery) {
      throw StateError('Delivery login required');
    }
    return await apiService.get('/delivery/earnings', token: token)
        as Map<String, dynamic>;
  }

  Future<void> _run(
    Future<void> Function() action, {
    bool silent = false,
  }) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      await action();
      error = null;
    } catch (exception) {
      if (!silent) error = exception.toString();
    } finally {
      if (!silent) loading = false;
      notifyListeners();
    }
  }
}
