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
  AppState({this.apiService = const ApiService()});

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
    await Future.wait([
      loadProducts(),
      loginDemo(role: UserRoles.user, silent: true),
    ]);
  }

  Future<void> loginDemo({
    String role = UserRoles.user,
    bool silent = false,
  }) async {
    final phone = switch (role) {
      UserRoles.delivery => '8888888888',
      UserRoles.admin => '7777777777',
      UserRoles.superAdmin => '6666666666',
      _ => '9999999999',
    };
    await login(phone: phone, password: 'password', silent: silent);
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
      if (products.isEmpty) products = _fallbackProducts;
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
    if (token == null) await loginDemo(silent: true);
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
      await loginDemo(role: UserRoles.admin, silent: true);
    }
    return await apiService.get('/admin/dashboard', token: token)
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> superAdminAnalytics() async {
    if (token == null || user?.role != UserRoles.superAdmin) {
      await loginDemo(role: UserRoles.superAdmin, silent: true);
    }
    return await apiService.get('/super-admin/analytics', token: token)
        as Map<String, dynamic>;
  }

  Future<List<dynamic>> categories() async {
    return await apiService.get('/categories') as List<dynamic>;
  }

  Future<List<OrderModel>> allOrdersForRole(String role) async {
    if (token == null || user?.role != role) {
      await loginDemo(role: role, silent: true);
    }
    final data = await apiService.get('/orders', token: token) as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(OrderModel.fromJson).toList();
  }

  Future<List<dynamic>> notificationsForRole(String role) async {
    if (token == null || user?.role != role) {
      await loginDemo(role: role, silent: true);
    }
    return await apiService.get('/notifications', token: token)
        as List<dynamic>;
  }

  Future<List<dynamic>> addresses() async {
    if (token == null) await loginDemo(silent: true);
    return await apiService.get('/users/addresses', token: token)
        as List<dynamic>;
  }

  Future<List<dynamic>> scheduledOrders() async {
    if (token == null) await loginDemo(silent: true);
    return await apiService.get('/scheduled-orders', token: token)
        as List<dynamic>;
  }

  Future<Map<String, dynamic>> deliveryEarnings() async {
    if (token == null || user?.role != UserRoles.delivery) {
      await loginDemo(role: UserRoles.delivery, silent: true);
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
      if (products.isEmpty) products = _fallbackProducts;
    } finally {
      if (!silent) loading = false;
      notifyListeners();
    }
  }

  static const List<ProductModel> _fallbackProducts = [
    ProductModel(
      id: 'local-tomato',
      name: 'Fresh Tomato',
      category: 'Vegetables',
      price: 38,
      cost: 24,
      stock: 120,
      imageUrl: 'assets/images/products/tomato.png',
      rating: 4.6,
      unit: '1 kg',
    ),
    ProductModel(
      id: 'local-milk',
      name: 'A2 Milk',
      category: 'Dairy',
      price: 72,
      cost: 53,
      stock: 42,
      imageUrl: 'assets/images/products/milk.png',
      rating: 4.8,
      unit: '1 litre',
    ),
    ProductModel(
      id: 'local-rice',
      name: 'Basmati Rice',
      category: 'Staples',
      price: 149,
      cost: 104,
      stock: 80,
      imageUrl: 'assets/images/products/rice.png',
      rating: 4.5,
      unit: '1 kg',
    ),
    ProductModel(
      id: 'local-banana',
      name: 'Yelakki Banana',
      category: 'Fruits',
      price: 64,
      cost: 39,
      stock: 36,
      imageUrl: 'assets/images/products/banana.png',
      rating: 4.7,
      unit: '500 g',
    ),
  ];
}
