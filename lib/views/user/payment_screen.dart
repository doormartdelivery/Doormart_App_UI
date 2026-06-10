import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../features/customer/services/payment_service.dart';
import '../../providers/app_state.dart';
import '../../widgets/toast_widget.dart';
import 'order_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});
  static const routeName = '/payment';

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  WebViewController? _controller;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _cashfreeOrder;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCashfreeCheckout());
  }

  Future<void> _startCashfreeCheckout() async {
    final state = context.read<AppState>();
    final address = state.selectedAddress?.fullAddress ?? '';
    if (state.token == null) {
      if (mounted) showToast(context, 'Please login first');
      if (mounted) Navigator.pop(context);
      return;
    }
    if (state.cart.isEmpty) {
      if (mounted) showToast(context, 'Your cart is empty');
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() => _loading = true);
    try {
      final order = await _paymentService.createCashfreeOrder(
        amountInPaise: (state.total * 100).round(),
        token: state.token!,
        receipt: 'dm_${DateTime.now().millisecondsSinceEpoch}',
        email: state.user?.email,
        contact: state.user?.phone,
        address: address,
      );
      _cashfreeOrder = order;
      final paymentSessionId = order['paymentSessionId'] as String? ??
          order['payment_session_id'] as String? ??
          '';
      final orderId = order['orderId'] as String? ?? order['order_id'] as String? ?? '';
      if (paymentSessionId.isEmpty || orderId.isEmpty) {
        throw StateError('Cashfree order was not created correctly');
      }

      final mode = (dotenv.env['CASHFREE_MODE'] ?? 'sandbox').trim();
      final returnUrlTemplate =
          dotenv.env['CASHFREE_RETURN_URL'] ??
          'http://10.0.2.2:5000/api/payments/cashfree-return?order_id={order_id}';
      final returnUrl = returnUrlTemplate.replaceAll('{order_id}', orderId);
      final html = _buildCheckoutHtml(
        mode: mode,
        paymentSessionId: paymentSessionId,
        returnUrl: returnUrl,
      );

      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (request) {
              final url = request.url;
              if (url.startsWith(returnUrl.split('?').first)) {
                _handlePaymentReturn(orderId);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
            onWebResourceError: (error) {
              if (mounted) {
                setState(() {
                  _error = error.description;
                  _loading = false;
                });
              }
            },
          ),
        )
        ..loadHtmlString(html, baseUrl: 'https://cashfree.local');

      if (mounted) setState(() => _loading = false);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  String _buildCheckoutHtml({
    required String mode,
    required String paymentSessionId,
    required String returnUrl,
  }) {
    final escapedReturnUrl = HtmlEscape(HtmlEscapeMode.element).convert(returnUrl);
    return '''
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Cashfree Checkout</title>
    <script src="https://sdk.cashfree.com/js/v3/cashfree.js"></script>
    <style>
      body { font-family: Arial, sans-serif; padding: 24px; background: #f6f6f6; color: #1a1a1a; }
      .card { background: white; border-radius: 18px; padding: 20px; box-shadow: 0 8px 20px rgba(0,0,0,.08); }
      .btn { margin-top: 18px; background: #e8541a; color: white; border: none; border-radius: 14px; padding: 14px 18px; font-size: 16px; font-weight: 700; width: 100%; }
    </style>
  </head>
  <body>
    <div class="card">
      <h2>Cashfree Payment</h2>
      <p>Redirecting you to secure checkout...</p>
      <button class="btn" onclick="openCheckout()">Pay Now</button>
    </div>
    <script>
      const cashfree = Cashfree({ mode: "${mode == 'production' ? 'production' : 'sandbox'}" });
      function openCheckout() {
        cashfree.checkout({
          paymentSessionId: "$paymentSessionId",
          redirectTarget: "_self"
        });
      }
      window.addEventListener('load', openCheckout);
    </script>
  </body>
</html>
''';
  }

  Future<void> _handlePaymentReturn(String orderId) async {
    final state = context.read<AppState>();
    try {
      final status = await _paymentService.cashfreeOrderStatus(
        token: state.token!,
        orderId: orderId,
      );
      final orderStatus = (status['order_status'] ?? status['status'] ?? '').toString().toUpperCase();
      if (orderStatus == 'PAID') {
        await state.checkout(
          address: state.selectedAddress?.fullAddress ?? '',
          paymentMethod: 'cashfree',
          paymentId: orderId,
        );
        if (!mounted) return;
        showToast(context, 'Payment successful');
        Navigator.pushReplacementNamed(context, OrderSuccessScreen.routeName);
        return;
      }
      if (!mounted) return;
      showToast(context, 'Payment not completed yet: $orderStatus');
    } catch (error) {
      if (!mounted) return;
      showToast(context, error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text('Cashfree Payment'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8541A)))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                )
              : WebViewWidget(controller: _controller!),
    );
  }
}
