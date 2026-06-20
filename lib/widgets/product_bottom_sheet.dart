import 'package:flutter/material.dart';

import '../core/utils/network_image_url.dart';
import '../models/product_model.dart';

Future<void> showProductBottomSheet(
  BuildContext context,
  ProductModel product, {
  Future<void> Function(int quantity)? onAddToCart,
}) {
  final mediaQuery = MediaQuery.of(context);
  final sheetHeight = mediaQuery.size.height * 0.72;
  final sheetWidth = mediaQuery.size.width;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
          child: SizedBox(
            height: sheetHeight,
            width: sheetWidth,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Card(
                clipBehavior: Clip.antiAlias,
                elevation: 14,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _ProductBackground(product: product),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0xCC000000),
                            Color(0x22000000),
                            Color(0x00000000),
                          ],
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: IconButton.filledTonal(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Rs ${product.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              product.unit,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _descriptionFor(product),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _QuantityAddToCartBar(
                              onAddToCart: (quantity) async {
                                await onAddToCart?.call(quantity);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _QuantityAddToCartBar extends StatefulWidget {
  const _QuantityAddToCartBar({required this.onAddToCart});

  final Future<void> Function(int quantity) onAddToCart;

  @override
  State<_QuantityAddToCartBar> createState() => _QuantityAddToCartBarState();
}

class _QuantityAddToCartBarState extends State<_QuantityAddToCartBar> {
  int _quantity = 1;

  void _increment() => setState(() => _quantity += 1);

  void _decrement() {
    if (_quantity == 1) return;
    setState(() => _quantity -= 1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: _decrement,
            icon: const Icon(Icons.remove),
          ),
          const SizedBox(width: 8),
          Text(
            '$_quantity',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: _increment,
            icon: const Icon(Icons.add),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => widget.onAddToCart(_quantity),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF14532D),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Add to Cart'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductBackground extends StatelessWidget {
  const _ProductBackground({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final imageUrl = NetworkImageUrl.normalize(product.imageUrl);
    debugPrint('Cloudinary Image URL (product sheet): $imageUrl');
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _fallbackBackground(product),
      );
    }
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (_, __, ___) => _fallbackBackground(product),
      );
    }
    return _fallbackBackground(product);
  }
}

Widget _fallbackBackground(ProductModel product) {
  final asset = _bestImageAsset(product);
  return Image.asset(
    asset,
    fit: BoxFit.cover,
    gaplessPlayback: true,
    width: double.infinity,
    height: double.infinity,
    errorBuilder: (_, __, ___) => Container(
      color: _categoryColor(product.category),
      child: Center(
        child: Icon(
          _categoryIcon(product.category),
          size: 88,
          color: const Color(0xFF0F9D58),
        ),
      ),
    ),
  );
}

String _descriptionFor(ProductModel product) {
  return 'Fresh ${product.name.toLowerCase()} with reliable delivery and great value for your daily shopping needs.';
}

IconData _categoryIcon(String category) {
  return switch (category.toLowerCase()) {
    'vegetables' => Icons.eco,
    'fruits' => Icons.apple,
    'dairy' => Icons.local_drink,
    'staples' => Icons.rice_bowl,
    _ => Icons.local_grocery_store,
  };
}

Color _categoryColor(String category) {
  return switch (category.toLowerCase()) {
    'vegetables' => const Color(0xFFE7F7EC),
    'fruits' => const Color(0xFFFFF0D7),
    'dairy' => const Color(0xFFEAF1FF),
    'staples' => const Color(0xFFFFEFEA),
    _ => const Color(0xFFF1F4EF),
  };
}

String _bestImageAsset(ProductModel product) {
  final name = product.name.toLowerCase();
  final category = product.category.toLowerCase();

  if (name.contains('tomato')) return 'assets/images/products/tomato.png';
  if (name.contains('milk')) return 'assets/images/products/milk.png';
  if (name.contains('rice')) return 'assets/images/products/rice.png';
  if (name.contains('dal') || name.contains('toor')) {
    return 'assets/images/products/dal.png';
  }
  if (name.contains('ghee')) return 'assets/images/products/oil.png';
  if (name.contains('ice cream')) return 'assets/images/products/milk.png';
  if (name.contains('banana') || name.contains('fruit')) {
    return 'assets/images/products/banana.png';
  }

  return switch (category) {
    'vegetables' => 'assets/images/products/tomato.png',
    'fruits' => 'assets/images/products/banana.png',
    'dairy' => 'assets/images/products/milk.png',
    'staples' => 'assets/images/products/rice.png',
    _ => 'assets/images/products/oil.png',
  };
}
