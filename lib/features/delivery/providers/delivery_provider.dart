import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/api_service.dart';
import '../../../core/constants.dart';
import '../models/delivery_order_model.dart';
import '../models/delivery_person_model.dart';
import '../services/delivery_api_service.dart';
import '../services/delivery_socket_service.dart';

class DeliveryProvider extends ChangeNotifier {
  DeliveryProvider({
    DeliveryApiService? apiService,
    DeliverySocketService? socketService,
  })  : apiService = apiService ?? DeliveryApiService(),
        socketService = socketService ?? DeliverySocketService();

  final DeliveryApiService apiService;
  final DeliverySocketService socketService;

  bool loading = false;
  String? error;
  String? authToken;
  Map<String, dynamic>? authUser;
  DeliveryPersonModel? deliveryPerson;
  DeliveryOrderModel? activeOrder;
  final List<DeliveryOrderModel> pendingRequests = [];
  final List<DeliveryOrderModel> history = [];
  Map<String, dynamic> earningsStats = const {};
  List<Map<String, dynamic>> statusDetails = [];
  bool online = false;
  Timer? _requestRefreshTimer;
  static const _deliveryTokenKey = 'delivery_auth_token';
  static const _deliveryUserKey = 'delivery_auth_user';

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    authToken ??= prefs.getString(_deliveryTokenKey);
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    return _run(() async {
      final response = await apiService.login(email: email, password: password);
      final user = response['user'] as Map<String, dynamic>;
      final delivery = response['deliveryPerson'] as Map<String, dynamic>?;
      authToken = response['token'] as String?;
      authUser = user;
      final role = (user['role'] as String? ?? '').toLowerCase();
      final status = (user['status'] as String? ?? '').toLowerCase();
      if (role != UserRoles.deliveryPerson) {
        throw StateError('Access denied: not a delivery person.');
      }
      if (status != 'active') {
        throw StateError('Access denied: delivery person is inactive.');
      }
      deliveryPerson = DeliveryPersonModel(
        id: user['_id'] as String? ?? user['id'] as String? ?? '',
        name: user['name'] as String? ?? 'Delivery Person',
        phone: user['phone'] as String? ?? '',
        vehicleNumber: delivery?['vehicleNumber'] as String? ?? user['vehicleNumber'] as String? ?? '',
        status: status,
        active: true,
        completedOrders: (user['completedOrders'] as num? ?? 0).toInt(),
        todayEarnings: (user['todayEarnings'] as num? ?? 0).toDouble(),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_deliveryTokenKey, authToken ?? '');
      return true;
    });
  }

  Future<void> loadDashboard() async {
    if (deliveryPerson == null) return;
    await _run(() async {
      final available = await apiService.fetchAvailableOrders(
        deliveryPersonId: deliveryPerson!.id,
        token: authToken,
      );
      pendingRequests
        ..clear()
        ..addAll(available);
      final fetchedActive = await apiService.fetchActiveOrder(
        deliveryPersonId: deliveryPerson!.id,
        token: authToken,
      );
      if (fetchedActive != null) {
        activeOrder = _forceAccepted(fetchedActive);
      }
      history
        ..clear()
        ..addAll(await apiService.fetchHistory(
          deliveryPersonId: deliveryPerson!.id,
          token: authToken,
        ));
      final earnings = await apiService.fetchEarnings(
        deliveryPersonId: deliveryPerson!.id,
        token: authToken,
      );
      earningsStats = earnings;
      final totalEarnings = (earnings['total'] as num?)?.toDouble() ??
          history.fold<double>(0, (sum, order) => sum + (order.deliveryEarning ?? 45));
      deliveryPerson = DeliveryPersonModel(
        id: deliveryPerson!.id,
        name: deliveryPerson!.name,
        phone: deliveryPerson!.phone,
        vehicleNumber: deliveryPerson!.vehicleNumber,
        status: deliveryPerson!.status,
        active: deliveryPerson!.active,
        completedOrders: (earnings['completedOrders'] as num? ?? history.length).toInt(),
        todayEarnings: totalEarnings,
        avatarUrl: deliveryPerson!.avatarUrl,
      );
    });
  }

  Future<void> refreshProfile() async {
    if (authToken == null) return;
    final response = await apiService.fetchProfile(token: authToken);
    final user = response['user'] as Map<String, dynamic>?;
    final delivery = response['deliveryPerson'] as Map<String, dynamic>?;
    if (user == null) return;
    authUser = user;
    deliveryPerson = DeliveryPersonModel(
      id: user['_id'] as String? ?? user['id'] as String? ?? deliveryPerson?.id ?? '',
      name: user['name'] as String? ?? deliveryPerson?.name ?? 'Delivery Person',
      phone: user['phone'] as String? ?? deliveryPerson?.phone ?? '',
      vehicleNumber: delivery?['vehicleNumber'] as String? ?? deliveryPerson?.vehicleNumber ?? '',
      status: user['status'] as String? ?? deliveryPerson?.status ?? 'active',
      active: deliveryPerson?.active ?? true,
      completedOrders: deliveryPerson?.completedOrders ?? 0,
      todayEarnings: deliveryPerson?.todayEarnings ?? 0,
      avatarUrl: deliveryPerson?.avatarUrl,
    );
    notifyListeners();
  }

  Future<String?> updateProfile({
    String? phone,
    String? vehicleNumber,
  }) async {
    if (deliveryPerson == null) return 'Login required';
    try {
      final response = await apiService.updateProfile(
        token: authToken,
        phone: phone,
        vehicleNumber: vehicleNumber,
      );
      final user = response['user'] as Map<String, dynamic>?;
      final delivery = response['deliveryPerson'] as Map<String, dynamic>?;
      if (user != null) {
        authUser = user;
      }
      deliveryPerson = DeliveryPersonModel(
        id: user?['_id'] as String? ?? user?['id'] as String? ?? deliveryPerson!.id,
        name: user?['name'] as String? ?? deliveryPerson!.name,
        phone: user?['phone'] as String? ?? deliveryPerson!.phone,
        vehicleNumber: delivery?['vehicleNumber'] as String? ?? deliveryPerson!.vehicleNumber,
        status: user?['status'] as String? ?? deliveryPerson!.status,
        active: deliveryPerson!.active,
        completedOrders: deliveryPerson!.completedOrders,
        todayEarnings: deliveryPerson!.todayEarnings,
        avatarUrl: deliveryPerson!.avatarUrl,
      );
      final prefs = await SharedPreferences.getInstance();
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> loadStatusDetails() async {
    if (deliveryPerson == null || authToken == null) return;
    statusDetails = await apiService.fetchStatusDetails(token: authToken);
    notifyListeners();
  }

  Future<void> goOnline() async {
    if (deliveryPerson == null) return;
    await _run(() async {
      final person = await apiService.goOnline(
        deliveryPerson!.id,
        token: authToken,
      );
      deliveryPerson = DeliveryPersonModel(
        id: person.id,
        name: person.name,
        phone: person.phone,
        vehicleNumber: person.vehicleNumber,
        status: person.status,
        active: person.active,
        completedOrders: person.completedOrders,
        todayEarnings: person.todayEarnings,
        avatarUrl: person.avatarUrl,
      );
      online = true;
      socketService.connect(
        deliveryPersonId: deliveryPerson!.id,
        deliveryPersonName: deliveryPerson!.name,
        onNewOrderRequest: _handleNewOrderRequest,
        onOrderTaken: _handleOrderTaken,
        onOrderAssigned: _handleOrderAssigned,
        onOrderPickedUp: _handleOrderPickedUp,
        onOrderDelivered: _handleOrderDelivered,
      );
      await loadDashboard();
      _startRequestRefresh();
    });
  }

  Future<void> goOffline() async {
    if (deliveryPerson == null) return;
    await _run(() async {
      await apiService.goOffline(
        deliveryPerson!.id,
        token: authToken,
      );
      online = false;
      socketService.emitDeliveryOffline(deliveryPersonId: deliveryPerson!.id);
      socketService.disconnect();
      pendingRequests.clear();
      _stopRequestRefresh();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_deliveryTokenKey);
    });
  }

  Future<String?> acceptOrder(DeliveryOrderModel order) async {
    if (deliveryPerson == null) return 'Login required';
    try {
      final accepted = await apiService.acceptOrder(
        orderId: order.id,
        deliveryPersonId: deliveryPerson!.id,
        token: authToken,
      );
      activeOrder = _forceAccepted(accepted);
      socketService.emitAcceptOrder(orderId: order.id, deliveryPersonId: deliveryPerson!.id);
      pendingRequests.removeWhere((item) => item.id == order.id);
      await loadDashboard();
      activeOrder = _forceAccepted(activeOrder ?? accepted);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        return 'Order already accepted by another delivery person.';
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  void removePendingOrder(String orderId) {
    pendingRequests.removeWhere((item) => item.id == orderId);
    notifyListeners();
  }

  Future<String?> rejectOrder(DeliveryOrderModel order) async {
    if (deliveryPerson == null) return 'Login required';
    try {
      await apiService.rejectOrder(
        orderId: order.id,
        deliveryPersonId: deliveryPerson!.id,
        token: authToken,
      );
      pendingRequests.removeWhere((item) => item.id == order.id);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> markPickedUp() async {
    if (deliveryPerson == null || activeOrder == null) return 'No active order';
    try {
      activeOrder = await apiService.markPickedUp(
        orderId: activeOrder!.id,
        deliveryPersonId: deliveryPerson!.id,
        token: authToken,
      );
      await loadDashboard();
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> markDelivered(String otp) async {
    if (deliveryPerson == null || activeOrder == null) return 'No active order';
    try {
      activeOrder = await apiService.markDelivered(
        orderId: activeOrder!.id,
        deliveryPersonId: deliveryPerson!.id,
        otp: otp,
        token: authToken,
      );
      await loadDashboard();
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    await goOffline();
    deliveryPerson = null;
    activeOrder = null;
    history.clear();
    pendingRequests.clear();
    earningsStats = const {};
    _stopRequestRefresh();
    notifyListeners();
  }

  void _handleNewOrderRequest(dynamic data) {
    final map = _normalize(data);
    if (map == null) return;
    final order = DeliveryOrderModel.fromJson(map);
    if (pendingRequests.every((item) => item.id != order.id)) {
      pendingRequests.insert(0, order);
      notifyListeners();
    }
  }

  void _startRequestRefresh() {
    _requestRefreshTimer?.cancel();
    _requestRefreshTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      if (!online || deliveryPerson == null) return;
      try {
        final available = await apiService.fetchAvailableOrders(
          deliveryPersonId: deliveryPerson!.id,
          token: authToken,
        );
        final currentIds = pendingRequests.map((item) => item.id).toSet();
        var changed = false;
        for (final order in available) {
          if (!currentIds.contains(order.id)) {
            pendingRequests.insert(0, order);
            changed = true;
          }
        }
        if (changed) notifyListeners();
      } catch (_) {
        // Keep the live socket flow as the primary source; polling is only a fallback.
      }
    });
  }

  void _stopRequestRefresh() {
    _requestRefreshTimer?.cancel();
    _requestRefreshTimer = null;
  }

  void _handleOrderTaken(dynamic data) {
    final map = _normalize(data);
    final orderId = _extractOrderId(data) ?? map?['_id'] as String?;
    if (orderId == null) return;
    removePendingOrder(orderId);
  }

  void _handleOrderAssigned(dynamic data) {
    final map = _normalize(data);
    if (map == null) return;
    activeOrder = _forceAccepted(DeliveryOrderModel.fromJson(map));
    pendingRequests.removeWhere((item) => item.id == activeOrder!.id);
    history.removeWhere((item) => item.id == activeOrder!.id);
    notifyListeners();
  }

  void _handleOrderPickedUp(dynamic data) {
    final map = _normalize(data);
    if (map == null) return;
    activeOrder = DeliveryOrderModel.fromJson(map);
    notifyListeners();
  }

  void _handleOrderDelivered(dynamic data) {
    final map = _normalize(data);
    if (map == null) return;
    final deliveredOrder = DeliveryOrderModel.fromJson(map);
    history.insert(0, deliveredOrder);
    if (activeOrder?.id == deliveredOrder.id) {
      activeOrder = null;
    }
    notifyListeners();
  }

  Future<T> _run<T>(FutureOr<T> Function() fn) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await fn();
      return result;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic>? _normalize(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['order'] is Map<String, dynamic>) return data['order'] as Map<String, dynamic>;
      return data;
    }
    return null;
  }

  DeliveryOrderModel _forceAccepted(DeliveryOrderModel order) {
    if (order.status == DeliveryOrderStatus.accepted ||
        order.status == DeliveryOrderStatus.pickedUp ||
        order.status == DeliveryOrderStatus.outForDelivery ||
        order.status == DeliveryOrderStatus.delivered) {
      return order;
    }
    return DeliveryOrderModel.fromJson({
      '_id': order.id,
      'orderId': order.orderId,
      'customerName': order.customerName,
      'customerPhone': order.customerPhone,
      'customerAddress': order.customerAddress,
      'customerArea': order.customerArea,
      'items': order.items
          .map(
            (item) => {
              'imageUrl': item.imageUrl,
              'name': item.name,
              'quantity': item.quantity,
              'price': item.unitPrice,
            },
          )
          .toList(),
      'totalAmount': order.totalAmount,
      'paymentType': order.paymentType,
      'status': 'ACCEPTED',
      'createdAt': order.createdAt.toIso8601String(),
      'codAmount': order.codAmount,
      'deliveryEarning': order.deliveryEarning,
    });
  }

  String? _extractOrderId(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['orderId'] as String? ?? data['id'] as String? ?? (data['order'] is Map<String, dynamic> ? (data['order'] as Map<String, dynamic>)['_id'] as String? : null);
    }
    return null;
  }
}
