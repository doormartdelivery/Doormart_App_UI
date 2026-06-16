import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/utils/network_image_url.dart';
import '../../providers/app_state.dart';
import '../../widgets/toast_widget.dart';
import '../app_page.dart';
import 'checkout_screen.dart';
import 'search_screen.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kOrange = Color(0xFFE8541A);
const _kOrangeLight = Color(0xFFFFF0EB);
const _kBg = Color(0xFFF6F6F6);
const _kCard = Colors.white;
const _kTextDark = Color(0xFF1A1A1A);
const _kTextMid = Color(0xFF9E9E9E);

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  static const routeName = '/cart';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────────────────
            _CartAppBar(),

            // ── Item list ─────────────────────────────────────────────────
            Expanded(
              child: Consumer<AppState>(
                builder: (context, state, _) {
                  if (state.cart.isEmpty) {
                    return _EmptyCart();
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: state.cart.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final line = state.cart[index];
                      return _CartItemCard(
                        key: ValueKey(line.product.id),
                        line: line,
                        onIncrement: () async {
                          HapticFeedback.lightImpact();
                          final ok = await state.addToCart(line.product);
                          if (!context.mounted) return;
                          if (!ok) {
                            showToast(context,
                                state.error ?? 'Please login first');
                          }
                        },
                        onDecrement: () async {
                          HapticFeedback.lightImpact();
                          final ok = await state.decrement(line.product);
                          if (!context.mounted) return;
                          if (!ok) {
                            showToast(context,
                                state.error ?? 'Please login first');
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),

            // ── Bottom summary + checkout ──────────────────────────────────
            Consumer<AppState>(
              builder: (context, state, _) =>
                  _BottomBar(state: state),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _CartAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.chevron_left_rounded,
                  size: 26, color: _kTextDark),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Cart',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _kTextDark,
                letterSpacing: -0.4,
              ),
            ),
          ),
          // Search
          _AppBarIcon(
            icon: Icons.search_rounded,
            onTap: () => Navigator.pushNamed(context, SearchScreen.routeName),
          ),
          const SizedBox(width: 10),
          // Cart badge
          Consumer<AppState>(
            builder: (context, state, _) => _AppBarIcon(
              icon: Icons.shopping_bag_outlined,
              badge: state.cart.isEmpty
                  ? null
                  : state.cart
                      .fold<int>(0, (sum, l) => sum + l.quantity)
                      .toString(),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBarIcon extends StatelessWidget {
  const _AppBarIcon({required this.icon, this.badge, required this.onTap});
  final IconData icon;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 22, color: _kTextDark),
          ),
          if (badge != null)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: _kOrange,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Cart Item Card ───────────────────────────────────────────────────────────

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    super.key,
    required this.line,
    required this.onIncrement,
    required this.onDecrement,
  });

  final dynamic line; // your CartLine / CartItem type
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Product image ─────────────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(22),
            ),
            child: SizedBox(
              width: 120,
              height: 110,
              child: _ProductImage(imageUrl: line.product.imageUrl ?? ''),
            ),
          ),

          const SizedBox(width: 14),

          // ── Details ───────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _kTextDark,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    line.product.category ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _kTextMid,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Price
                      Text(
                        'Rs ${line.product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: _kTextDark,
                        ),
                      ),
                      const Spacer(),
                      // ── Quantity pill ──────────────────────────────
                      _QuantityPill(
                        quantity: line.quantity,
                        onDecrement: onDecrement,
                        onIncrement: onIncrement,
                      ),
                      const SizedBox(width: 14),
                    ],
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

// ─── Quantity Pill ────────────────────────────────────────────────────────────

class _QuantityPill extends StatelessWidget {
  const _QuantityPill({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: _kOrange,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: _kOrange.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minus
          _PillBtn(icon: Icons.remove_rounded, onTap: onDecrement),
          // Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: child,
              ),
              child: Text(
                '$quantity',
                key: ValueKey(quantity),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          // Plus
          _PillBtn(icon: Icons.add_rounded, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _PillBtn extends StatefulWidget {
  const _PillBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_PillBtn> createState() => _PillBtnState();
}

class _PillBtnState extends State<_PillBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
    lowerBound: 0,
    upperBound: 1,
  );
  late final Animation<double> _scale =
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
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(widget.icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

// ─── Product Image ────────────────────────────────────────────────────────────

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final normalized = NetworkImageUrl.normalize(imageUrl);
    if (normalized.startsWith('http')) {
      return Image.network(normalized, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const _ImageFallback());
    }
    if (normalized.startsWith('assets/')) {
      return Image.asset(normalized, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const _ImageFallback());
    }
    return const _ImageFallback();
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kOrangeLight,
      child: const Center(
        child: Icon(Icons.fastfood_rounded, color: _kOrange, size: 40),
      ),
    );
  }
}

// ─── Empty Cart ───────────────────────────────────────────────────────────────

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _kOrangeLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_bag_outlined,
                size: 64, color: _kOrange),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _kTextDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add items to get started',
            style: TextStyle(color: _kTextMid),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final totalQty = state.cart.fold<int>(0, (s, l) => s + l.quantity);

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Summary row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item count
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$totalQty Selected Food',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: _kTextDark,
                    ),
                  ),
                  const Text(
                    'Items',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: _kTextDark,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Total
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Total Amount :',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _kTextDark,
                    ),
                  ),
                  Text(
                    'Rs ${state.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: _kTextDark,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Checkout button
          _CheckoutButton(
            enabled: state.cart.isNotEmpty,
            onTap: () {
              if (state.cart.isEmpty) {
                showToast(context, 'Your cart is empty');
                return;
              }
              HapticFeedback.mediumImpact();
              Navigator.pushNamed(context, CheckoutScreen.routeName);
            },
          ),
        ],
      ),
    );
  }
}

class _CheckoutButton extends StatefulWidget {
  const _CheckoutButton({required this.enabled, required this.onTap});
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_CheckoutButton> createState() => _CheckoutButtonState();
}

class _CheckoutButtonState extends State<_CheckoutButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    lowerBound: 0,
    upperBound: 1,
  );
  late final Animation<double> _scale =
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
      onTapDown: widget.enabled ? (_) => _c.forward() : null,
      onTapUp: widget.enabled
          ? (_) {
              _c.reverse();
              widget.onTap();
            }
          : null,
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            gradient: widget.enabled
                ? const LinearGradient(
                    colors: [Color(0xFFF26522), Color(0xFFE8401A)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: widget.enabled ? null : const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(999),
            boxShadow: widget.enabled
                ? [
                    BoxShadow(
                      color: _kOrange.withValues(alpha: 0.40),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              'Checkout',
              style: TextStyle(
                color: widget.enabled ? Colors.white : Colors.grey,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
