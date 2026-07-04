import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/utils/network_image_url.dart';
import '../models/product_model.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kOrange = Color(0xFFE8541A);
const _kOrangeDeep = Color(0xFFD44010);
const _kOrangeLight = Color(0xFFFFF0EB);
const _kGreen = Color(0xFF0F9D58);
const _kGreenLight = Color(0xFFEAF7EF);

Future<void> showProductBottomSheet(
  BuildContext context,
  ProductModel product, {
  Future<void> Function(int quantity)? onAddToCart,
}) {
  final mq = MediaQuery.of(context);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _ProductSheet(product: product, onAddToCart: onAddToCart),
          ),
        ),
      );
    },
  );
}

// ─── Main Sheet ───────────────────────────────────────────────────────────────

class _ProductSheet extends StatefulWidget {
  const _ProductSheet({required this.product, required this.onAddToCart});
  final ProductModel product;
  final Future<void> Function(int quantity)? onAddToCart;

  @override
  State<_ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends State<_ProductSheet>
    with SingleTickerProviderStateMixin {
  int _quantity = 1;
  bool _adding = false;

  // Sheet entry animation
  late final AnimationController _entryCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  )..forward();

  late final Animation<Offset> _slideAnim = Tween<Offset>(
    begin: const Offset(0, 0.12),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

  late final Animation<double> _fadeAnim =
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  void _increment() {
    HapticFeedback.selectionClick();
    setState(() => _quantity++);
  }

  void _decrement() {
    if (_quantity <= 1) return;
    HapticFeedback.selectionClick();
    setState(() => _quantity--);
  }

  Future<void> _addToCart() async {
    HapticFeedback.mediumImpact();
    setState(() => _adding = true);
    await widget.onAddToCart?.call(_quantity);
    if (mounted) {
      setState(() => _adding = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final catColor = _categoryAccent(product.category);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 40,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Image hero ──────────────────────────────────────────
              _ImageHero(product: product, catColor: catColor),

              // ── Content ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category + rating row
                    Row(
                      children: [
                        _CategoryPill(category: product.category),
                        const Spacer(),
                        _RatingPill(rating: product.rating),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Product name
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.4,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Unit
                    Row(
                      children: [
                        const Icon(Icons.straighten_rounded,
                            size: 14, color: Color(0xFF888888)),
                        const SizedBox(width: 4),
                        Text(
                          _unitLabel(product.unit),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF888888),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.inventory_2_rounded,
                            size: 14, color: Color(0xFF888888)),
                        const SizedBox(width: 4),
                        Text(
                          '${product.stock} in stock',
                          style: TextStyle(
                            fontSize: 13,
                            color: product.stock > 10
                                ? _kGreen
                                : const Color(0xFFE8541A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Price row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Rs ${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: _kOrange,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // MRP strikethrough
                        Text(
                          'Rs ${(product.price * 1.15).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFFAAAAAA),
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Color(0xFFAAAAAA),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Discount badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _kGreenLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '13% OFF',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _kGreen,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Delivery promise strip
                    _DeliveryStrip(),

                    const SizedBox(height: 14),

                    // Description
                    Text(
                      _descriptionFor(product),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF888888),
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Quantity + Add to cart ─────────────────────────
                    _QuantityCartBar(
                      quantity: _quantity,
                      adding: _adding,
                      onIncrement: _increment,
                      onDecrement: _decrement,
                      onAddToCart: _addToCart,
                      product: product,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Image Hero ───────────────────────────────────────────────────────────────

class _ImageHero extends StatelessWidget {
  const _ImageHero({required this.product, required this.catColor});
  final ProductModel product;
  final Color catColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  catColor,
                  catColor.withValues(alpha: 0.60),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Decorative circles
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),

          // Product image
          _ProductBackground(product: product),

          // Bottom fade
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 60,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.18),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: 12,
            right: 12,
            child: _CloseButton(),
          ),

          // Wishlist button
          Positioned(
            top: 12,
            left: 12,
            child: _WishlistButton(),
          ),

          // Fresh badge
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded,
                      size: 13, color: _kOrange),
                  SizedBox(width: 3),
                  Text(
                    'Delivered in 10 mins',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Close Button ─────────────────────────────────────────────────────────────

class _CloseButton extends StatefulWidget {
  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );
  late final Animation<double> _s =
      Tween<double>(begin: 1.0, end: 0.88).animate(
    CurvedAnimation(parent: _c, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        Navigator.pop(context);
      },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _s,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.close_rounded,
              size: 18, color: Color(0xFF1A1A1A)),
        ),
      ),
    );
  }
}

// ─── Wishlist Button ──────────────────────────────────────────────────────────

class _WishlistButton extends StatefulWidget {
  @override
  State<_WishlistButton> createState() => _WishlistButtonState();
}

class _WishlistButtonState extends State<_WishlistButton>
    with SingleTickerProviderStateMixin {
  bool _liked = false;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<double> _scale =
      TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
    TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
  ]).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _liked = !_liked);
        _c.forward(from: 0);
      },
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _liked ? _kOrangeLight : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 18,
            color: _liked ? _kOrange : const Color(0xFF888888),
          ),
        ),
      ),
    );
  }
}

// ─── Category Pill ────────────────────────────────────────────────────────────

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    final color = _categoryAccent(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_categoryIcon(category), size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            category,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Rating Pill ──────────────────────────────────────────────────────────────

class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.rating});
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded,
              size: 13, color: Color(0xFFF59E0B)),
          const SizedBox(width: 3),
          Text(
            rating > 0 ? rating.toStringAsFixed(1) : '4.5',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF92400E),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Delivery Strip ───────────────────────────────────────────────────────────

class _DeliveryStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kGreenLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kGreen.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping_rounded,
              size: 16, color: _kGreen),
          const SizedBox(width: 8),
          const Text(
            'Free delivery • Arrives in ',
            style: TextStyle(
              fontSize: 12.5,
              color: _kGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Text(
            '10 minutes',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: _kGreen,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: _kGreen,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'FREE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quantity + Cart Bar ──────────────────────────────────────────────────────

class _QuantityCartBar extends StatelessWidget {
  const _QuantityCartBar({
    required this.quantity,
    required this.adding,
    required this.onIncrement,
    required this.onDecrement,
    required this.onAddToCart,
    required this.product,
  });

  final int quantity;
  final bool adding;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onAddToCart;
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final totalPrice = product.price * quantity;

    return Row(
      children: [
        // ── Quantity selector ──────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QtyBtn(
                icon: Icons.remove_rounded,
                enabled: quantity > 1,
                onTap: onDecrement,
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: child,
                ),
                child: SizedBox(
                  width: 36,
                  child: Text(
                    '$quantity',
                    key: ValueKey(quantity),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ),
              _QtyBtn(
                icon: Icons.add_rounded,
                enabled: true,
                onTap: onIncrement,
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // ── Add to cart button ─────────────────────────────────────────
        Expanded(
          child: _AddToCartButton(
            adding: adding,
            totalPrice: totalPrice,
            onTap: onAddToCart,
          ),
        ),
      ],
    );
  }
}

class _QtyBtn extends StatefulWidget {
  const _QtyBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_QtyBtn> createState() => _QtyBtnState();
}

class _QtyBtnState extends State<_QtyBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );
  late final Animation<double> _s =
      Tween<double>(begin: 1.0, end: 0.80).animate(
    CurvedAnimation(parent: _c, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => _c.forward() : null,
      onTapUp: widget.enabled
          ? (_) {
              _c.reverse();
              widget.onTap();
            }
          : null,
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _s,
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: widget.enabled ? _kOrange : const Color(0xFFDDDDDD),
            borderRadius: BorderRadius.circular(12),
            boxShadow: widget.enabled
                ? [
                    BoxShadow(
                      color: _kOrange.withValues(alpha: 0.30),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Icon(widget.icon,
              color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _AddToCartButton extends StatefulWidget {
  const _AddToCartButton({
    required this.adding,
    required this.totalPrice,
    required this.onTap,
  });
  final bool adding;
  final double totalPrice;
  final VoidCallback onTap;

  @override
  State<_AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<_AddToCartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
  );
  late final Animation<double> _s =
      Tween<double>(begin: 1.0, end: 0.96).animate(
    CurvedAnimation(parent: _c, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.adding ? null : (_) => _c.forward(),
      onTapUp: widget.adding
          ? null
          : (_) {
              _c.reverse();
              widget.onTap();
            },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _s,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: widget.adding
                ? null
                : const LinearGradient(
                    colors: [Color(0xFFF26522), Color(0xFFE8401A)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            color: widget.adding ? const Color(0xFFE0E0E0) : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.adding
                ? []
                : [
                    BoxShadow(
                      color: _kOrange.withValues(alpha: 0.40),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: widget.adding
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_rounded,
                              color: Colors.white, size: 17),
                          SizedBox(width: 6),
                          Text(
                            'Add to Cart',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Rs ${widget.totalPrice.toStringAsFixed(0)} total',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.80),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Product Background Image ─────────────────────────────────────────────────

class _ProductBackground extends StatelessWidget {
  const _ProductBackground({required this.product});
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final imageUrl = NetworkImageUrl.normalize(product.imageUrl);
    debugPrint('ProductSheet image: $imageUrl');

    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _fallbackBackground(product),
      );
    }
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _categoryAccent(product.category),
            ),
          );
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
    fit: BoxFit.contain,
    gaplessPlayback: true,
    errorBuilder: (_, __, ___) => Center(
      child: Icon(
        _categoryIcon(product.category),
        size: 88,
        color: _categoryAccent(product.category),
      ),
    ),
  );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _unitLabel(String value) {
  final unit = value.trim();
  if (unit.isEmpty) return '1 item';
  if (RegExp(r'^\d').hasMatch(unit)) return unit;
  return '1 $unit';
}

String _descriptionFor(ProductModel product) {
  return 'Fresh ${product.name.toLowerCase()} — sourced directly and '
      'delivered to your door in under 10 minutes.';
}

Color _categoryAccent(String category) {
  return switch (category.toLowerCase()) {
    'vegetables' => const Color(0xFF16A34A),
    'fruits' => const Color(0xFFEA580C),
    'dairy' => const Color(0xFF2563EB),
    'staples' => const Color(0xFFB45309),
    'snacks' => const Color(0xFFDB2777),
    'beverages' => const Color(0xFF0891B2),
    _ => _kOrange,
  };
}

IconData _categoryIcon(String category) {
  return switch (category.toLowerCase()) {
    'vegetables' => Icons.eco_rounded,
    'fruits' => Icons.apple_rounded,
    'dairy' => Icons.water_drop_rounded,
    'staples' => Icons.rice_bowl_rounded,
    'snacks' => Icons.cookie_rounded,
    'beverages' => Icons.local_drink_rounded,
    _ => Icons.local_grocery_store_rounded,
  };
}

String _bestImageAsset(ProductModel product) {
  final name = product.name.toLowerCase();
  final cat = product.category.toLowerCase();
  if (name.contains('tomato')) return 'assets/images/products/tomato.png';
  if (name.contains('milk')) return 'assets/images/products/milk.png';
  if (name.contains('rice')) return 'assets/images/products/rice.png';
  if (name.contains('dal') || name.contains('toor')) {
    return 'assets/images/products/dal.png';
  }
  if (name.contains('ghee') || name.contains('oil')) {
    return 'assets/images/products/oil.png';
  }
  if (name.contains('banana')) return 'assets/images/products/banana.png';
  return switch (cat) {
    'vegetables' => 'assets/images/products/tomato.png',
    'fruits' => 'assets/images/products/banana.png',
    'dairy' => 'assets/images/products/milk.png',
    'staples' => 'assets/images/products/rice.png',
    _ => 'assets/images/products/oil.png',
  };
}