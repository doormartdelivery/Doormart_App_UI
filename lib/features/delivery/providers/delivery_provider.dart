import 'dart:async';

import 'package:flutter/foundation.dart';

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
  bool online = false;

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    return _run(() async {
      final response = await apiService.login(email: email, password: password);
      final user = response['user'] as Map<String, dynamic>;
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
        vehicleNumber: user['vehicleNumber'] as String? ?? '',
        status: status,
        active: true,
        completedOrders: (user['completedOrders'] as num? ?? 0).toInt(),
        todayEarnings: (user['todayEarnings'] as num? ?? 0).toDouble(),
      );
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
      activeOrder = await apiService.fetchActiveOrder(
        deliveryPersonId: deliveryPerson!.id,
        token: authToken,
      );
      history
        ..clear()
        ..addAll(await apiService.fetchHistory(
          deliveryPersonId: deliveryPerson!.id,
          token: authToken,
        ));
    });
  }

  Future<void> goOnline() async {
    if (deliveryPerson == null) return;
    await _run(() async {
      final person = await apiService.goOnline(
        deliveryPerson!.id,
        token: authToken,
      );
      deliveryPerson = person;
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
    });
  }

  Future<String?> acceptOrder(DeliveryOrderModel order) async {
    if (deliveryPerson == null) return 'Login required';
    try {
      await apiService.acceptOrder(
        orderId: order.id,
        deliveryPersonId: deliveryPerson!.id,
        token: authToken,
      );
      socketService.emitAcceptOrder(orderId: order.id, deliveryPersonId: deliveryPerson!.id);
      pendingRequests.removeWhere((item) => item.id == order.id);
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

  void _handleOrderTaken(dynamic data) {
    final map = _normalize(data);
    final orderId = _extractOrderId(data) ?? map?['_id'] as String?;
    if (orderId == null) return;
    removePendingOrder(orderId);
  }

  void _handleOrderAssigned(dynamic data) {
    final map = _normalize(data);
    if (map == null) return;
    activeOrder = DeliveryOrderModel.fromJson(map);
    pendingRequests.removeWhere((item) => item.id == activeOrder!.id);
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

  String? _extractOrderId(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['orderId'] as String? ?? data['id'] as String? ?? (data['order'] is Map<String, dynamic> ? (data['order'] as Map<String, dynamic>)['_id'] as String? : null);
    }
    return null;
  }
}
