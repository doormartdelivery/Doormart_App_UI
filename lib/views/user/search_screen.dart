import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';

import '../../core/utils/network_image_url.dart';
import '../../features/customer/search/voice_search_widget.dart';
import '../../providers/app_state.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/product_bottom_sheet.dart';
import '../../widgets/toast_widget.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  static const routeName = '/search';

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _searchController;
  bool _initialized = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final initialQuery = ModalRoute.of(context)?.settings.arguments as String?;
    if (initialQuery != null && initialQuery.trim().isNotEmpty) {
      _searchController.text = initialQuery.trim();
      _query = initialQuery.trim();
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
      backgroundColor: const Color(0xFFF7FAF4),
      body: GradientBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: _SearchHeader(
                    controller: _searchController,
                    onChanged: (query) {
                      setState(() => _query = query.trim());
                    },
                    onSubmitted: (query) {
                      setState(() => _query = query.trim());
                    },
                    onClear: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    onBack: () => Navigator.pop(context),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverToBoxAdapter(
                child: Consumer<AppState>(
                  builder: (context, state, _) {
                    final products = _filteredProducts(state.products);
                    final count = products.length;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _ResultPill(label: 'Results', value: count),
                          const SizedBox(width: 8),
                          _ResultPill(label: 'Category', value: 'All'),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              Consumer<AppState>(
                builder: (context, state, _) {
                  final products = _filteredProducts(state.products);
                  if (state.loading && products.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  if (state.error != null && products.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(state.error!),
                      ),
                    );
                  }
                  if (_query.isNotEmpty && products.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: _EmptyState(),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
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
                                    '[perf][favorite:search][ui] ${tapSw.elapsedMilliseconds}ms',
                                  );
                                });
                              },
                              onTap: () => showProductBottomSheet(
                                context,
                                product,
                                onAddToCart: (quantity) async {
                                  final tapSw = Stopwatch()..start();
                                  final added = await context
                                      .read<AppState>()
                                      .addToCart(product, quantity: quantity);
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
                                      '[perf][cart:search][ui] ${tapSw.elapsedMilliseconds}ms',
                                    );
                                  });
                                },
                              ),
                              onAdd: () async {
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
                                    '[perf][cart:search][ui] ${tapSw.elapsedMilliseconds}ms',
                                  );
                                });
                              },
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
              SliverToBoxAdapter(child: SizedBox(height: bottomInset)),
            ],
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
    final q = _query.toLowerCase().trim();
    if (q.isNotEmpty) {
      items = items.where((item) {
        final name = (item.name as String).toLowerCase();
        final category = (item.category as String).toLowerCase();
        final description = (item.description as String? ?? '').toLowerCase();
        return name.contains(q) ||
            category.contains(q) ||
            description.contains(q);
      }).toList();
    }
    return items;
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onBack,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3E8DF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Search products',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          VoiceSearchWidget(
            controller: controller,
            autofocus: true,
            hintText: 'Search groceries in English',
            onSearchChanged: onChanged,
            onSubmitted: onSubmitted,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text('Clear search'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultPill extends StatelessWidget {
  const _ResultPill({required this.label, required this.value});

  final String label;
  final Object value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE3E8DF)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          '$label: $value',
          style: const TextStyle(fontWeight: FontWeight.w700),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3E8DF)),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 42, color: Color(0xFF0F9D58)),
          SizedBox(height: 10),
          Text(
            'No matching products found',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ProductFeedCard extends StatelessWidget {
  const _ProductFeedCard({
    required this.product,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onAdd,
    required this.onTap,
  });

  final dynamic product;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onAdd;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Stack(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(22),
                ),
                child: SizedBox(
                  width: 120,
                  height: 158,
                  child: _ImageThumb(imageUrl: product.imageUrl),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 14, 44, 14),
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
                        product.category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Rs ${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8541A),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFE8541A,
                              ).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: 235,
                          child: FilledButton.icon(
                            onPressed: onAdd,
                            icon: const Icon(
                              Icons.shopping_cart_outlined,
                              size: 16,
                            ),
                            label: const Text(
                              'Add to Cart',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
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
          Positioned(
            top: 12,
            right: 12,
            child: _BadgeButton(
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
    return const ColoredBox(
      color: Color(0xFFF1F5F9),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _BadgeButton extends StatelessWidget {
  const _BadgeButton({
    required this.active,
    required this.child,
    required this.onTap,
  });

  final bool active;
  final Widget child;
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
              color: const Color(0xFFE8541A).withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          active ? Icons.favorite : Icons.favorite_border,
          size: 18,
          color: active ? const Color(0xFFE8541A) : const Color(0xFFAAAAAA),
        ),
      ),
    );
  }
}

class _TextChip extends StatelessWidget {
  const _TextChip(this.label, {required this.subText});

  final String label;
  final String subText;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
            Text(
              subText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
