import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/network_image_url.dart';
import '../../models/product_model.dart';
import '../../providers/app_state.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/product_bottom_sheet.dart';
import '../../widgets/toast_widget.dart';

const _kBg = Color(0xFFF6F6F6);
const _kCard = Colors.white;
const _kTextDark = Color(0xFF1A1A1A);

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  static const routeName = '/products';

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late final TextEditingController _searchController;
  String _query = '';
  String _selectedCategory = 'All';
  _ProductListSort _sort = _ProductListSort.relevance;
  bool _categoryInitialized = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_categoryInitialized) return;
    _categoryInitialized = true;
    final category = ModalRoute.of(context)?.settings.arguments as String?;
    if (category != null && category.isNotEmpty && category != 'All') {
      _selectedCategory = category;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (context, state, _) {
            final products = _filteredProducts(state.products);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _Header(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() => _query = value.trim());
                      },
                      onBack: () => Navigator.pop(context),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
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
                          active: _selectedCategory != 'All',
                          onTap: () => _showFilterSheet(),
                        ),
                        _FilterPill(
                          label: 'Sort by',
                          icon: Icons.keyboard_arrow_down,
                          active: _sort != _ProductListSort.relevance,
                          onTap: () => _showSortSheet(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                if (state.loading && products.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (state.error != null && products.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(state.error!),
                    ),
                  )
                else if (products.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: _EmptyState(),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 120 + bottomInset),
                    sliver: SliverList.separated(
                      itemCount: products.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 18),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return Selector<AppState, bool>(
                          selector: (_, appState) =>
                              appState.isFavorite(product),
                          builder: (context, isFavorite, _) {
                            return _ProductFeedCard(
                              product: product,
                              isFavorite: isFavorite,
                              onTap: () => showProductBottomSheet(
                                context,
                                product,
                                onAddToCart: (quantity, variant) async {
                                  final added = await context
                                      .read<AppState>()
                                      .addToCart(
                                        product,
                                        quantity: quantity,
                                        unit: variant.unit,
                                        price: variant.price,
                                        discountCost: variant.discountCost,
                                        stock: variant.stock,
                                      );
                                  if (!context.mounted) return;
                                  showToast(
                                    context,
                                    added
                                        ? '${product.name} added to cart'
                                        : context.read<AppState>().error ??
                                              'Please login first',
                                  );
                                },
                              ),
                              onFavoriteToggle: () async {
                                final tapSw = Stopwatch()..start();
                                try {
                                  await context.read<AppState>().toggleFavorite(
                                    product,
                                  );
                                } catch (_) {}
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  debugPrint(
                                    '[perf][favorite:product-list][ui] ${tapSw.elapsedMilliseconds}ms',
                                  );
                                });
                              },
                              onAddToCart: () async {
                                final tapSw = Stopwatch()..start();
                                final added = await context
                                    .read<AppState>()
                                    .addToCart(product);
                                if (!context.mounted) return;
                                showToast(
                                  context,
                                  added
                                      ? '${product.name} added to cart'
                                      : context.read<AppState>().error ??
                                            'Please login first',
                                );
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  debugPrint(
                                    '[perf][cart:product-list][ui] ${tapSw.elapsedMilliseconds}ms',
                                  );
                                });
                              },
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
      ),
      bottomNavigationBar: BottomNavBar(
        index: 0,
        onTap: (index) => BottomNavBar.navigate(context, index),
      ),
    );
  }

  List<dynamic> _filteredProducts(List<dynamic> input) {
    var items = List<dynamic>.from(input);

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      items = items.where((item) {
        final name = (item.name as String).toLowerCase();
        final category = (item.category as String).toLowerCase();
        return name.contains(q) || category.contains(q);
      }).toList();
    }

    if (_selectedCategory != 'All') {
      items = items
          .where(
            (item) =>
                item.category.toLowerCase() == _selectedCategory.toLowerCase(),
          )
          .toList();
    }

    switch (_sort) {
      case _ProductListSort.relevance:
        break;
      case _ProductListSort.priceLowHigh:
        items.sort((a, b) => a.price.compareTo(b.price));
        break;
      case _ProductListSort.priceHighLow:
        items.sort((a, b) => b.price.compareTo(a.price));
        break;
      case _ProductListSort.ratingHighLow:
        items.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case _ProductListSort.nameAZ:
        items.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
    }

    return items;
  }

  void _showFilterSheet() {
    final categories = context.read<AppState>().categoryCatalog;
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Choose category',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('All'),
                            if (_selectedCategory == 'All') ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: Color(0xFFE8541A),
                              ),
                            ],
                          ],
                        ),
                        selected: _selectedCategory == 'All',
                        selectedColor: const Color(0xFFFFF0EB),
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _selectedCategory == 'All'
                              ? const Color(0xFFE8541A)
                              : const Color(0xFF17211B),
                        ),
                        side: BorderSide(
                          color: _selectedCategory == 'All'
                              ? const Color(0xFFE8541A)
                              : const Color(0xFFD9DED8),
                        ),
                        onSelected: (_) => setModalState(() {
                          _selectedCategory = 'All';
                        }),
                      ),
                      ...categories.map((category) {
                        final selected = _selectedCategory == category.name;
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(category.name),
                              if (selected) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: Color(0xFFE8541A),
                                ),
                              ],
                            ],
                          ),
                          selected: selected,
                          selectedColor: const Color(0xFFFFF0EB),
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: selected
                                ? const Color(0xFFE8541A)
                                : const Color(0xFF17211B),
                          ),
                          side: BorderSide(
                            color: selected
                                ? const Color(0xFFE8541A)
                                : const Color(0xFFD9DED8),
                          ),
                          onSelected: (_) => setModalState(() {
                            _selectedCategory = category.name;
                          }),
                        );
                      }),
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
            );
          },
        );
      },
    );
  }

  void _showSortSheet() {
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
                    title: 'All',
                    selected: _sort == _ProductListSort.relevance,
                    onTap: () =>
                        setModalState(() => _sort = _ProductListSort.relevance),
                  ),
                  _SortTile(
                    title: 'Relevance',
                    selected: _sort == _ProductListSort.relevance,
                    onTap: () =>
                        setModalState(() => _sort = _ProductListSort.relevance),
                  ),
                  _SortTile(
                    title: 'Price: Low to High',
                    selected: _sort == _ProductListSort.priceLowHigh,
                    onTap: () => setModalState(
                      () => _sort = _ProductListSort.priceLowHigh,
                    ),
                  ),
                  _SortTile(
                    title: 'Price: High to Low',
                    selected: _sort == _ProductListSort.priceHighLow,
                    onTap: () => setModalState(
                      () => _sort = _ProductListSort.priceHighLow,
                    ),
                  ),
                  _SortTile(
                    title: 'Rating: High to Low',
                    selected: _sort == _ProductListSort.ratingHighLow,
                    onTap: () => setModalState(
                      () => _sort = _ProductListSort.ratingHighLow,
                    ),
                  ),
                  _SortTile(
                    title: 'Name: A to Z',
                    selected: _sort == _ProductListSort.nameAZ,
                    onTap: () =>
                        setModalState(() => _sort = _ProductListSort.nameAZ),
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
            );
          },
        );
      },
    );
  }
}

enum _ProductListSort {
  relevance,
  priceLowHigh,
  priceHighLow,
  ratingHighLow,
  nameAZ,
}

class _Header extends StatelessWidget {
  const _Header({
    required this.controller,
    required this.onChanged,
    required this.onBack,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(icon: Icons.arrow_back_rounded, onTap: onBack),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Product List',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: _kTextDark,
            ),
          ),
        ),
        const SizedBox(width: 44),
      ],
    );
  }
}

class _SortTile extends StatelessWidget {
  const _SortTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: selected ? const Color(0xFFE8541A) : const Color(0xFF17211B),
        ),
      ),
      trailing: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? const Color(0xFFFFF0EB) : Colors.transparent,
          border: Border.all(
            color: selected ? const Color(0xFFE8541A) : const Color(0xFFB8C2B6),
            width: 1.4,
          ),
        ),
        child: selected
            ? const Icon(
                Icons.check_rounded,
                size: 15,
                color: Color(0xFFE8541A),
              )
            : null,
      ),
    );
  }
}

class _ProductFeedCard extends StatelessWidget {
  const _ProductFeedCard({
    required this.product,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onAddToCart,
  });

  final dynamic product;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final Future<void> Function() onAddToCart;

  @override
  Widget build(BuildContext context) {
    final storeLabel = _storeLabel(product);
    final accent = _categoryAccent((product.category as String?) ?? '');
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.20),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: Colors.white.withValues(alpha: 0.72),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 210,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _GlassImage(product: product, accent: accent),
                            Positioned(
                              top: 14,
                              left: 14,
                              child: _RatingChip(
                                rating: product.rating.toStringAsFixed(1),
                              ),
                            ),
                            Positioned(
                              top: 14,
                              right: 14,
                              child: _HeartButton(
                                isFavorite: isFavorite,
                                onTap: onFavoriteToggle,
                              ),
                            ),
                            Positioned(
                              left: 14,
                              right: 14,
                              bottom: 14,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (storeLabel.isNotEmpty) ...[
                                    _ChipLabel(
                                      icon: Icons.storefront_rounded,
                                      label: storeLabel,
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  _ChipLabel(
                                    icon: Icons.local_fire_department_rounded,
                                    label: _unitLabel(product.unit),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF121826),
                                height: 1.12,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              product.category,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Fresh, handpicked and ready to add to your basket.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.35,
                                color: Colors.black.withValues(alpha: 0.60),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Rs ${product.price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Tap to view more packs',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black.withValues(
                                          alpha: 0.45,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF7A34),
                                        Color(0xFFE8541A),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFE8541A,
                                        ).withValues(alpha: 0.28),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: FilledButton.icon(
                                    onPressed: onAddToCart,
                                    icon: const Icon(
                                      Icons.shopping_cart_outlined,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Add',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 14,
            child: _GlassEdgeGlow(accent: accent),
          ),
        ],
      ),
    );
  }
}

class _GlassEdgeGlow extends StatelessWidget {
  const _GlassEdgeGlow({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            accent.withValues(alpha: 0.22),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _GlassImage extends StatelessWidget {
  const _GlassImage({required this.product, required this.accent});

  final dynamic product;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final normalized = NetworkImageUrl.normalize(product.imageUrl);
    final child = normalized.startsWith('assets/')
        ? Image.asset(normalized, fit: BoxFit.cover)
        : normalized.startsWith('http')
        ? Image.network(
            normalized,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _funnyMissingImageFallback(
              context,
              product,
            ),
          )
        : _funnyMissingImageFallback(context, product);

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.05),
                Colors.black.withValues(alpha: 0.28),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Premium selection',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _unitLabel(String value) {
  final unit = value.trim();
  if (unit.isEmpty) return '1 item';
  if (RegExp(r'^\d').hasMatch(unit)) return unit;
  return '1 $unit';
}

String _storeLabel(ProductModel product) {
  final name = product.supplierName.trim();
  final city = product.supplierCity.trim();
  if (name.isEmpty) return '';
  if (city.isEmpty) return name;
  return '$name · $city';
}

class _HeartButton extends StatelessWidget {
  const _HeartButton({required this.isFavorite, required this.onTap});

  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE8541A).withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          size: 18,
          color: isFavorite ? const Color(0xFFE8541A) : const Color(0xFFAAAAAA),
        ),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({required this.rating});

  final String rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFD54F)),
          const SizedBox(width: 3),
          Text(
            rating,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _funnyMissingImageFallback(BuildContext context, dynamic product) {
  final accent = _categoryAccent((product.category as String?) ?? '');
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withValues(alpha: 0.16),
          const Color(0xFFFFF7ED),
          Colors.white,
        ],
      ),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 16,
          right: 16,
          child: Transform.rotate(
            angle: 0.12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: accent.withValues(alpha: 0.28)),
              ),
              child: const Text(
                'oops',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7C2D12),
                ),
              ),
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(Icons.hide_image_outlined, size: 42, color: accent),
              ),
              const SizedBox(height: 10),
              Text(
                'Image took a tea break',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF7C2D12).withValues(alpha: 0.92),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Still tasty, just camera shy.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Color _categoryAccent(String category) {
  return switch (category.toLowerCase()) {
    'vegetables' => const Color(0xFF16A34A),
    'fruits' => const Color(0xFFEA580C),
    'dairy' => const Color(0xFF2563EB),
    'staples' => const Color(0xFFB45309),
    'snacks' => const Color(0xFFDB2777),
    'beverages' => const Color(0xFF0891B2),
    _ => const Color(0xFFE8541A),
  };
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

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
              Icon(icon, size: 18, color: const Color(0xFFE8541A)),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: const Column(
        children: [
          Icon(Icons.shopping_bag_outlined, size: 42, color: Color(0xFF0F9D58)),
          SizedBox(height: 10),
          Text(
            'No products found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6),
          Text(
            'Try changing the search or filters.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
        child: const Icon(
          Icons.chevron_left_rounded,
          size: 26,
          color: _kTextDark,
        ),
      ),
    );
  }
}
