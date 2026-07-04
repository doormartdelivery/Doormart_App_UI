import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/network_image_url.dart';
import '../../models/product_model.dart';
import '../../providers/app_state.dart';
import '../../widgets/product_bottom_sheet.dart';
import '../../widgets/toast_widget.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'cart_screen.dart';
import 'search_screen.dart';
import 'user_home_screen.dart';

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
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (context, state, _) {
            final favorites = _applyFilters(state.favorites);
            return Column(
              children: [
                _TopBar(
                  cartCount: state.cartCount,
                  onBack: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        UserHomeScreen.routeName,
                        (route) => false,
                      );
                    }
                  },
                  onCart: () =>
                      Navigator.pushNamed(context, CartScreen.routeName),
                  onSearch: () =>
                      Navigator.pushNamed(context, SearchScreen.routeName),
                ),
                // Filter pills row
                SizedBox(
                  height: 52,
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
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: favorites.isEmpty
                      ? const _EmptyFavoritesCard()
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(16, 4, 16, 24 + bottomInset),
                          itemCount: favorites.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
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
                              onToggleFavorite: () async {
                                await context.read<AppState>().removeFavorite(
                                  product.id,
                                );
                                if (!context.mounted) return;
                                showToast(
                                  context,
                                  '${product.name} removed from favorites',
                                );
                              },
                              isFavorited: true,
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        index: 3,
        onTap: (index) => BottomNavBar.navigate(context, index),
      ),
    );
  }

  List<ProductModel> _applyFilters(List<ProductModel> input) {
    var items = List<ProductModel>.from(input);
    if (_fastDeliveryOnly) items = items.where((e) => e.stock >= 10).toList();
    if (_ratingOnly) items = items.where((e) => e.rating >= 4.0).toList();
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
        items.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
    }
    return items;
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose filter',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E1C1A),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ChoiceChip(
                    label: const Text('Fast Delivery'),
                    selected: _fastDeliveryOnly,
                    onSelected: (_) => setModalState(
                      () => _fastDeliveryOnly = !_fastDeliveryOnly,
                    ),
                    selectedColor: const Color(0xFFFFF0EB),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: _fastDeliveryOnly
                          ? const Color(0xFFE8541A)
                          : const Color(0xFF4E4A47),
                      fontWeight: FontWeight.w700,
                    ),
                    side: BorderSide(
                      color: _fastDeliveryOnly
                          ? const Color(0xFFE8541A)
                          : const Color(0xFFE6D7CE),
                    ),
                    checkmarkColor: const Color(0xFFE8541A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  ChoiceChip(
                    label: const Text('Ratings 4.0+'),
                    selected: _ratingOnly,
                    onSelected: (_) => setModalState(
                      () => _ratingOnly = !_ratingOnly,
                    ),
                    selectedColor: const Color(0xFFFFF0EB),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: _ratingOnly
                          ? const Color(0xFFE8541A)
                          : const Color(0xFF4E4A47),
                      fontWeight: FontWeight.w700,
                    ),
                    side: BorderSide(
                      color: _ratingOnly
                          ? const Color(0xFFE8541A)
                          : const Color(0xFFE6D7CE),
                    ),
                    checkmarkColor: const Color(0xFFE8541A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE8541A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(sheetContext);
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sort by',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E1C1A),
                ),
              ),
              const SizedBox(height: 12),
              _SortTile(
                label: 'Relevance',
                selected: _sort == _WishlistSort.relevance,
                onTap: () =>
                    setModalState(() => _sort = _WishlistSort.relevance),
              ),
              _SortTile(
                label: 'Price: Low to High',
                selected: _sort == _WishlistSort.priceLowHigh,
                onTap: () =>
                    setModalState(() => _sort = _WishlistSort.priceLowHigh),
              ),
              _SortTile(
                label: 'Price: High to Low',
                selected: _sort == _WishlistSort.priceHighLow,
                onTap: () =>
                    setModalState(() => _sort = _WishlistSort.priceHighLow),
              ),
              _SortTile(
                label: 'Rating: High to Low',
                selected: _sort == _WishlistSort.ratingHighLow,
                onTap: () =>
                    setModalState(() => _sort = _WishlistSort.ratingHighLow),
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
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE8541A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(sheetContext);
                  },
                  child: const Text('Apply Sort'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _WishlistSort {
  relevance,
  priceLowHigh,
  priceHighLow,
  ratingHighLow,
  nameAZ,
}

// ─── Top Bar ────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.cartCount,
    required this.onBack,
    required this.onCart,
    required this.onSearch,
  });

  final int cartCount;
  final VoidCallback onBack;
  final VoidCallback onCart;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 8),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chevron_left,
                size: 26,
                color: Color(0xFF1E1C1A),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Favourites',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E1C1A),
              ),
            ),
          ),
          // Search icon
          GestureDetector(
            onTap: onSearch,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.search, size: 26, color: Color(0xFF1E1C1A)),
            ),
          ),
          const SizedBox(width: 4),
          // Cart icon with badge
          GestureDetector(
            onTap: onCart,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE8541A),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    size: 22,
                    color: Color(0xFFE8541A),
                  ),
                ),
                if (cartCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8541A),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$cartCount',
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
          ),
        ],
      ),
    );
  }
}

// ─── Favorite Card ───────────────────────────────────────────────────────────

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.product,
    required this.onTap,
    required this.onToggleFavorite,
    required this.isFavorited,
  });

  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final bool isFavorited;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  child: _Thumb(imageUrl: product.imageUrl),
                ),
                // Right content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 44, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E1C1A),
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFAAAAAA),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Fresh, quality-picked product ready to add to your cart.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF666666),
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Rating + time row
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: Color(0xFFFFC107),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E1C1A),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.alarm,
                              size: 16,
                              color: Color(0xFFE8541A),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '20-25 Min',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF555555),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Orange price pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8541A),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'Rs ${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: onToggleFavorite,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE8541A).withOpacity(0.22),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isFavorited ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                    color: isFavorited
                        ? const Color(0xFFE8541A)
                        : const Color(0xFFAAAAAA),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Thumb ───────────────────────────────────────────────────────────────────

class _Thumb extends StatelessWidget {
  const _Thumb({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    const width = 130.0;
    const height = 176.0;
    final normalized = NetworkImageUrl.normalize(imageUrl);

    if (normalized.startsWith('assets/')) {
      return Image.asset(
        normalized,
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    }
    if (normalized.startsWith('http')) {
      return Image.network(
        normalized,
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    }
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF1F1F1),
      child: const Icon(
        Icons.image_outlined,
        color: Color(0xFFCCCCCC),
        size: 32,
      ),
    );
  }
}

// ─── Filter Pill ─────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: active
                  ? const [Color(0xFFFFF0EB), Color(0xFFFFE3D3)]
                  : const [Colors.white, Color(0xFFFFF7F2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? const Color(0xFFE8541A) : const Color(0xFFF1CDBD),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFFE8541A,
                ).withValues(alpha: active ? 0.28 : 0.16),
                blurRadius: active ? 18 : 14,
                spreadRadius: active ? 0.6 : 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon!, size: 18, color: const Color(0xFFE8541A)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: Color(0xFFE8541A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyFavoritesCard extends StatelessWidget {
  const _EmptyFavoritesCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0EA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border,
              size: 38,
              color: Color(0xFFE8541A),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No favourites yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E1C1A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the heart on any product\nto save it here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF999999),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sort Tile ────────────────────────────────────────────────────────────────

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
          color: selected ? const Color(0xFFE8541A) : const Color(0xFF1E1C1A),
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle, color: Color(0xFFE8541A))
          : const Icon(Icons.circle_outlined, color: Color(0xFFB7B0A6)),
    );
  }
}
