import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../features/customer/services/payment_service.dart';
import '../../providers/app_state.dart';
import '../../widgets/toast_widget.dart';
import 'order_success_screen.dart';

// Stripe brand colour
const _kStripe = Color(0xFF635BFF);

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
  String? _checkoutUrl;
  bool _launchedWebCheckout = false;

  /// The success URL prefix we detect in the WebView navigation.
  static const _successPath = '/api/payments/stripe/success';
  static const _cancelPath = '/api/payments/stripe/cancel';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startStripeCheckout());
  }

  Future<void> _startStripeCheckout() async {
    final state = context.read<AppState>();

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
      // Create Stripe Checkout Session via the backend
      final result = await _paymentService.createStripeCheckoutSession(
        amountInPaise: (state.total * 100).round(),
        token: state.token!,
        currency: 'inr',
        receipt: 'dm_${DateTime.now().millisecondsSinceEpoch}',
        email: state.user?.email,
        contact: state.user?.phone,
        address: state.selectedAddress?.fullAddress,
        description: 'Doormart Delivery Order',
      );

      final stripeUrl = result['url'] as String? ?? '';
      if (stripeUrl.isEmpty) {
        throw StateError('Stripe did not return a checkout URL.');
      }

      _checkoutUrl = stripeUrl;

      if (kIsWeb) {
        // For Web, open Stripe in a new window/tab as WebViews are blocked by Stripe's X-Frame-Options headers.
        final uri = Uri.parse(stripeUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          setState(() {
            _launchedWebCheckout = true;
            _loading = false;
          });
        } else {
          throw StateError('Could not launch secure payment page. Please allow popups.');
        }
      } else {
        // For Mobile, run within the embedded WebView.
        _controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: (request) {
                final url = request.url;
                // Detect Stripe success redirect
                if (url.contains(_successPath)) {
                  _handleSuccess();
                  return NavigationDecision.prevent;
                }
                // Detect Stripe cancel redirect
                if (url.contains(_cancelPath)) {
                  _handleCancel();
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
              onWebResourceError: (err) {
                if (mounted) {
                  setState(() {
                    _error = err.description;
                    _loading = false;
                  });
                }
              },
              onPageFinished: (_) {
                if (mounted) setState(() => _loading = false);
              },
            ),
          )
          ..loadRequest(Uri.parse(stripeUrl));

        if (mounted) setState(() => _loading = false);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _handleSuccess() async {
    final state = context.read<AppState>();
    try {
      await state.checkout(
        address: state.selectedAddress?.fullAddress ?? '',
        paymentMethod: 'stripe',
      );
      if (!mounted) return;
      showToast(context, '✅ Payment successful!');
      Navigator.pushReplacementNamed(context, OrderSuccessScreen.routeName);
    } catch (error) {
      if (!mounted) return;
      showToast(context, error.toString());
    }
  }

  void _handleCancel() {
    if (!mounted) return;
    showToast(context, 'Payment cancelled. Please try again.');
    Navigator.pop(context);
  }

  Future<void> _launchWebUrlAgain() async {
    if (_checkoutUrl != null) {
      final uri = Uri.parse(_checkoutUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          showToast(context, 'Could not open payment window. Please check popup blockers.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text('Secure Payment'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: _loading
              ? const LinearProgressIndicator(
                  backgroundColor: Color(0xFFE8E8E8),
                  valueColor: AlwaysStoppedAnimation<Color>(_kStripe),
                )
              : const SizedBox.shrink(),
        ),
      ),
      body: _error != null
          ? _ErrorView(
              message: _error!,
              onRetry: () {
                setState(() {
                  _error = null;
                  _loading = true;
                  _launchedWebCheckout = false;
                });
                _startStripeCheckout();
              },
            )
          : _launchedWebCheckout
              ? _WebConfirmationView(
                  onConfirm: _handleSuccess,
                  onCancel: _handleCancel,
                  onLaunchAgain: _launchWebUrlAgain,
                )
              : _controller == null
                  ? const Center(
                      child: CircularProgressIndicator(color: _kStripe),
                    )
                  : WebViewWidget(controller: _controller!),
    );
  }
}

// ─── Web Confirmation View ───────────────────────────────────────────────────

class _WebConfirmationView extends StatelessWidget {
  const _WebConfirmationView({
    required this.onConfirm,
    required this.onCancel,
    required this.onLaunchAgain,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final VoidCallback onLaunchAgain;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.open_in_new_rounded,
                color: _kStripe,
                size: 44,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Checkout Opened',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Stripe Checkout has been opened in a new tab. Please complete your transaction there and return here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kStripe,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'I Have Paid Successfully',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onLaunchAgain,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4B5563),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Launch Payment Page Again',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Cancel & Go Back',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFFFEEEE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFE53935), size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'Payment Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kStripe,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999)),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
