import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfupi.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfupipayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import 'package:provider/provider.dart';

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

class _PaymentScreenState extends State<PaymentScreen>
    with WidgetsBindingObserver {
  final PaymentService _paymentService = PaymentService();
  final CFPaymentGatewayService _gatewayService = CFPaymentGatewayService();

  bool _loading = true;
  bool _processingPayment = false;
  bool _verifyingPayment = false;
  String? _error;
  String? _orderId;
  String? _paymentSessionId;
  CFEnvironment? _environment;

  bool get _canStartPayment =>
      !_loading && !_processingPayment && !_verifyingPayment && !_hasFatalError;

  bool get _hasFatalError =>
      (_orderId == null || _orderId!.isEmpty) ||
      (_paymentSessionId == null || _paymentSessionId!.isEmpty);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _gatewayService.setCallback(_onPaymentVerified, _onPaymentError);
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareCheckout());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _processingPayment &&
        !_verifyingPayment &&
        _orderId != null &&
        _orderId!.isNotEmpty) {
      unawaited(_verifyCashfreeOrder(_orderId!));
    }
  }

  Future<void> _prepareCheckout() async {
    final state = context.read<AppState>();
    final address = state.selectedAddress;
    final addressText = address?.fullAddress ?? '';

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

    setState(() {
      _loading = true;
      _error = null;
      _orderId = null;
      _paymentSessionId = null;
      _environment = null;
    });

    try {
      final data = await _paymentService.createCashfreeOrder(
        amountInPaise: (state.total * 100).round(),
        token: state.token!,
        receipt: 'dm_${DateTime.now().millisecondsSinceEpoch}',
        email: state.user?.email,
        contact: state.user?.phone,
        address: addressText,
        products: state.cart.map((line) => line.toOrderJson()).toList(),
        deliveryFee: state.deliveryFee,
        gstPercent: state.gstPercent,
        deliveryAddress: address == null
            ? null
            : {
                'line1': address.line1,
                'area': address.area,
                'landmark': address.landmark,
                'city': address.city,
                'state': address.state,
                'pincode': address.pincode,
                'label': address.label,
                'fullAddress': address.fullAddress,
                ...address.toLocationJson(),
              },
      );

      _orderId = _readString(data, const ['orderId', 'order_id']);
      _paymentSessionId = _readString(data, const [
        'paymentSessionId',
        'payment_session_id',
      ]);
      _environment = _parseEnvironment(
        _readString(data, const ['environment']),
      );

      final raw = data['raw'];
      if ((_paymentSessionId == null || _paymentSessionId!.isEmpty) &&
          raw is Map<String, dynamic>) {
        _paymentSessionId = _readString(raw, const [
          'payment_session_id',
          'paymentSessionId',
        ]);
      }

      if (_orderId == null || _orderId!.isEmpty) {
        throw StateError('Cashfree order id was not created');
      }
      if (_paymentSessionId == null || _paymentSessionId!.isEmpty) {
        throw StateError('Cashfree payment session was not created');
      }

      if (mounted) {
        setState(() {
          _loading = false;
          _error = null;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _orderId = null;
        _paymentSessionId = null;
        _environment = null;
        _error = error.toString();
      });
    }
  }

  Future<void> _startPayment() async {
    if (!_canStartPayment) return;

    try {
      setState(() {
        _processingPayment = true;
        _error = null;
      });

      final session = _createSession();
      if (session == null) {
        if (mounted) {
          setState(() => _processingPayment = false);
          showToast(context, 'Unable to create Cashfree session');
        }
        return;
      }

      final upi = CFUPIBuilder()
          .setChannel(CFUPIChannel.INTENT_WITH_UI)
          .build();
      final payment = CFUPIPaymentBuilder()
          .setSession(session)
          .setUPI(upi)
          .build();
      _gatewayService.doPayment(payment);
    } on CFException catch (error) {
      if (!mounted) return;
      setState(() => _processingPayment = false);
      showToast(context, error.message);
    } catch (error) {
      if (!mounted) return;
      setState(() => _processingPayment = false);
      showToast(context, error.toString());
    }
  }

  CFSession? _createSession() {
    final orderId = _orderId;
    final paymentSessionId = _paymentSessionId;
    if (orderId == null ||
        orderId.isEmpty ||
        paymentSessionId == null ||
        paymentSessionId.isEmpty ||
        _environment == null) {
      return null;
    }

    try {
      return CFSessionBuilder()
          .setEnvironment(_environment!)
          .setOrderId(orderId)
          .setPaymentSessionId(paymentSessionId)
          .build();
    } on CFException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
      return null;
    }
  }

  void _onPaymentVerified(String orderId) {
    unawaited(_verifyCashfreeOrder(orderId));
  }

  void _onPaymentError(CFErrorResponse errorResponse, String orderId) {
    if (!mounted) return;
    setState(() {
      _processingPayment = false;
      _verifyingPayment = false;
    });
    final message = (errorResponse.getMessage() ?? '').trim();
    showToast(
      context,
      message.isEmpty
          ? 'Payment failed for order ${orderId.isEmpty ? 'unknown' : orderId}'
          : message,
    );
  }

  Future<void> _verifyCashfreeOrder(String orderId) async {
    if (_verifyingPayment) return;

    final state = context.read<AppState>();
    final token = state.token;
    final address = state.selectedAddress;
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() => _processingPayment = false);
        showToast(context, 'Please login again to verify payment');
      }
      return;
    }

    setState(() {
      _verifyingPayment = true;
    });

    try {
      final data = await _paymentService.verifyCashfreeOrder(
        token: token,
        orderId: orderId,
      );
      final status = _readString(data, const [
        'orderStatus',
        'order_status',
        'status',
      ]).toUpperCase();

      if (status == 'PAID') {
        if (address == null) {
          throw StateError('Please select a delivery address');
        }
        await state.checkout(
          address: address,
          paymentMethod: 'cashfree',
          paymentId: orderId,
        );
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, OrderSuccessScreen.routeName);
        return;
      }

      if (!mounted) return;
      setState(() => _processingPayment = false);
      showToast(context, 'Payment is not complete yet. Status: $status');
    } catch (error) {
      if (!mounted) return;
      setState(() => _processingPayment = false);
      showToast(context, error.toString());
    } finally {
      if (mounted) {
        setState(() => _verifyingPayment = false);
      }
    }
  }

  CFEnvironment _parseEnvironment(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized == 'production' || normalized == 'prod') {
      return CFEnvironment.PRODUCTION;
    }
    if (normalized == 'sandbox' && !kReleaseMode) {
      return CFEnvironment.SANDBOX;
    }
    throw StateError(
      'Online payments are temporarily unavailable. Please contact support or use cash on delivery.',
    );
  }

  String _readString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null) {
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text('Cashfree UPI Payment'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pay using UPI intent',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a UPI app to pay securely. Your order will be confirmed once your payment is verified.',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Consumer<AppState>(
                builder: (context, state, _) => _SummaryCard(
                  subtotal: state.subtotal,
                  deliveryFee: state.deliveryFee,
                  gstAmount: state.gstAmount,
                  total: state.total,
                ),
              ),
              const SizedBox(height: 20),
              _StatusCard(
                loading: _loading,
                processingPayment: _processingPayment,
                verifyingPayment: _verifyingPayment,
                error: _error,
                orderId: _orderId,
                paymentSessionId: _paymentSessionId,
                environment: _environment,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE8541A),
                    disabledBackgroundColor: const Color(0xFFFFC8B2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _canStartPayment ? _startPayment : null,
                  child: _processingPayment || _verifyingPayment
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Pay with UPI App',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE8541A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _loading || _verifyingPayment
                      ? null
                      : _prepareCheckout,
                  child: const Text(
                    'Refresh payment session',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'After paying, return here and wait for your payment confirmation.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.black.withValues(alpha: 0.5),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.loading,
    required this.processingPayment,
    required this.verifyingPayment,
    required this.error,
    required this.orderId,
    required this.paymentSessionId,
    required this.environment,
  });

  final bool loading;
  final bool processingPayment;
  final bool verifyingPayment;
  final String? error;
  final String? orderId;
  final String? paymentSessionId;
  final CFEnvironment? environment;

  @override
  Widget build(BuildContext context) {
    final statusText = loading
        ? 'Preparing Cashfree session...'
        : processingPayment
        ? 'Opening UPI app...'
        : verifyingPayment
        ? 'Verifying payment on the server...'
        : error != null
        ? 'Unable to prepare payment'
        : 'Ready to pay';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: Color(0xFFE8541A),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (error != null && error!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
          if (!kReleaseMode) ...[
            const SizedBox(height: 12),
            _metaRow(
              'Environment',
              environment == null
                  ? 'Not available'
                  : environment == CFEnvironment.PRODUCTION
                  ? 'Production'
                  : 'Sandbox',
            ),
            _metaRow('Order ID', orderId ?? 'Not generated'),
            _metaRow('Session ID', paymentSessionId ?? 'Not generated'),
          ],
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withValues(alpha: 0.55),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.subtotal,
    required this.deliveryFee,
    required this.gstAmount,
    required this.total,
  });

  final double subtotal;
  final double deliveryFee;
  final double gstAmount;
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
          const SizedBox(height: 8),
          _row('GST', gstAmount),
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
