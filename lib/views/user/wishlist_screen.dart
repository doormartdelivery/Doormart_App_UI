import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/app_state.dart';
import '../../widgets/product_bottom_sheet.dart';
import '../../widgets/toast_widget.dart';
import 'cart_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  static const routeName = '/wishlist';

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool _fastDeliveryOnly = false;
  bool _ratingOnly = false;
  _WishlistSort _sort = _WishlistSort.relevance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EA),
      body: SafeArea(
        child: Stack(
          children: [
            Consumer<AppState>(
              builder: (context, state, _) {
                final favorites = _applyFilters(state.favorites);
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _HeroHeader(onBack: () => Navigator.pop(context)),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 14)),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 54,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          children: [
                            _FilterPill(
                              label: 'Filter',
                              icon: Icons.tune,
                              active: _fastDeliveryOnly || _ratingOnly,
                              onTap: () => _showFilterSheet(context),
                            ),
                            _FilterPill(
                              label: 'Sort by',
                              icon: Icons.keyboard_arrow_down,
                              active: _sort != _WishlistSort.relevance,
                              onTap: () => _showSortSheet(context),
                            ),
                            _FilterPill(
                              label: 'Fast Delivery',
                              active: _fastDeliveryOnly,
                              onTap: () => setState(() {
                                _fastDeliveryOnly = !_fastDeliveryOnly;
                              }),
                            ),
                            _FilterPill(
                              label: 'Ratings 4.0+',
                              active: _ratingOnly,
                              onTap: () => setState(() {
                                _ratingOnly = !_ratingOnly;
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 18)),
                    if (favorites.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: _EmptyFavoritesCard(),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                        sliver: SliverList.separated(
                          itemCount: favorites.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 18),
                          itemBuilder: (context, index) {
                            final product = favorites[index];
                            return _FavoriteCard(
                              product: product,
                              onTap: () => showProductBottomSheet(
                                context,
                                product,
                                onAddToCart: (quantity) async {
                                  final added = await context
                                      .read<AppState>()
                                      .addToCart(product, quantity: quantity);
                                  if (!context.mounted) return;
                                  showToast(
                                    context,
                                    added
                                        ? '${product.name} added to cart'
                                        : state.error ?? 'Please login first',
                                  );
                                },
                              ),
                              onRemove: () async {
                                await context
                                    .read<AppState>()
                                    .removeFavorite(product.id);
                                if (!context.mounted) return;
                                showToast(
                                  context,
                                  '${product.name} removed from favorites',
                                );
                              },
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: Consumer<AppState>(
                builder: (context, state, _) {
                  final count = state.favorites.length;
                  final total = state.favorites.fold<double>(
                    0,
                    (sum, item) => sum + item.price,
                  );
                  return _BottomBar(
                    count: count,
                    total: total,
                    onCheckout: count == 0
                        ? null
                        : () => Navigator.pushNamed(
                              context,
                              CartScreen.routeName,
                            ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ProductModel> _applyFilters(List<ProductModel> input) {
    var items = List<ProductModel>.from(input);

    if (_fastDeliveryOnly) {
      items = items.where((item) => item.stock >= 10).toList();
    }
    if (_ratingOnly) {
      items = items.where((item) => item.rating >= 4.0).toList();
    }

    switch (_sort) {
      case _WishlistSort.relevance:
        break;
      case _WishlistSort.priceLowHigh:
        items.sort((a, b) => a.price.compareTo(b.price));
        break;
      case _WishlistSort.priceHighLow:
        items.sort((a, b) => b.price.compareTo(a.price));
        break;
      case _WishlistSort.ratingHighLow:
        items.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case _WishlistSort.nameAZ:
        items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }

    return items;
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Fast Delivery only'),
                    subtitle: const Text('Show faster items first'),
                    value: _fastDeliveryOnly,
                    onChanged: (value) => setModalState(() {
                      _fastDeliveryOnly = value;
                    }),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Rating 4.0+'),
                    subtitle: const Text('Only top rated favorites'),
                    value: _ratingOnly,
                    onChanged: (value) => setModalState(() {
                      _ratingOnly = value;
                    }),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(sheetContext);
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SortTile(
                    label: 'Relevance',
                    selected: _sort == _WishlistSort.relevance,
                    onTap: () => setModalState(() => _sort = _WishlistSort.relevance),
                  ),
                  _SortTile(
                    label: 'Price: Low to High',
                    selected: _sort == _WishlistSort.priceLowHigh,
                    onTap: () => setModalState(() => _sort = _WishlistSort.priceLowHigh),
                  ),
                  _SortTile(
                    label: 'Price: High to Low',
                    selected: _sort == _WishlistSort.priceHighLow,
                    onTap: () => setModalState(() => _sort = _WishlistSort.priceHighLow),
                  ),
                  _SortTile(
                    label: 'Rating: High to Low',
                    selected: _sort == _WishlistSort.ratingHighLow,
                    onTap: () => setModalState(() => _sort = _WishlistSort.ratingHighLow),
                  ),
                  _SortTile(
                    label: 'Name: A to Z',
                    selected: _sort == _WishlistSort.nameAZ,
                    onTap: () => setModalState(() => _sort = _WishlistSort.nameAZ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(sheetContext);
                      },
                      child: const Text('Apply Sort'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

enum _WishlistSort { relevance, priceLowHigh, priceHighLow, ratingHighLow, nameAZ }

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 330,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFC55E), Color(0xFFFFA21A)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 10,
            left: 8,
            child: _AnimatedTap(
              onTap: onBack,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            top: 38,
            right: 12,
            child: _FloatingFood(imagePath: 'assets/images/products/dal1.png', size: 112),
          ),
          Positioned(
            top: 88,
            left: 86,
            child: _FloatingFood(imagePath: 'assets/images/products/milk1.png', size: 132),
          ),
          Positioned(
            top: 198,
            right: 16,
            child: _FloatingFood(imagePath: 'assets/images/products/dal.png', size: 120),
          ),
          const Positioned(
            left: 18,
            bottom: 68,
            child: Text(
              'We know\nyou love it!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.w900,
                height: 0.94,
              ),
            ),
          ),
          const Positioned(
            left: 20,
            bottom: 24,
            child: Text(
              'Browse your favourite products\n& feast like never before.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingFood extends StatelessWidget {
  const _FloatingFood({required this.imagePath, required this.size});

  final String imagePath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(child: Image.asset(imagePath, fit: BoxFit.cover)),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.onTap,
    this.icon,
    this.active = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: _AnimatedTap(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFBE9D0) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE3DED7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              if (icon != null) ...[
                const SizedBox(width: 6),
                Icon(icon, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.product,
    required this.onTap,
    required this.onRemove,
  });

  final ProductModel product;
  final VoidCallback onTap;
  final Future<void> Function() onRemove;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: SizedBox(
                      width: 118,
                      height: 128,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _Thumb(imageUrl: product.imageUrl),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Color(0x9A000000), Color(0x00000000)],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 10,
                            bottom: 8,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'ITEMS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  'AT Rs ${product.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E1C1A),
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: const [
                          Icon(Icons.star, size: 18, color: Color(0xFF0E9A57)),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '4.4 (3.6K+) · 30-35 mins',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2F2D2B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF66615B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vellore Fort · 1.7 km',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _AnimatedTap(
                          onTap: () => onRemove(),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7E9EE),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: Color(0xFFE84C67),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(imageUrl, fit: BoxFit.cover, gaplessPlayback: true);
    }
    if (imageUrl.startsWith('http')) {
      return Image.network(imageUrl, fit: BoxFit.cover);
    }
    return Container(
      color: const Color(0xFFF1F5F0),
      alignment: Alignment.center,
      child: const Icon(Icons.shopping_bag_outlined),
    );
  }
}

class _SortTile extends StatelessWidget {
  const _SortTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: selected ? const Color(0xFF1DAA61) : const Color(0xFF1E1C1A),
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle, color: Color(0xFF1DAA61))
          : const Icon(Icons.circle_outlined, color: Color(0xFFB7B0A6)),
    );
  }
}

class _EmptyFavoritesCard extends StatelessWidget {
  const _EmptyFavoritesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Icon(Icons.favorite_border, size: 44, color: Color(0xFFE3A56D)),
          SizedBox(height: 12),
          Text(
            'No favorite products yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6),
          Text(
            'Tap the heart on any product to save it here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6E665E)),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.count,
    required this.total,
    required this.onCheckout,
  });

  final int count;
  final double total;
  final VoidCallback? onCheckout;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: onCheckout == null,
      child: Opacity(
        opacity: onCheckout == null ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$count item${count == 1 ? '' : 's'} | Rs ${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF6B675F),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Favorites',
                      style: TextStyle(
                        fontSize: 21,
                        color: Color(0xFF1C8E50),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _AnimatedTap(
                onTap: () => onCheckout?.call(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DAA61),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Checkout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedTap extends StatefulWidget {
  const _AnimatedTap({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_AnimatedTap> createState() => _AnimatedTapState();
}

class _AnimatedTapState extends State<_AnimatedTap> {
  bool _pressed = false;

  Future<void> _tap() async {
    setState(() => _pressed = true);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    setState(() => _pressed = false);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _tap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
