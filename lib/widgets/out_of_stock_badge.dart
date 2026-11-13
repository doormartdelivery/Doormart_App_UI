import 'package:flutter/material.dart';

bool isProductOutOfStock(dynamic product) {
  final stock = (product.stock as num?)?.toInt() ?? 0;
  final variants = product.unitVariants as List<dynamic>? ?? const [];
  final variantInStock = variants.any(
    (variant) => ((variant.stock as num?)?.toInt() ?? 0) > 0,
  );
  return stock <= 0 && !variantInStock;
}

class OutOfStockBadge extends StatelessWidget {
  const OutOfStockBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE11D48),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Text(
        'OUT OF STOCK',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: .3,
        ),
      ),
    );
  }
}
