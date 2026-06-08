import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../mascot/walking_mascot_widget.dart';
import '../../models/product_model.dart';
import '../../providers/app_state.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/product_bottom_sheet.dart';
import '../../widgets/product_card.dart';
import '../../widgets/toast_widget.dart';
import '../../features/customer/search/voice_search_widget.dart';
import '../admin/admin_dashboard_screen.dart';
import '../delivery/delivery_home_screen.dart';
import '../super_admin/super_admin_dashboard_screen.dart';
import 'cart_screen.dart';
import 'product_list_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  static const routeName = '/';

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  _EssentialsSort _sort = _EssentialsSort.relevance;
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF4),
      body: GradientBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _HomeHeader()),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              const SliverToBoxAdapter(child: _SearchAndDelivery()),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              const SliverToBoxAdapter(child: _OfferBanners()),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
              const SliverToBoxAdapter(
                child: _SectionTitle('Shop by category'),
              ),
              const SliverToBoxAdapter(child: _CategoryGrid()),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
              const SliverToBoxAdapter(
                child: _SectionTitle('Fresh picks today'),
              ),
              const SliverToBoxAdapter(child: _ProductRail()),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
              const SliverToBoxAdapter(
                child: _SectionTitle('Daily essentials'),
              ),
              SliverToBoxAdapter(
                child: _EssentialsFilters(
                  sort: _sort,
                  selectedCategory: _selectedCategory,
                  onFilterTap: _showFilterSheet,
                  onSortTap: _showSortSheet,
                  onCategorySelected: (value) =>
                      setState(() => _selectedCategory = value),
                ),
              ),
              SliverToBoxAdapter(
                child: _EssentialsGrid(
                  sort: _sort,
                  selectedCategory: _selectedCategory,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              const SliverToBoxAdapter(child: _OperationsEntry()),
              const SliverToBoxAdapter(child: WalkingMascotWidget()),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
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
                    label: 'Relevance',
                    selected: _sort == _EssentialsSort.relevance,
                    onTap: () => setModalState(
                      () => _sort = _EssentialsSort.relevance,
                    ),
                  ),
                  _SortTile(
                    label: 'Price: Low to High',
                    selected: _sort == _EssentialsSort.priceLowHigh,
                    onTap: () => setModalState(
                      () => _sort = _EssentialsSort.priceLowHigh,
                    ),
                  ),
                  _SortTile(
                    label: 'Price: High to Low',
                    selected: _sort == _EssentialsSort.priceHighLow,
                    onTap: () => setModalState(
                      () => _sort = _EssentialsSort.priceHighLow,
                    ),
                  ),
                  _SortTile(
                    label: 'Rating: High to Low',
                    selected: _sort == _EssentialsSort.ratingHighLow,
                    onTap: () => setModalState(
                      () => _sort = _EssentialsSort.ratingHighLow,
                    ),
                  ),
                  _SortTile(
                    label: 'Name: A to Z',
                    selected: _sort == _EssentialsSort.nameAZ,
                    onTap: () => setModalState(
                      () => _sort = _EssentialsSort.nameAZ,
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

class _HomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final addressText =
            state.selectedAddress?.fullAddress ?? 'Add your delivery address';
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE3E8DF)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF7EF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.timer,
                            color: Color(0xFF0F9D58),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Delivery in 10 minutes',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Color(0xFF667064),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            addressText,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF667064),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Profile',
                onPressed: () =>
                    Navigator.pushNamed(context, ProfileScreen.routeName),
                icon: const Icon(Icons.person),
              ),
            ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchAndDelivery extends StatefulWidget {
  const _SearchAndDelivery();

  @override
  State<_SearchAndDelivery> createState() => _SearchAndDeliveryState();
}

class _SearchAndDeliveryState extends State<_SearchAndDelivery> {
  late final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: VoiceSearchWidget(
        controller: _controller,
        readOnly: true,
        hintText: 'Search atta, milk, fruits...',
        onTap: () => Navigator.pushNamed(context, SearchScreen.routeName),
        onSearchChanged: (query) {
          if (query.trim().isEmpty) return;
          Navigator.pushNamed(
            context,
            SearchScreen.routeName,
            arguments: query.trim(),
          );
        },
      ),
    );
  }
}

class _OfferBanners extends StatefulWidget {
  const _OfferBanners();

  @override
  State<_OfferBanners> createState() => _OfferBannersState();
}

class _OfferBannersState extends State<_OfferBanners> {
  final PageController _controller = PageController(viewportFraction: 0.86);
  int _page = 0;
  Timer? _timer;

  static const _banners = [
    (
      'Fresh fruits',
      'Up to 30% off',
      'assets/images/banners/grocery_bag.png',
    ),
    (
      'Daily dairy',
      'Morning essentials',
      'assets/images/banners/coupon_basket.png',
    ),
    (
      'Fresh vegetables',
      'Farm to table',
      'assets/images/categories/vegetables.png',
    ),
    (
      'Kitchen staples',
      'Rice, dal and oil',
      'assets/images/categories/staples.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _next());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (!_controller.hasClients) return;
    final next = (_page + 1) % _banners.length;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 206,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            itemCount: _banners.length,
            onPageChanged: (value) => setState(() => _page = value),
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Padding(
                padding: EdgeInsets.only(left: index == 0 ? 16 : 6, right: 6),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _BannerImage(path: banner.$3, title: banner.$1),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF0F9D58).withValues(alpha: 0.10),
                                Colors.black.withValues(alpha: 0.18),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.topRight,
                            ),
                          ),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0x11000000), Color(0xAA000000)],
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.14),
                                  ),
                                ),
                                child: const Text(
                                  'Fresh picks',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                banner.$1,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -0.2,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                banner.$2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Shop now',
                                  style: TextStyle(
                                    color: Color(0xFF14532D),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: index == _page ? 18 : 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: index == _page
                    ? const Color(0xFF0F9D58)
                    : const Color(0xFFD3DDD0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

IconData _bannerIconFor(String title) {
  final lower = title.toLowerCase();
  if (lower.contains('fruit')) return Icons.apple;
  if (lower.contains('vegetable')) return Icons.eco;
  if (lower.contains('dairy')) return Icons.local_drink;
  return Icons.local_grocery_store;
}

class _BannerImage extends StatelessWidget {
  const _BannerImage({required this.path, required this.title});

  final String path;
  final String title;

  @override
  Widget build(BuildContext context) {
    final image = path.startsWith('http')
        ? Image.network(
            path,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _BannerFallback(title: title),
          )
        : Image.asset(
            path,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _BannerFallback(title: title),
          );
    return image;
  }
}

class _BannerFallback extends StatelessWidget {
  const _BannerFallback({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFDFF3E4), Color(0xFFB8E0C3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          _bannerIconFor(title),
          size: 92,
          color: const Color(0xFF0F9D58),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pushNamed(context, ProductListScreen.routeName),
            child: const Text('See all'),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final categories = state.categoryCatalog;
        if (categories.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('No categories available'),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 10,
            childAspectRatio: 0.84,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];
            final bgColor = _categoryTint(index);
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.pushNamed(
                context,
                ProductListScreen.routeName,
                arguments: category.name,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: bgColor.withValues(alpha: 0.8)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: _CategoryImage(imageUrl: category.imageUrl),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334035),
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

Color _categoryTint(int index) {
  final tints = [
    const Color(0xFFE7F7EC),
    const Color(0xFFFFF0D7),
    const Color(0xFFEAF1FF),
    const Color(0xFFFFEFEA),
    const Color(0xFFFFF8D8),
    const Color(0xFFEFF3F0),
    const Color(0xFFF2EAFE),
    const Color(0xFFFFEAF3),
  ];
  return tints[index % tints.length];
}

class _CategoryImage extends StatelessWidget {
  const _CategoryImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(imageUrl, fit: BoxFit.contain);
    }
    if (imageUrl.startsWith('http')) {
      return Image.network(imageUrl, fit: BoxFit.contain);
    }
    return const Icon(Icons.category, size: 34, color: Color(0xFF0F9D58));
  }
}

class _ProductRail extends StatelessWidget {
  const _ProductRail();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final products = state.products.take(6).toList();
        return SizedBox(
          height: 320,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) => SizedBox(
              width: 168,
              child: ProductCard(
                product: products[index],
                isFavorite: state.isFavorite(products[index]),
                onFavoriteToggle: () async {
                  await state.toggleFavorite(products[index]);
                },
                onTap: () => showProductBottomSheet(
                  context,
                  products[index],
                  onAddToCart: (quantity) async {
                    final added = await state.addToCart(
                      products[index],
                      quantity: quantity,
                    );
                    if (!context.mounted) return;
                    showToast(
                      context,
                      added
                          ? '${products[index].name} added to cart'
                          : state.error ?? 'Please login first',
                    );
                  },
                ),
                onAdd: () async {
                  final added = await state.addToCart(products[index]);
                  if (!context.mounted) return;
                  showToast(
                    context,
                    added
                        ? '${products[index].name} added to cart'
                        : state.error ?? 'Please login first',
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _EssentialsSort { relevance, priceLowHigh, priceHighLow, ratingHighLow, nameAZ }

class _EssentialsGrid extends StatelessWidget {
  const _EssentialsGrid({
    required this.sort,
    required this.selectedCategory,
  });

  final _EssentialsSort sort;
  final String selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        var products = List<ProductModel>.from(state.products);
        if (selectedCategory != 'All') {
          products = products
              .where(
                (item) =>
                    item.category.toLowerCase() == selectedCategory.toLowerCase(),
              )
              .toList();
        }
        switch (sort) {
          case _EssentialsSort.relevance:
            break;
          case _EssentialsSort.priceLowHigh:
            products.sort((a, b) => a.price.compareTo(b.price));
            break;
          case _EssentialsSort.priceHighLow:
            products.sort((a, b) => b.price.compareTo(a.price));
            break;
          case _EssentialsSort.ratingHighLow:
            products.sort((a, b) => b.rating.compareTo(a.rating));
            break;
          case _EssentialsSort.nameAZ:
            products.sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
            break;
        }
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (context, index) => ProductCard(
            product: products[index],
            isFavorite: state.isFavorite(products[index]),
            onFavoriteToggle: () async {
              await state.toggleFavorite(products[index]);
            },
            onTap: () => showProductBottomSheet(
              context,
              products[index],
              onAddToCart: (quantity) async {
                final added = await state.addToCart(
                  products[index],
                  quantity: quantity,
                );
                if (!context.mounted) return;
                showToast(
                  context,
                  added
                      ? '${products[index].name} added to cart'
                      : state.error ?? 'Please login first',
                );
              },
            ),
            onAdd: () async {
              final added = await state.addToCart(products[index]);
              if (!context.mounted) return;
              showToast(
                context,
                added
                    ? '${products[index].name} added to cart'
                    : state.error ?? 'Please login first',
              );
            },
          ),
        );
      },
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
          color: selected ? const Color(0xFF0F9D58) : const Color(0xFF1E1C1A),
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle, color: Color(0xFF0F9D58))
          : const Icon(Icons.circle_outlined, color: Color(0xFFB7B0A6)),
    );
  }
}

class _EssentialsFilters extends StatelessWidget {
  const _EssentialsFilters({
    required this.sort,
    required this.onFilterTap,
    required this.onSortTap,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final _EssentialsSort sort;
  final VoidCallback onFilterTap;
  final VoidCallback onSortTap;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final chips = [
      _FeedChipData('Filter', Icons.tune, selectedCategory != 'All'),
      _FeedChipData('Sort by', Icons.keyboard_arrow_down, sort != _EssentialsSort.relevance),
      _FeedChipData(
        selectedCategory == 'All' ? 'All Categories' : selectedCategory,
        Icons.category_outlined,
        selectedCategory != 'All',
      ),
    ];

    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final chip = chips[index];
          return _FeedChip(
            label: chip.label,
            icon: chip.icon,
            active: chip.active,
            onTap: () {
            switch (chip.label) {
              case 'Filter':
                onFilterTap();
                break;
              case 'Sort by':
                onSortTap();
                break;
              default:
                onFilterTap();
                break;
            }
          },
          );
        },
      ),
    );
  }
}

class _FeedChipData {
  const _FeedChipData(this.label, this.icon, this.active);

  final String label;
  final IconData icon;
  final bool active;
}

class _FeedChip extends StatelessWidget {
  const _FeedChip({
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 92),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            Icon(icon, size: 17, color: const Color(0xFF16231C)),
            const SizedBox(width: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: Color(0xFF16231C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OperationsEntry extends StatelessWidget {
  const _OperationsEntry();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE3E8DF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(top: 12),
          title: const Text(
            'Team access',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: const Text('Delivery, admin and super admin tools'),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    DeliveryHomeScreen.routeName,
                  ),
                  icon: const Icon(Icons.delivery_dining),
                  label: const Text('Delivery'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AdminDashboardScreen.routeName,
                  ),
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Admin'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    SuperAdminDashboardScreen.routeName,
                  ),
                  icon: const Icon(Icons.insights),
                  label: const Text('Super admin'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
