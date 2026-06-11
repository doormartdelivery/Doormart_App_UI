import 'dart:async';

import 'package:flutter/material.dart';

import '../models/delivery_order_model.dart';

class NewOrderRequestCard extends StatefulWidget {
  const NewOrderRequestCard({
    super.key,
    required this.order,
    required this.onAccept,
    required this.onReject,
    required this.onExpired,
  });

  final DeliveryOrderModel order;
  final Future<String?> Function() onAccept;
  final Future<String?> Function() onReject;
  final VoidCallback onExpired;

  @override
  State<NewOrderRequestCard> createState() => _NewOrderRequestCardState();
}

class _NewOrderRequestCardState extends State<NewOrderRequestCard> {
  late int _secondsLeft = 30;
  Timer? _timer;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        widget.onExpired();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order ${widget.order.displayOrderId}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                _timerChip(),
              ],
            ),
            const SizedBox(height: 12),
            Text(widget.order.customerArea),
            Text('${widget.order.itemCount} items'),
            Text('₹${widget.order.totalAmount.toStringAsFixed(2)}'),
            Text('Payment: ${widget.order.paymentType}'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _reject,
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy ? null : _accept,
                    child: _busy
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _timerChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$_secondsLeft s', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w700)),
    );
  }

  Future<void> _accept() async {
    setState(() => _busy = true);
    final message = await widget.onAccept();
    if (!mounted) return;
    setState(() => _busy = false);
    if (message != null && message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _reject() async {
    setState(() => _busy = true);
    final message = await widget.onReject();
    if (!mounted) return;
    setState(() => _busy = false);
    if (message != null && message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
