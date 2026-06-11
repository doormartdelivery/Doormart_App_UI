import 'package:flutter/material.dart';
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
  bool _loading = true;
  String? _error;
  String? _orderId;
  String? _paymentSessionId;
  String _cashfreeMode = 'sandbox';
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCheckout());
  }

  Future<void> _startCheckout() async {
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
      final data = await _paymentService.createCashfreeOrder(
        amountInPaise: (state.total * 100).round(),
        token: state.token!,
        receipt: 'dm_${DateTime.now().millisecondsSinceEpoch}',
        email: state.user?.email,
        contact: state.user?.phone,
        address: address,
      );

      _orderId = data['orderId'] as String? ?? data['order_id'] as String?;
      _paymentSessionId = data['paymentSessionId'] as String? ??
          data['payment_session_id'] as String? ??
          '';
      _cashfreeMode = (data['environment'] as String? ?? 'sandbox').toLowerCase();
      final paymentUrl =
          data['paymentUrl'] as String? ??
          data['payment_link'] as String? ??
          data['paymentLink'] as String? ??
          data['url'] as String? ??
          '';
      final raw = data['raw'];
      final rawPaymentSessionId = raw is Map<String, dynamic>
          ? (raw['payment_session_id'] as String? ??
              raw['paymentSessionId'] as String? ??
              '')
          : '';
      if (_paymentSessionId == null || _paymentSessionId!.isEmpty) {
        _paymentSessionId = rawPaymentSessionId;
      }
      if (_paymentSessionId == null || _paymentSessionId!.isEmpty) {
        throw StateError('Cashfree payment session was not created');
      }
      final html = _cashfreeCheckoutHtml(
        paymentSessionId: _paymentSessionId!,
        mode: _cashfreeMode,
      );
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFFF6F6F6))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) async {
              if (url.contains('/api/payments/cashfree/success')) {
                if (!mounted) return;
                Navigator.of(context).pop();
                await _checkPaymentStatus();
              }
            },
            onNavigationRequest: (request) {
              if (request.url.contains('/api/payments/cashfree/success')) {
                if (mounted) {
                  Navigator.of(context).pop();
                  _checkPaymentStatus();
                }
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadHtmlString(html);

      setState(() {
        _webViewController = controller;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _checkPaymentStatus() async {
    final state = context.read<AppState>();
    final orderId = _orderId;
    if (state.token == null || orderId == null) return;
    try {
      final data = await _paymentService.cashfreeOrderStatus(
        token: state.token!,
        orderId: orderId,
      );
      final status = (data['order_status'] ?? data['status'] ?? '').toString().toUpperCase();
      if (status == 'PAID') {
        await state.checkout(
          address: state.selectedAddress?.fullAddress ?? '',
          paymentMethod: 'cashfree',
          paymentId: orderId,
        );
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, OrderSuccessScreen.routeName);
      } else if (mounted) {
        showToast(context, 'Payment status: $status');
      }
    } catch (error) {
      if (mounted) showToast(context, error.toString());
    }
  }

  String _cashfreeCheckoutHtml({
    required String paymentSessionId,
    required String mode,
  }) {
    return '''
<!doctype html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <style>
      html, body {
        margin: 0;
        padding: 0;
        width: 100%;
        height: 100%;
        background: #f6f6f6;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      }
      .center {
        height: 100%;
        display: flex;
        align-items: center;
        justify-content: center;
        flex-direction: column;
        color: #1a1a1a;
        gap: 12px;
      }
      .spinner {
        width: 38px;
        height: 38px;
        border-radius: 50%;
        border: 4px solid #f0d6c8;
        border-top-color: #e8541a;
        animation: spin 0.9s linear infinite;
      }
      @keyframes spin { to { transform: rotate(360deg); } }
    </style>
    <script src="https://sdk.cashfree.com/js/v3/cashfree.js"></script>
  </head>
  <body>
    <div class="center">
      <div class="spinner"></div>
      <div>Opening Cashfree checkout...</div>
    </div>
    <script>
      (function () {
        try {
          const cashfree = Cashfree({ mode: '$mode' });
          cashfree.checkout({ paymentSessionId: '$paymentSessionId' });
        } catch (err) {
          document.body.innerHTML = '<pre style="white-space: pre-wrap; padding: 16px;">' + err + '</pre>';
        }
      })();
    </script>
  </body>
</html>
''';
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
      body: _webViewController == null
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pay securely with Cashfree',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'We will open the official Cashfree checkout inside the app.',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Consumer<AppState>(
                    builder: (context, state, _) => _SummaryCard(
                      subtotal: state.subtotal,
                      deliveryFee: state.deliveryFee,
                      total: state.total,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_loading)
                    const LinearProgressIndicator(color: Color(0xFFE8541A)),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE8541A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _loading ? null : _checkPaymentStatus,
                      child: const Text(
                        'Check Payment Status',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : WebViewWidget(controller: _webViewController!),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
  });

  final double subtotal;
  final double deliveryFee;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _row('Subtotal', subtotal),
          const SizedBox(height: 8),
          _row('Delivery fee', deliveryFee),
          const Divider(height: 24),
          _row('Total', total, bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, double amount, {bool bold = false}) {
    final style = TextStyle(
      fontSize: bold ? 16 : 14,
      fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text('Rs ${amount.toStringAsFixed(2)}', style: style),
      ],
    );
  }
}
