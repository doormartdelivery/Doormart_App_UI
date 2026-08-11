import 'dart:async';
import 'package:flutter/foundation.dart';

import '../app.dart';
import '../core/constants.dart';
import '../core/role_access.dart';
import '../core/utils/network_image_url.dart';
import '../models/address_model.dart';
import '../models/banner_model.dart';
import '../models/category_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../notifications/firebase_messaging_service.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/session_service.dart';
import '../widgets/toast_widget.dart';

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
  AppState({ApiService? apiService, SocketService? socketService})
    : apiService = apiService ?? ApiService(),
      socketService = socketService ?? SocketService();

  final ApiService apiService;
  final SocketService socketService;
  final FirebaseMessagingService _messagingService = FirebaseMessagingService();
  final SessionService _sessionService = SessionService();
  bool initialized = false;
  bool loading = false;
  String? error;
  String? token;
  UserModel? user;
  List<ProductModel> products = [];
  List<CategoryModel> categoryCatalog = [];
  List<BannerModel> banners = [];
  List<ProductModel> favorites = [];
  List<OrderModel> orders = [];
  List<OrderModel> adminOrders = [];
  List<AddressModel> savedAddresses = [];
  List<Map<String, dynamic>> supportTickets = [];
  AddressModel? selectedAddress;
  Map<String, dynamic>? checkoutSummary;
  final List<CartLine> cart = [];
  int _cartMutationToken = 0;
  int dashboardRefreshTick = 0;
  double deliveryChargeAmount = 35;
  double gstPercent = 0;

  double get subtotal => cart.fold(0, (sum, line) => sum + line.total);
  double get deliveryFee => cart.isEmpty ? 0 : deliveryChargeAmount;
  double get gstAmount => cart.isEmpty ? 0 : subtotal * (gstPercent / 100);
  double get total => subtotal + deliveryFee + gstAmount;
  int get cartCount => cart.fold(0, (sum, line) => sum + line.quantity);
  int get favoritesCount => favorites.length;
  bool get signedIn => token != null;

  Future<void> bootstrap() async {
    try {
      token = await _sessionService.getToken();
      user = await _sessionService.getSavedUser();
      await Future.wait([
        loadProducts(),
        loadCategories(),
        loadBanners(),
        loadCheckoutSettings(),
      ]);
      if (token != null && user?.role == UserRoles.user) {
        await _restoreSession();
      }
      if (token != null) {
        _connectSocket();
        try {
          await _syncDeliveryToken();
        } catch (e) {
          debugPrint('FCM token sync skipped during bootstrap: $e');
        }
        if (user?.role == UserRoles.user) {
          await loadFavorites();
        }
        if (user?.role == UserRoles.admin ||
            user?.role == UserRoles.superAdmin) {
          await loadAdminOrders();
        }
      }
    } catch (error) {
      debugPrint('App bootstrap continued after recoverable error: $error');
    } finally {
      initialized = true;
      notifyListeners();
    }
  }

  Future<void> loginWithPassword({
    String? email,
    String? phone,
    required String password,
    bool silent = false,
  }) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
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
      await _sessionService.saveSession(token: token!, user: user!);
      await _refreshCurrentProfileSafely();
      await _loadPostAuthData();
      _connectSocket();
      try {
        await _syncDeliveryToken();
      } catch (e) {
        debugPrint('FCM token sync skipped after login: $e');
      }
      if (user?.role == UserRoles.admin || user?.role == UserRoles.superAdmin) {
        await loadAdminOrders();
      }
      error = null;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      if (!silent) loading = false;
      notifyListeners();
    }
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
      await _sessionService.saveSession(token: token!, user: user!);
      await _refreshCurrentProfileSafely();
      await _loadPostAuthData();
      _connectSocket();
      if (user?.role == UserRoles.admin || user?.role == UserRoles.superAdmin) {
        await loadAdminOrders();
      }
    }, silent: silent);
  }

  Future<void> sendPasswordResetOtp({required String email}) async {
    await apiService.post('/auth/forgot-password', body: {'email': email});
  }

  Future<void> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String password,
  }) async {
    await apiService.post(
      '/auth/reset-password',
      body: {'email': email, 'otp': otp, 'password': password},
    );
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
    if (token != null) {
      await _sessionService.saveSession(token: token!, user: user!);
    }
    notifyListeners();
    _connectSocket();
    try {
      await _syncDeliveryToken();
    } catch (e) {
      debugPrint('FCM token sync skipped after register: $e');
    }

    if ((addressLine1 ?? '').isNotEmpty &&
        (city ?? '').isNotEmpty &&
        (pincode ?? '').isNotEmpty) {
      try {
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
      } catch (e) {
        debugPrint('Address save skipped after register: $e');
      }
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

  Future<void> _refreshCurrentProfileSafely() async {
    if (token == null) return;
    if (user?.role == UserRoles.deliveryPerson) return;
    try {
      await refreshProfile();
    } catch (e) {
      debugPrint('Profile refresh skipped: $e');
    }
  }

  Future<void> _loadPostAuthData() async {
    final role = user?.role;
    if (role == UserRoles.user) {
      await Future.wait([
        _safeCall(loadCart),
        _safeCall(loadAddresses),
        _safeCall(loadFavorites),
        _safeCall(loadOrders),
      ]);
      return;
    }
    if (role == UserRoles.deliveryPerson) {
      return;
    }
    if (role == UserRoles.admin || role == UserRoles.superAdmin) {
      await Future.wait([
        _safeCall(loadOrders),
        _safeCall(loadFavorites),
        _safeCall(loadProducts),
      ]);
      return;
    }
    await Future.wait([
      _safeCall(loadOrders),
      _safeCall(loadCart),
      _safeCall(loadAddresses),
      _safeCall(loadFavorites),
    ]);
  }

  Future<void> loadSupportTickets() async {
    if (token == null) return;
    try {
      final data =
          await apiService.get('/support/tickets', token: token)
              as List<dynamic>;
      supportTickets = data.whereType<Map<String, dynamic>>().toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Support tickets skipped: $e');
    }
  }

  Future<Map<String, dynamic>> createSupportTicket({
    required String subject,
    required String issueType,
    required String description,
    String orderId = '',
    String imageUrl = '',
  }) async {
    if (token == null) throw StateError('Please login first');
    final data =
        await apiService.post(
              '/support/tickets',
              token: token,
              body: {
                'subject': subject,
                'issueType': issueType,
                'description': description,
                'orderId': orderId,
                'imageUrl': imageUrl,
              },
            )
            as Map<String, dynamic>;
    await loadSupportTickets();
    return data;
  }

  Future<void> _safeCall(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('Post-auth load skipped: $e');
    }
  }

  Future<void> logout() async {
    final currentToken = await _messagingService.getToken();
    if (token != null && currentToken != null && currentToken.isNotEmpty) {
      try {
        await _messagingService.removeToken(
          token: currentToken,
          authToken: token!,
        );
      } catch (e) {
        debugPrint('FCM token removal skipped during logout: $e');
      }
    }
    token = null;
    user = null;
    orders = [];
    adminOrders = [];
    savedAddresses = [];
    selectedAddress = null;
    cart.clear();
    favorites = [];
    socketService.disconnect();
    await _sessionService.clearSession();
    notifyListeners();
  }

  Future<void> _syncDeliveryToken() async {
    if (token == null) return;
    await _messagingService.registerTokenSync(authToken: token!);
  }

  bool isFavorite(ProductModel product) =>
      favorites.any((item) => item.id == product.id);

  void _setFavoriteState(ProductModel product, bool favorite) {
    if (favorite) {
      if (favorites.any((item) => item.id == product.id)) return;
      favorites = [product, ...favorites];
      return;
    }
    favorites = favorites.where((item) => item.id != product.id).toList();
  }

  List<CartLine> _cloneCart() => cart
      .map((line) => CartLine(product: line.product, quantity: line.quantity))
      .toList();

  void _setCartQuantity(ProductModel product, int quantity) {
    final index = cart.indexWhere((line) => line.product.id == product.id);
    if (quantity <= 0) {
      if (index != -1) cart.removeAt(index);
      return;
    }
    if (index == -1) {
      cart.add(CartLine(product: product, quantity: quantity));
      return;
    }
    cart[index].quantity = quantity;
  }

  int _nextCartMutationToken() => ++_cartMutationToken;

  void _restoreCartSnapshot(List<CartLine> snapshot) {
    cart
      ..clear()
      ..addAll(snapshot);
    notifyListeners();
  }

  Future<void> _syncCartMutation({
    required int mutationToken,
    required List<CartLine> snapshot,
    required Future<void> Function() action,
  }) async {
    try {
      await action();
    } catch (e) {
      if (mutationToken == _cartMutationToken) {
        _restoreCartSnapshot(snapshot);
        error = e.toString();
      } else {
        debugPrint('Cart sync failed after newer cart changes: $e');
      }
    }
  }

  Future<void> toggleFavorite(ProductModel product) async {
    if (token == null) throw StateError('Please login first');
    final wasFavorite = isFavorite(product);
    final snapshot = List<ProductModel>.from(favorites);
    _setFavoriteState(product, !wasFavorite);
    notifyListeners();
    final sw = Stopwatch()..start();
    try {
      if (wasFavorite) {
        await apiService.delete('/wishlist/remove/${product.id}', token: token);
      } else {
        await apiService.post(
          '/wishlist/add',
          token: token,
          body: {'productId': product.id},
        );
      }
      debugPrint(
        '[perf][wishlist:${wasFavorite ? "remove" : "add"}][api] ${sw.elapsedMilliseconds}ms',
      );
    } catch (e) {
      favorites = snapshot;
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeFavorite(String productId) async {
    if (token == null) throw StateError('Please login first');
    final snapshot = List<ProductModel>.from(favorites);
    favorites.removeWhere((item) => item.id == productId);
    notifyListeners();
    try {
      await apiService.delete('/wishlist/remove/$productId', token: token);
    } catch (e) {
      favorites = snapshot;
      error = e.toString();
      notifyListeners();
      rethrow;
    }
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
      final path = '/products${query.isEmpty ? '' : '?$query'}';
      products = await _loadProductsWithRetry(path, token: token);
    });
  }

  Future<List<ProductModel>> _loadProductsWithRetry(
    String path, {
    String? token,
  }) async {
    Future<List<ProductModel>> fetchOnce() async {
      final data =
          await apiService
                  .get(path, token: token)
                  .timeout(const Duration(seconds: 8))
              as List<dynamic>;
      return data
          .cast<Map<String, dynamic>>()
          .map(ProductModel.fromJson)
          .toList();
    }

    try {
      return await fetchOnce();
    } catch (firstError) {
      debugPrint('Product load retry after error: $firstError');
      await Future<void>.delayed(const Duration(milliseconds: 350));
      return await fetchOnce();
    }
  }

  Future<void> loadCategories() async {
    try {
      final data =
          await apiService
                  .get('/categories')
                  .timeout(const Duration(seconds: 8))
              as List<dynamic>;
      categoryCatalog = data
          .cast<Map<String, dynamic>>()
          .map(CategoryModel.fromJson)
          .toList();
      notifyListeners();
    } catch (error) {
      debugPrint('Category load skipped: $error');
    }
  }

  Future<void> loadBanners() async {
    try {
      final data =
          await apiService.get('/banners').timeout(const Duration(seconds: 8))
              as List<dynamic>;
      banners = data
          .cast<Map<String, dynamic>>()
          .where((item) => item['active'] != false)
          .map(BannerModel.fromJson)
          .toList();
      notifyListeners();
    } catch (error) {
      debugPrint('Banner load skipped: $error');
    }
  }

  Future<void> createCategory({
    required String name,
    String description = '',
    String imageUrl = '',
  }) async {
    if (token == null ||
        (user?.role != UserRoles.admin && user?.role != UserRoles.superAdmin)) {
      throw StateError('Admin login required');
    }
    await apiService.post(
      '/categories',
      token: token,
      body: {'name': name, 'description': description, 'imageUrl': imageUrl},
    );
    await loadCategories();
  }

  Future<void> updateCategory({
    required String categoryId,
    required String name,
    String description = '',
    String imageUrl = '',
  }) async {
    if (token == null ||
        (user?.role != UserRoles.admin && user?.role != UserRoles.superAdmin)) {
      throw StateError('Admin login required');
    }
    await apiService.put(
      '/categories/$categoryId',
      token: token,
      body: {'name': name, 'description': description, 'imageUrl': imageUrl},
    );
    await loadCategories();
  }

  Future<void> deleteCategory(String categoryId) async {
    if (token == null ||
        (user?.role != UserRoles.admin && user?.role != UserRoles.superAdmin)) {
      throw StateError('Admin login required');
    }
    await apiService.delete('/categories/$categoryId', token: token);
    await loadCategories();
  }

  Future<String> uploadCategoryImage(
    String filePath, {
    Uint8List? bytes,
    String? fileName,
  }) async {
    if (token == null ||
        (user?.role != UserRoles.admin && user?.role != UserRoles.superAdmin)) {
      throw StateError('Admin login required');
    }

    final data =
        await apiService.uploadImage(
              '/categories/upload-image',
              token: token,
              filePath: filePath,
              bytes: bytes,
              fileName: fileName,
              fieldName: 'image',
            )
            as Map<String, dynamic>;

    return NetworkImageUrl.normalize(data['url'] as String?);
  }

  Future<String> uploadProductImage(
    String filePath, {
    Uint8List? bytes,
    String? fileName,
  }) async {
    if (token == null ||
        (user?.role != UserRoles.admin && user?.role != UserRoles.superAdmin)) {
      throw StateError('Admin login required');
    }

    final data =
        await apiService.uploadImage(
              '/products/upload-image',
              token: token,
              filePath: filePath,
              bytes: bytes,
              fileName: fileName,
              fieldName: 'image',
            )
            as Map<String, dynamic>;

    return NetworkImageUrl.normalize(data['url'] as String?);
  }

  Future<ProductModel> createProduct({
    required String name,
    required String category,
    required double price,
    required double cost,
    required int stock,
    required String unit,
    required double rating,
    String description = '',
    String dashboardSection = 'daily_essentials',
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
                'unit': unit,
                'rating': rating,
                'description': description,
                'dashboardSection': dashboardSection,
                'imageUrl': imageUrl,
              },
            )
            as Map<String, dynamic>;

    final product = ProductModel.fromJson(data);
    products.insert(0, product);
    notifyListeners();
    await loadProducts();
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
    required double rating,
    String description = '',
    String dashboardSection = 'daily_essentials',
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
                'rating': rating,
                'description': description,
                'dashboardSection': dashboardSection,
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
    await loadProducts();
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
    await loadProducts();
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
    return _syncAddToCart(product, quantity: quantity);
  }

  Future<bool> decrement(ProductModel product) async {
    return _syncDecrement(product);
  }

  Future<bool> clearCart() async {
    return _syncClearCart();
  }

  Future<OrderModel> checkout({
    required String address,
    String paymentMethod = 'razorpay',
    String? paymentId,
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
                'gstPercent': gstPercent,
                'address': address,
                'paymentMethod': paymentMethod,
                if (paymentId != null) 'paymentId': paymentId,
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

  Future<Map<String, dynamic>> loadCheckoutSummary() async {
    if (token == null) throw StateError('Please login first');
    final data =
        await apiService.post(
              '/payments/checkout-summary',
              token: token,
              body: {
                'products': cart.map((line) => line.toOrderJson()).toList(),
                'deliveryFee': deliveryFee,
                'gstPercent': gstPercent,
              },
            )
            as Map<String, dynamic>;
    checkoutSummary = data;
    notifyListeners();
    return data;
  }

  Future<Map<String, dynamic>> adminDashboard() async {
    if (token == null ||
        (user?.role != UserRoles.admin && user?.role != UserRoles.superAdmin)) {
      throw StateError('Admin login required');
    }
    return await apiService.get('/admin/dashboard', token: token)
        as Map<String, dynamic>;
  }

  Future<void> loadCheckoutSettings() async {
    try {
      final data = await apiService.get('/settings/public') as List<dynamic>;
      final map = {
        for (final item in data.whereType<Map<String, dynamic>>())
          (item['key'] ?? '').toString(): item['value'],
      };
      deliveryChargeAmount = _asDouble(
        map['delivery_charge_amount'],
        fallback: deliveryChargeAmount,
      );
      gstPercent = _asDouble(map['gst_percent'], fallback: gstPercent);
      notifyListeners();
    } catch (e) {
      debugPrint('Checkout settings load skipped: $e');
    }
  }

  Future<void> saveCheckoutSettings({
    required double deliveryChargeAmount,
    required double gstPercent,
  }) async {
    if (token == null ||
        (user?.role != UserRoles.admin && user?.role != UserRoles.superAdmin)) {
      throw StateError('Admin login required');
    }
    await apiService.put(
      '/admin/settings',
      token: token,
      body: {
        'delivery_charge_amount': deliveryChargeAmount,
        'gst_percent': gstPercent,
      },
    );
    this.deliveryChargeAmount = deliveryChargeAmount;
    this.gstPercent = gstPercent;
    notifyListeners();
  }

  double _asDouble(dynamic value, {double fallback = 0}) {
    final n = value is num ? value.toDouble() : double.tryParse('$value');
    return n ?? fallback;
  }

  Future<Map<String, dynamic>> superAdminAnalytics() async {
    if (token == null || user?.role != UserRoles.superAdmin) {
      throw StateError('Super admin login required');
    }
    return await apiService.get('/super-admin/analytics', token: token)
        as Map<String, dynamic>;
  }

  Future<List<dynamic>> categories() async {
    final data = await apiService.get('/categories') as List<dynamic>;
    categoryCatalog = data
        .cast<Map<String, dynamic>>()
        .map(CategoryModel.fromJson)
        .toList();
    notifyListeners();
    return data;
  }

  Future<List<OrderModel>> allOrdersForRole(String role) async {
    if (token == null || user?.role != role) {
      throw StateError('Login required');
    }
    final data = await apiService.get('/orders', token: token) as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(OrderModel.fromJson).toList();
  }

  Future<void> loadAdminOrders() async {
    if (token == null ||
        (user?.role != UserRoles.admin && user?.role != UserRoles.superAdmin)) {
      return;
    }
    final data = await apiService.get('/orders', token: token) as List<dynamic>;
    adminOrders = data
        .cast<Map<String, dynamic>>()
        .map(OrderModel.fromJson)
        .toList();
    notifyListeners();
  }

  void upsertAdminOrder(OrderModel order) {
    if (user?.role != UserRoles.admin && user?.role != UserRoles.superAdmin) {
      return;
    }

    final index = adminOrders.indexWhere((existing) => existing.id == order.id);
    if (index == -1) {
      adminOrders = [order, ...adminOrders];
    } else {
      final updated = [...adminOrders];
      updated[index] = order;
      adminOrders = updated;
    }
    notifyListeners();
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
    final data =
        await apiService.get('/admin/users', token: token) as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(UserModel.fromJson).toList();
  }

  Future<List<Map<String, dynamic>>> adminDeliveryPartners() async {
    if (token == null ||
        (user?.role != UserRoles.admin && user?.role != UserRoles.superAdmin)) {
      throw StateError('Admin login required');
    }
    final data =
        await apiService.get('/admin/delivery', token: token) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<UserModel> updateAdminUserRole(String userId, String role) async {
    if (token == null ||
        (user?.role != UserRoles.admin && user?.role != UserRoles.superAdmin)) {
      throw StateError('Admin login required');
    }
    final data =
        await apiService.put(
              '/admin/users/$userId',
              token: token,
              body: {'role': role},
            )
            as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  Future<UserModel> updateAdminUser({
    required String userId,
    String? name,
    String? phone,
    String? email,
    String? avatarUrl,
    String? password,
    String? role,
    String? status,
    String? vendorId,
  }) async {
    if (token == null ||
        (user?.role != UserRoles.admin && user?.role != UserRoles.superAdmin)) {
      throw StateError('Admin login required');
    }
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (password != null && password.isNotEmpty) 'password': password,
      if (role != null) 'role': role,
      if (status != null) 'status': status,
      if (vendorId != null && vendorId.isNotEmpty) 'vendorId': vendorId,
    };
    final data =
        await apiService.put('/admin/users/$userId', token: token, body: body)
            as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  Future<UserModel> createAdminUser({
    required String name,
    required String phone,
    String email = '',
    String avatarUrl = '',
    String password = '',
    String role = UserRoles.deliveryPerson,
    String status = 'active',
    String? vendorId,
  }) async {
    if (token == null ||
        (user?.role != UserRoles.admin && user?.role != UserRoles.superAdmin)) {
      throw StateError('Admin login required');
    }
    final data =
        await apiService.post(
              '/admin/users',
              token: token,
              body: {
                'name': name,
                'phone': phone,
                'email': email,
                'avatarUrl': avatarUrl,
                if (password.isNotEmpty) 'password': password,
                'role': role,
                'status': status,
                if (vendorId != null && vendorId.isNotEmpty)
                  'vendorId': vendorId,
              },
            )
            as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  Future<void> deleteAdminUser(String userId) async {
    if (token == null ||
        (user?.role != UserRoles.admin && user?.role != UserRoles.superAdmin)) {
      throw StateError('Admin login required');
    }
    await apiService.delete('/admin/users/$userId', token: token);
  }

  Future<List<BannerModel>> adminBanners() async {
    if (token == null ||
        (user?.role != UserRoles.admin && user?.role != UserRoles.superAdmin)) {
      throw StateError('Admin login required');
    }
    final data =
        await apiService.get('/admin/banners', token: token) as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(BannerModel.fromJson).toList();
  }

  Future<BannerModel> createBanner({
    required String title,
    required String imageUrl,
    bool active = true,
  }) async {
    if (token == null ||
        (user?.role != UserRoles.admin && user?.role != UserRoles.superAdmin)) {
      throw StateError('Admin login required');
    }
    final data =
        await apiService.post(
              '/admin/banners',
              token: token,
              body: {'title': title, 'imageUrl': imageUrl, 'active': active},
            )
            as Map<String, dynamic>;
    await loadBanners();
    return BannerModel.fromJson(data);
  }

  Future<BannerModel> updateBanner({
    required String bannerId,
    required String title,
    required String imageUrl,
    bool active = true,
  }) async {
    if (token == null ||
        (user?.role != UserRoles.admin && user?.role != UserRoles.superAdmin)) {
      throw StateError('Admin login required');
    }
    final data =
        await apiService.put(
              '/admin/banners/$bannerId',
              token: token,
              body: {'title': title, 'imageUrl': imageUrl, 'active': active},
            )
            as Map<String, dynamic>;
    await loadBanners();
    return BannerModel.fromJson(data);
  }

  Future<void> deleteBanner(String bannerId) async {
    if (token == null ||
        (user?.role != UserRoles.admin && user?.role != UserRoles.superAdmin)) {
      throw StateError('Admin login required');
    }
    await apiService.delete('/admin/banners/$bannerId', token: token);
    await loadBanners();
  }

  Future<List<OrderModel>> availableDeliveryOrders() async {
    if (token == null || user?.role != UserRoles.deliveryPerson) {
      throw StateError('Delivery login required');
    }
    final data =
        await apiService.get('/delivery/available-orders', token: token)
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
    final data =
        await apiService.post('/delivery/accept/$orderId', token: token)
            as Map<String, dynamic>;
    final order = OrderModel.fromJson(data);
    await loadOrders();
    return order;
  }

  Future<OrderModel> pickupDeliveryOrder(String orderId) async {
    if (token == null || user?.role != UserRoles.deliveryPerson) {
      throw StateError('Delivery login required');
    }
    final data =
        await apiService.post('/delivery/pickup/$orderId', token: token)
            as Map<String, dynamic>;
    final order = OrderModel.fromJson(data);
    await loadOrders();
    return order;
  }

  Future<OrderModel> deliverDeliveryOrder(String orderId) async {
    if (token == null || user?.role != UserRoles.deliveryPerson) {
      throw StateError('Delivery login required');
    }
    final data =
        await apiService.post('/delivery/delivered/$orderId', token: token)
            as Map<String, dynamic>;
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

  Future<AddressModel> createAddress({
    required String label,
    required String line1,
    required String city,
    required String pincode,
  }) async {
    if (token == null) throw StateError('Please login first');
    final data =
        await apiService.post(
              '/addresses',
              token: token,
              body: {
                'label': label,
                'line1': line1,
                'city': city,
                'pincode': pincode,
              },
            )
            as Map<String, dynamic>;
    final address = AddressModel.fromJson(data);
    await loadAddresses();
    return address;
  }

  Future<AddressModel> updateAddress({
    required String addressId,
    required String label,
    required String line1,
    required String city,
    required String pincode,
  }) async {
    if (token == null) throw StateError('Please login first');
    final data =
        await apiService.put(
              '/addresses/$addressId',
              token: token,
              body: {
                'label': label,
                'line1': line1,
                'city': city,
                'pincode': pincode,
              },
            )
            as Map<String, dynamic>;
    final address = AddressModel.fromJson(data);
    await loadAddresses();
    return address;
  }

  Future<void> deleteAddress(String addressId) async {
    if (token == null) throw StateError('Please login first');
    await apiService.delete('/addresses/$addressId', token: token);
    await loadAddresses();
  }

  Future<void> setDefaultAddress(String addressId) async {
    if (token == null) throw StateError('Please login first');
    await apiService.put('/addresses/default/$addressId', token: token);
    await loadAddresses();
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
        _connectSocket();
        if (user?.role == UserRoles.admin ||
            user?.role == UserRoles.superAdmin) {
          await loadProducts();
          await loadAdminOrders();
        }
      }
    } catch (_) {
      if (user?.role == UserRoles.user || user?.role == null) {
        token = null;
        user = null;
        await _sessionService.clearSession();
      }
    }
  }

  Future<void> _persistSession() async {
    if (token != null && user != null) {
      await _sessionService.saveSession(token: token!, user: user!);
    }
  }

  void _connectSocket() {
    if (token == null || socketService.connected) return;
    socketService.connect(
      token: token,
      userId: user?.id,
      onOrderCreated: (data) async {
        debugPrint('Socket order created event received; reloading orders.');
        dashboardRefreshTick++;
        if (data is Map<String, dynamic>) {
          final order = OrderModel.fromJson(data);
          if (user?.role == UserRoles.admin ||
              user?.role == UserRoles.superAdmin) {
            upsertAdminOrder(order);
          }
          if (user?.role == UserRoles.user) {
            final index = orders.indexWhere(
              (existing) => existing.id == order.id,
            );
            if (index == -1) {
              orders = [order, ...orders];
            } else {
              final updated = [...orders];
              updated[index] = order;
              orders = updated;
            }
            notifyListeners();
          }
        }
        await loadOrders();
        await loadAdminOrders();
      },
      onOrderAccepted: (_) async {
        debugPrint('Socket order accepted event received; reloading orders.');
        dashboardRefreshTick++;
        await loadOrders();
        await loadAdminOrders();
      },
      onOrderPickedUp: (_) async {
        debugPrint('Socket order picked up event received; reloading orders.');
        dashboardRefreshTick++;
        await loadOrders();
        await loadAdminOrders();
      },
      onOrderDelivered: (_) async {
        debugPrint('Socket order delivered event received; reloading orders.');
        dashboardRefreshTick++;
        await loadOrders();
        await loadAdminOrders();
        final navContext = DoormartDeliveryApp.navigatorKey.currentContext;
        if (navContext != null)
          showToast(navContext, 'Order delivered successfully');
      },
      onStockUpdated: (_) async {
        debugPrint('Socket stock updated event received; reloading products.');
        dashboardRefreshTick++;
        await loadProducts();
        if (user?.role == UserRoles.admin ||
            user?.role == UserRoles.superAdmin) {
          await loadAdminOrders();
        }
        notifyListeners();
      },
    );
    if (user?.id.isNotEmpty == true) {
      debugPrint('Socket connecting for user room: user:${user!.id}');
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
    final snapshot = _cloneCart();
    final mutationToken = _nextCartMutationToken();
    _setCartQuantity(
      product,
      (cart
              .firstWhere(
                (line) => line.product.id == product.id,
                orElse: () => CartLine(product: product, quantity: 0),
              )
              .quantity) +
          quantity,
    );
    error = null;
    notifyListeners();
    unawaited(
      _syncCartMutation(
        mutationToken: mutationToken,
        snapshot: snapshot,
        action: () async {
          await apiService.post(
            '/cart/add',
            token: token,
            body: {'productId': product.id, 'quantity': quantity},
          );
        },
      ),
    );
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
    final snapshot = _cloneCart();
    final mutationToken = _nextCartMutationToken();
    final nextQuantity = current.quantity <= 1 ? 0 : current.quantity - 1;
    _setCartQuantity(product, nextQuantity);
    error = null;
    notifyListeners();
    unawaited(
      _syncCartMutation(
        mutationToken: mutationToken,
        snapshot: snapshot,
        action: () async {
          if (current.quantity <= 1) {
            await apiService.delete('/cart/remove/${product.id}', token: token);
            return;
          }
          await apiService.put(
            '/cart/update',
            token: token,
            body: {'productId': product.id, 'quantity': nextQuantity},
          );
        },
      ),
    );
    return true;
  }

  Future<bool> _syncClearCart() async {
    if (token == null) {
      error = 'Please login first';
      notifyListeners();
      return false;
    }
    final snapshot = _cloneCart();
    final mutationToken = _nextCartMutationToken();
    cart.clear();
    error = null;
    notifyListeners();
    unawaited(
      _syncCartMutation(
        mutationToken: mutationToken,
        snapshot: snapshot,
        action: () async {
          await apiService.delete('/cart/clear', token: token);
        },
      ),
    );
    return true;
  }
}
