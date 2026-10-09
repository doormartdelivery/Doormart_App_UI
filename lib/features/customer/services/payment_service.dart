import 'package:flutter/foundation.dart';

import '../../../services/api_service.dart';

class PaymentService {
  PaymentService({ApiService? api}) : api = api ?? ApiService();
  final ApiService api;

  Future<Map<String, dynamic>> createCashfreeOrder({
    required int amountInPaise,
    required String token,
    String currency = 'INR',
    String? receipt,
    String? email,
    String? contact,
    String? address,
    List<Map<String, dynamic>>? products,
    double? deliveryFee,
    double? gstPercent,
    bool? useProductTax,
    double? distanceKm,
    Map<String, dynamic>? deliveryAddress,
  }) async {
    final body = <String, dynamic>{
      'amount': amountInPaise,
      'currency': currency,
      if (kReleaseMode) 'environment': 'production',
    };
    if (receipt != null) body['receipt'] = receipt;
    if (email != null) body['email'] = email;
    if (contact != null) body['contact'] = contact;
    if (address != null) body['addressText'] = address;
    if (products != null) body['products'] = products;
    if (deliveryFee != null) body['deliveryFee'] = deliveryFee;
    if (gstPercent != null) body['gstPercent'] = gstPercent;
    if (useProductTax != null) body['useProductTax'] = useProductTax;
    if (distanceKm != null) body['distanceKm'] = distanceKm;
    if (deliveryAddress != null) body['address'] = deliveryAddress;

    return await api.post(
          '/payments/cashfree/create-order',
          token: token,
          body: body,
        )
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cashfreeOrderStatus({
    required String token,
    required String orderId,
  }) async {
    return await api.get('/payments/cashfree/status/$orderId', token: token)
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyCashfreeOrder({
    required String token,
    required String orderId,
  }) async {
    return await api.get(
          '/payments/cashfree/verify-order/$orderId',
          token: token,
        )
        as Map<String, dynamic>;
  }

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
