import 'package:flutter/material.dart';

import '../models/product_model.dart';

class ProductPriceBreakdown extends StatelessWidget {
  const ProductPriceBreakdown({
    super.key,
    required this.product,
    this.basePrice,
    this.compact = false,
    this.showBreakdown = true,
    this.priceFontSize,
    this.trimWholeDecimals = false,
  });

  final ProductModel product;
  final double? basePrice;
  final bool compact;
  final bool showBreakdown;
  final double? priceFontSize;
  final bool trimWholeDecimals;

  @override
  Widget build(BuildContext context) {
    final base = basePrice ?? product.price;
    final gst = base * product.tax / 100;
    final total = base + gst;
    final currency = (double value) {
      final formatted = trimWholeDecimals && value == value.roundToDouble()
          ? value.toStringAsFixed(0)
          : value.toStringAsFixed(2);
      return 'Rs $formatted';
    };

    if (!showBreakdown) {
      return Text(
        currency(total),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: priceFontSize ?? (compact ? 14 : 18),
          fontWeight: FontWeight.w900,
          color: const Color(0xFF111827),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          currency(base),
          style: TextStyle(
            fontSize: compact ? 13 : 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        Text(
          'GST ${product.tax.toStringAsFixed(0)}% · ${currency(gst)}',
          style: TextStyle(
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
          ),
        ),
        Text(
          'Total ${currency(total)}',
          style: TextStyle(
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFE8541A),
          ),
        ),
      ],
    );
  }
}
