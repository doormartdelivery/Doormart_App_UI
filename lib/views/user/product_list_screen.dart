import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/network_image_url.dart';
import '../../providers/app_state.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/toast_widget.dart';
import '../../widgets/product_bottom_sheet.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF4),
      body: GradientBackground(
        child: SafeArea(
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
                          _FilterPill(
                            label: _selectedCategory == 'All'
                                ? 'All Categories'
                                : _selectedCategory,
                            icon: Icons.category_outlined,
                            active: _selectedCategory != 'All',
                            onTap: () => _showFilterSheet(),
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
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      sliver: SliverList.separated(
                        itemCount: products.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 18),
                        itemBuilder: (context, index) {
                          final product = products[index];
                        return _ProductFeedCard(
                          product: product,
                          isFavorite: state.isFavorite(product),
                          onTap: () => showProductBottomSheet(
                            context,
                            product,
                            onAddToCart: (quantity) async {
                              final added = await state.addToCart(
                                product,
                                quantity: quantity,
                              );
                              if (!context.mounted) return;
                              showToast(
                                context,
                                added
                                    ? '${product.name} added to cart'
                                    : state.error ?? 'Please login first',
                              );
                            },
                          ),
                          onFavoriteToggle: () async {
                            await state.toggleFavorite(product);
                          },
                            onAddToCart: () async {
                              final added = await state.addToCart(product);
                              if (!context.mounted) return;
                              showToast(
                                context,
                                added
                                    ? '${product.name} added to cart'
                                    : state.error ?? 'Please login first',
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
          .where((item) =>
              item.category.toLowerCase() == _selectedCategory.toLowerCase())
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
        items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
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
                    children: categories.map((category) {
                      final selected = _selectedCategory == category.name;
                      return ChoiceChip(
                        label: Text(category.name),
                        selected: selected,
                        onSelected: (_) => setModalState(() {
                          _selectedCategory = category.name;
                        }),
                      );
                    }).toList(),
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
                    title: 'Relevance',
                    selected: _sort == _ProductListSort.relevance,
                    onTap: () => setModalState(
                      () => _sort = _ProductListSort.relevance,
                    ),
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
                    onTap: () => setModalState(
                      () => _sort = _ProductListSort.nameAZ,
                    ),
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

enum _ProductListSort { relevance, priceLowHigh, priceHighLow, ratingHighLow, nameAZ }

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
        _CircleIconButton(icon: Icons.arrow_back, onTap: onBack),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Product List',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
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
          color: selected ? const Color(0xFF0F9D58) : const Color(0xFF17211B),
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle, color: Color(0xFF0F9D58))
          : const Icon(Icons.circle_outlined, color: Color(0xFFB8C2B6)),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(22),
                  ),
                  child: SizedBox(
                    width: 120,
                    height: 180,
                    child: _ImageThumb(imageUrl: product.imageUrl),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _RatingChip(rating: product.rating.toStringAsFixed(1)),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.category} • ${_unitLabel(product.unit)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Fresh, handpicked and ready to add to your basket.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.2,
                        color: Colors.black.withValues(alpha: 0.58),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Rs ${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const Spacer(),
                        _BadgeButton(
                          active: isFavorite,
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isFavorite
                                ? const Color(0xFFE8541A)
                                : const Color(0xFFAAAAAA),
                          ),
                          onTap: onFavoriteToggle,
                        ),
                        const SizedBox(width: 6),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8541A),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE8541A).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: 230,
                        child: FilledButton.icon(
                          onPressed: onAddToCart,
                          icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                          label: const Text(
                            'Add to Cart',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
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
    );
  }
}

String _unitLabel(String value) {
  final unit = value.trim();
  if (unit.isEmpty) return '1 item';
  if (RegExp(r'^\d').hasMatch(unit)) return unit;
  return '1 $unit';
}

class _BadgeButton extends StatelessWidget {
  const _BadgeButton({
    required this.child,
    required this.onTap,
    required this.active,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE8541A).withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: child,
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

class _ImageThumb extends StatelessWidget {
  const _ImageThumb({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final normalized = NetworkImageUrl.normalize(imageUrl);
    if (normalized.startsWith('assets/')) {
      return Image.asset(normalized, fit: BoxFit.cover);
    }
    if (normalized.startsWith('http')) {
      return Image.network(normalized, fit: BoxFit.cover);
    }
    return Container(
      color: const Color(0xFFF1F1F1),
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported_outlined, color: Color(0xFF999999)),
    );
  }
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
            color: active ? Colors.white.withValues(alpha: 0.84) : Colors.white.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF16231C)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: Color(0xFF16231C),
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
    return Material(
      color: Colors.white.withValues(alpha: 0.72),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.arrow_back),
        ),
      ),
    );
  }
}
