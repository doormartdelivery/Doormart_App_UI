import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../core/role_access.dart';
import '../models/address_model.dart';
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
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  bool initialized = false;
  bool loading = false;
  String? error;
  String? token;
  UserModel? user;
  List<ProductModel> products = [];
  List<ProductModel> favorites = [];
  List<OrderModel> orders = [];
  List<AddressModel> savedAddresses = [];
  AddressModel? selectedAddress;
  final List<CartLine> cart = [];

  double get subtotal => cart.fold(0, (sum, line) => sum + line.total);
  double get deliveryFee => cart.isEmpty ? 0 : 35;
  double get total => subtotal + deliveryFee;
  int get cartCount => cart.fold(0, (sum, line) => sum + line.quantity);
  int get favoritesCount => favorites.length;
  bool get signedIn => token != null && user != null;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_tokenKey);
    final storedUser = prefs.getString(_userKey);
    if (storedUser != null && storedUser.isNotEmpty) {
      user = UserModel.fromStorage(storedUser);
    }
    await Future.wait([loadProducts(), _restoreSession()]);
    if (token != null) {
      await loadFavorites();
    }
    initialized = true;
    notifyListeners();
  }

  Future<void> loginWithPassword({
    String? email,
    String? phone,
    required String password,
    bool silent = false,
  }) async {
    await _run(() async {
      final data =
          await apiService.post(
                '/auth/login',
                body: {
                  if (phone != null && phone.isNotEmpty) 'phone': phone,
                  if (email != null && email.isNotEmpty) 'email': email,
                  'password': password,
                },
              )
              as Map<String, dynamic>;
      token = data['token'] as String;
      user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _persistSession();
      await loadOrders();
      await loadCart();
      await loadAddresses();
      await loadFavorites();
    }, silent: silent);
  }

  Future<void> sendOtp({required String email}) async {
    await apiService.post('/auth/send-otp', body: {'email': email});
  }

  Future<void> verifyOtp({
    required String email,
    required String otp,
    bool silent = false,
  }) async {
    await _run(() async {
      final data =
          await apiService.post(
                '/auth/verify-otp',
                body: {'email': email, 'otp': otp},
              )
              as Map<String, dynamic>;
      token = data['token'] as String;
      user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _persistSession();
      await loadOrders();
      await loadCart();
      await loadAddresses();
      await loadFavorites();
    }, silent: silent);
  }

  Future<void> register({
    required String name,
    required String phone,
    String? email,
    required String password,
    String? addressLabel,
    String? addressLine1,
    String? city,
    String? pincode,
  }) async {
    final data =
        await apiService.post(
              '/auth/register',
              body: {
                'name': name,
                'phone': phone,
                if (email != null && email.isNotEmpty) 'email': email,
                'password': password,
              },
            )
            as Map<String, dynamic>;
    token = data['token'] as String?;
    final userJson = data['user'] as Map<String, dynamic>;
    user = UserModel.fromJson(userJson);
    await _persistSession();
    notifyListeners();

    if ((addressLine1 ?? '').isNotEmpty &&
        (city ?? '').isNotEmpty &&
        (pincode ?? '').isNotEmpty) {
      await apiService.post(
        '/addresses',
        token: token,
        body: {
          'label': addressLabel ?? 'Home',
          'line1': addressLine1,
          'city': city,
          'pincode': pincode,
        },
      );
      await loadAddresses();
    }
  }

  Future<void> refreshProfile() async {
    if (token == null) return;
    final data =
        await apiService.get('/auth/me', token: token) as Map<String, dynamic>;
    final currentUser = data['user'];
    if (currentUser is Map<String, dynamic>) {
      user = UserModel.fromJson(currentUser);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    token = null;
    user = null;
    orders = [];
    savedAddresses = [];
    selectedAddress = null;
    cart.clear();
    favorites = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    notifyListeners();
  }

  bool isFavorite(ProductModel product) =>
      favorites.any((item) => item.id == product.id);

  Future<void> toggleFavorite(ProductModel product) async {
    if (token == null) throw StateError('Please login first');
    if (isFavorite(product)) {
      await removeFavorite(product.id);
      return;
    }
    await apiService.post(
      '/wishlist/add',
      token: token,
      body: {'productId': product.id},
    );
    await loadFavorites();
  }

  Future<void> removeFavorite(String productId) async {
    if (token == null) throw StateError('Please login first');
    await apiService.delete(
      '/wishlist/remove/$productId',
      token: token,
    );
    await loadFavorites();
  }

  String get defaultDashboardRoute => RoleAccess.dashboardForRole(user?.role);

  bool canAccessRoute(String routeName) {
    return RoleAccess.canAccessRoute(user?.role, routeName);
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

  Future<ProductModel> createProduct({
    required String name,
    required String category,
    required double price,
    required double cost,
    required int stock,
    String imageUrl = '',
  }) async {
    if (token == null ||
        (user?.role != UserRoles.admin && user?.role != UserRoles.superAdmin)) {
      throw StateError('Admin login required');
    }

    final data =
        await apiService.post(
              '/products',
              token: token,
              body: {
                'name': name,
                'category': category,
                'price': price,
                'cost': cost,
                'stock': stock,
                'imageUrl': imageUrl,
              },
            )
            as Map<String, dynamic>;

    final product = ProductModel.fromJson(data);
    products.insert(0, product);
    notifyListeners();
    return product;
  }

  Future<ProductModel> updateProduct({
    required String productId,
    required String name,
    required String category,
    required double price,
    required double cost,
    required int stock,
    required String unit,
    String imageUrl = '',
  }) async {
    if (token == null ||
        (user?.role != UserRoles.admin && user?.role != UserRoles.superAdmin)) {
      throw StateError('Admin login required');
    }

    final data =
        await apiService.put(
              '/products/$productId',
              token: token,
              body: {
                'name': name,
                'category': category,
                'price': price,
                'cost': cost,
                'stock': stock,
                'unit': unit,
                'imageUrl': imageUrl,
              },
            )
            as Map<String, dynamic>;

    final product = ProductModel.fromJson(data);
    final index = products.indexWhere((item) => item.id == product.id);
    if (index == -1) {
      products.insert(0, product);
    } else {
      products[index] = product;
    }
    notifyListeners();
    return product;
  }

  Future<void> deleteProduct(String productId) async {
    if (token == null ||
        (user?.role != UserRoles.admin && user?.role != UserRoles.superAdmin)) {
      throw StateError('Admin login required');
    }

    await apiService.delete('/products/$productId', token: token);
    products.removeWhere((product) => product.id == productId);
    notifyListeners();
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

  Future<void> loadFavorites() async {
    if (token == null) {
      favorites = [];
      notifyListeners();
      return;
    }

    final data =
        await apiService.get('/wishlist', token: token) as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? const []);
    favorites = items
        .map((item) => item is Map<String, dynamic> ? item['product'] : null)
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList();
    notifyListeners();
  }

  Future<bool> addToCart(ProductModel product, {int quantity = 1}) async {
    return await _syncAddToCart(product, quantity: quantity);
  }

  Future<bool> decrement(ProductModel product) async {
    return await _syncDecrement(product);
  }

  Future<bool> clearCart() async {
    return await _syncClearCart();
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
    if (token == null ||
        (user?.role != UserRoles.admin && user?.role != UserRoles.superAdmin)) {
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

  Future<OrderModel> updateOrderStatus(String orderId, String status) async {
    if (token == null ||
        (user?.role != UserRoles.admin && user?.role != UserRoles.superAdmin)) {
      throw StateError('Admin login required');
    }

    final data =
        await apiService.patch(
              '/orders/$orderId/status',
              token: token,
              body: {'status': status},
            )
            as Map<String, dynamic>;

    return OrderModel.fromJson(data);
  }

  Future<List<UserModel>> adminUsers() async {
    if (token == null ||
        (user?.role != UserRoles.admin && user?.role != UserRoles.superAdmin)) {
      throw StateError('Admin login required');
    }
    final data = await apiService.get('/admin/users', token: token)
        as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(UserModel.fromJson).toList();
  }

  Future<UserModel> updateAdminUserRole(String userId, String role) async {
    if (token == null ||
        (user?.role != UserRoles.admin && user?.role != UserRoles.superAdmin)) {
      throw StateError('Admin login required');
    }
    final data = await apiService.put(
      '/admin/users/$userId',
      token: token,
      body: {'role': role},
    ) as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  Future<List<OrderModel>> availableDeliveryOrders() async {
    if (token == null || user?.role != UserRoles.deliveryPerson) {
      throw StateError('Delivery login required');
    }
    final data = await apiService.get('/delivery/available-orders', token: token)
        as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(OrderModel.fromJson).toList();
  }

  Future<List<OrderModel>> deliveryOrderHistory() async {
    if (token == null || user?.role != UserRoles.deliveryPerson) {
      throw StateError('Delivery login required');
    }
    final data =
        await apiService.get('/delivery/history', token: token)
            as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(OrderModel.fromJson).toList();
  }

  Future<OrderModel> acceptDeliveryOrder(String orderId) async {
    if (token == null || user?.role != UserRoles.deliveryPerson) {
      throw StateError('Delivery login required');
    }
    final data = await apiService.post(
      '/delivery/accept/$orderId',
      token: token,
    ) as Map<String, dynamic>;
    final order = OrderModel.fromJson(data);
    await loadOrders();
    return order;
  }

  Future<OrderModel> pickupDeliveryOrder(String orderId) async {
    if (token == null || user?.role != UserRoles.deliveryPerson) {
      throw StateError('Delivery login required');
    }
    final data = await apiService.post(
      '/delivery/pickup/$orderId',
      token: token,
    ) as Map<String, dynamic>;
    final order = OrderModel.fromJson(data);
    await loadOrders();
    return order;
  }

  Future<OrderModel> deliverDeliveryOrder(String orderId) async {
    if (token == null || user?.role != UserRoles.deliveryPerson) {
      throw StateError('Delivery login required');
    }
    final data = await apiService.post(
      '/delivery/delivered/$orderId',
      token: token,
    ) as Map<String, dynamic>;
    final order = OrderModel.fromJson(data);
    await loadOrders();
    return order;
  }

  Future<List<dynamic>> notificationsForRole(String role) async {
    if (token == null || user?.role != role) {
      throw StateError('Login required');
    }
    return await apiService.get('/notifications', token: token)
        as List<dynamic>;
  }

  Future<List<AddressModel>> addresses() async {
    if (token == null) throw StateError('Please login first');
    return await loadAddresses();
  }

  Future<List<AddressModel>> loadAddresses() async {
    if (token == null) return <AddressModel>[];
    final data =
        await apiService.get('/addresses', token: token) as List<dynamic>;
    savedAddresses = data
        .whereType<Map<String, dynamic>>()
        .map(AddressModel.fromJson)
        .toList();
    if (savedAddresses.isEmpty) {
      selectedAddress = null;
    } else if (selectedAddress == null ||
        !savedAddresses.any((address) => address.id == selectedAddress!.id)) {
      selectedAddress = savedAddresses.first;
    }
    notifyListeners();
    return savedAddresses;
  }

  Future<List<dynamic>> scheduledOrders() async {
    if (token == null) throw StateError('Please login first');
    return await apiService.get('/orders/scheduled', token: token)
        as List<dynamic>;
  }

  Future<Map<String, dynamic>> deliveryEarnings() async {
    if (token == null || user?.role != UserRoles.deliveryPerson) {
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

  Future<void> _restoreSession() async {
    if (token == null) return;
    try {
      final data =
          await apiService.get('/auth/me', token: token)
              as Map<String, dynamic>;
      final currentUser = data['user'];
      if (currentUser is Map<String, dynamic>) {
        user = UserModel.fromJson(currentUser);
        await _persistSession();
        await loadOrders();
        await loadCart();
        await loadAddresses();
      }
    } catch (_) {
      token = null;
      user = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    }
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_tokenKey, token!);
    }
    if (user != null) {
      await prefs.setString(_userKey, user!.toStorage());
    }
  }

  Future<void> loadCart() async {
    if (token == null) return;
    final data = await apiService.get('/cart', token: token);
    final items = data is Map<String, dynamic>
        ? (data['items'] as List<dynamic>? ?? [])
        : <dynamic>[];
    cart
      ..clear()
      ..addAll(
        items.whereType<Map<String, dynamic>>().map((item) {
          final productJson = item['product'];
          if (productJson is! Map<String, dynamic>) {
            return null;
          }
          final quantity = item['quantity'];
          if (quantity is! num) {
            return null;
          }
          return CartLine(
            product: ProductModel.fromJson(productJson),
            quantity: quantity.toInt(),
          );
        }).whereType<CartLine>(),
      );
    notifyListeners();
  }

  Future<bool> _syncAddToCart(ProductModel product, {int quantity = 1}) async {
    if (token == null) {
      error = 'Please login first';
      notifyListeners();
      return false;
    }
    await apiService.post(
      '/cart/add',
      token: token,
      body: {'productId': product.id, 'quantity': quantity},
    );
    await loadCart();
    return true;
  }

  Future<bool> _syncDecrement(ProductModel product) async {
    if (token == null) {
      error = 'Please login first';
      notifyListeners();
      return false;
    }
    final current = cart.firstWhere(
      (line) => line.product.id == product.id,
      orElse: () => CartLine(product: product, quantity: 0),
    );
    if (current.quantity <= 1) {
      await apiService.delete('/cart/remove/${product.id}', token: token);
    } else {
      await apiService.put(
        '/cart/update',
        token: token,
        body: {'productId': product.id, 'quantity': current.quantity - 1},
      );
    }
    await loadCart();
    return true;
  }

  Future<bool> _syncClearCart() async {
    if (token == null) {
      error = 'Please login first';
      notifyListeners();
      return false;
    }
    await apiService.delete('/cart/clear', token: token);
    cart.clear();
    notifyListeners();
    return true;
  }
}
