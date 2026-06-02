class RazorpayService {
  Future<String> startPayment({
    required double amount,
    required String orderId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return 'pay_demo_$orderId';
  }
}
