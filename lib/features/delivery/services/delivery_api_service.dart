import '../../../services/api_service.dart';
import '../models/delivery_order_model.dart';
import '../models/delivery_person_model.dart';

class DeliveryApiService {
  DeliveryApiService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    ) as Map<String, dynamic>;
    final user = response['user'] as Map<String, dynamic>?;
    final deliveryPerson = response['deliveryPerson'] as Map<String, dynamic>?;
    if (user == null) {
      throw StateError('Invalid login response');
    }
    return {'user': user, 'deliveryPerson': deliveryPerson, 'token': response['token']};
  }

  Future<DeliveryPersonModel> goOnline(String deliveryPersonId, {String? token}) async {
    final response = await _apiService.post(
      '/delivery/go-online',
      body: {'deliveryPersonId': deliveryPersonId},
      token: token,
    ) as Map<String, dynamic>;
    return DeliveryPersonModel.fromJson((response['deliveryPerson'] as Map<String, dynamic>?) ?? response);
  }

  Future<DeliveryPersonModel> goOffline(String deliveryPersonId, {String? token}) async {
    final response = await _apiService.post(
      '/delivery/go-offline',
      body: {'deliveryPersonId': deliveryPersonId},
      token: token,
    ) as Map<String, dynamic>;
    return DeliveryPersonModel.fromJson((response['deliveryPerson'] as Map<String, dynamic>?) ?? response);
  }

  Future<Map<String, dynamic>> fetchProfile({String? token}) async {
    final response = await _apiService.get('/delivery/profile', token: token);
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile({
    String? token,
    String? phone,
    String? vehicleNumber,
  }) async {
    final response = await _apiService.put(
      '/delivery/profile',
      token: token,
      body: {
        if (phone != null) 'phone': phone,
        if (vehicleNumber != null) 'vehicleNumber': vehicleNumber,
      },
    );
    return response as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> fetchStatusDetails({String? token}) async {
    final response = await _apiService.get('/delivery/status-details', token: token) as List<dynamic>;
    return response.whereType<Map<String, dynamic>>().toList();
  }

  Future<DeliveryOrderModel?> fetchActiveOrder({required String deliveryPersonId, String? token}) async {
    final response = await _apiService.get('/delivery/active-order?deliveryPersonId=$deliveryPersonId', token: token);
    if (response == null) return null;
    if (response is Map<String, dynamic> && response['order'] is Map<String, dynamic>) {
      return DeliveryOrderModel.fromJson(response['order'] as Map<String, dynamic>);
    }
    if (response is Map<String, dynamic>) {
      return DeliveryOrderModel.fromJson(response);
    }
    return null;
  }

  Future<List<DeliveryOrderModel>> fetchHistory({required String deliveryPersonId, String? token}) async {
    final response = await _apiService.get('/delivery/order-history?deliveryPersonId=$deliveryPersonId', token: token) as List<dynamic>;
    return response
        .whereType<Map<String, dynamic>>()
        .map(DeliveryOrderModel.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> fetchEarnings({
    required String deliveryPersonId,
    String? token,
  }) async {
    final response = await _apiService.get('/delivery/earnings?deliveryPersonId=$deliveryPersonId', token: token);
    return (response as Map<String, dynamic>);
  }

  Future<List<DeliveryOrderModel>> fetchAvailableOrders({
    required String deliveryPersonId,
    String? token,
  }) async {
    final response = await _apiService.get('/delivery/orders?deliveryPersonId=$deliveryPersonId', token: token) as List<dynamic>;
    return response
        .whereType<Map<String, dynamic>>()
        .map(DeliveryOrderModel.fromJson)
        .toList();
  }

  Future<DeliveryOrderModel> acceptOrder({
    required String orderId,
    required String deliveryPersonId,
    String? token,
  }) async {
    final response = await _apiService.post(
      '/delivery/orders/$orderId/accept',
      body: {'deliveryPersonId': deliveryPersonId},
      token: token,
    ) as Map<String, dynamic>;
    return DeliveryOrderModel.fromJson((response['order'] as Map<String, dynamic>?) ?? response);
  }

  Future<void> rejectOrder({
    required String orderId,
    required String deliveryPersonId,
    String? token,
  }) async {
    await _apiService.post(
      '/delivery/orders/$orderId/reject',
      body: {'deliveryPersonId': deliveryPersonId},
      token: token,
    );
  }

  Future<DeliveryOrderModel> markPickedUp({
    required String orderId,
    required String deliveryPersonId,
    String? token,
  }) async {
    final response = await _apiService.post(
      '/delivery/orders/$orderId/picked-up',
      body: {'deliveryPersonId': deliveryPersonId},
      token: token,
    ) as Map<String, dynamic>;
    return DeliveryOrderModel.fromJson((response['order'] as Map<String, dynamic>?) ?? response);
  }

  Future<DeliveryOrderModel> markDelivered({
    required String orderId,
    required String deliveryPersonId,
    required String otp,
    String? token,
  }) async {
    final response = await _apiService.post(
      '/delivery/orders/$orderId/delivered',
      body: {'deliveryPersonId': deliveryPersonId, 'otp': otp},
      token: token,
    ) as Map<String, dynamic>;
    return DeliveryOrderModel.fromJson((response['order'] as Map<String, dynamic>?) ?? response);
  }
}
