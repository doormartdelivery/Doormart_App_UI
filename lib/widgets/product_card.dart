import 'package:flutter/material.dart';

import '../models/product_model.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onAdd});

  final ProductModel product;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _categoryColor(product.category),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _ProductImage(product: product),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8A00),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '10% OFF',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                product.unit,
                style: const TextStyle(fontSize: 12, color: Color(0xFF667064)),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.timer, size: 14, color: Color(0xFF0F9D58)),
                  const SizedBox(width: 3),
                  Text(
                    '${product.stock > 20 ? 10 : 18} min',
                    style: const TextStyle(fontSize: 11),
                  ),
                  const Spacer(),
                  const Icon(Icons.star, size: 14, color: Color(0xFFFFB300)),
                  Text(
                    product.rating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rs ${product.price.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'MRP Rs ${(product.price * 1.12).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8A9387),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 34,
                    child: FilledButton(
                      onPressed: onAdd,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        backgroundColor: const Color(0xFF0F9D58),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('ADD'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final path = product.imageUrl;
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _fallbackIcon(product.category),
      );
    }
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _fallbackIcon(product.category),
      );
    }
    return _fallbackIcon(product.category);
  }
}

Widget _fallbackIcon(String category) {
  return Icon(
    _categoryIcon(category),
    size: 54,
    color: const Color(0xFF0F9D58),
  );
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
