import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../mascot/walking_mascot_widget.dart';
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

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  static const routeName = '/';

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
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickySearchHeaderDelegate(
                  child: const _SearchAndDelivery(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 0)),
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
              const SliverToBoxAdapter(child: _EssentialsGrid()),
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
}

class _HomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final addressText =
            state.selectedAddress?.fullAddress ?? 'Add your delivery address';
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer, color: Color(0xFF0F9D58)),
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
                          Icons.location_on,
                          size: 18,
                          color: Color(0xFF667064),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            addressText,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF667064)),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, size: 18),
                      ],
                    ),
                  ],
                ),
              ),
              Badge(
                isLabelVisible: state.cartCount > 0,
                label: Text('${state.cartCount}'),
                child: IconButton.filledTonal(
                  tooltip: 'Cart',
                  onPressed: () =>
                      Navigator.pushNamed(context, CartScreen.routeName),
                  icon: const Icon(Icons.shopping_cart),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SearchAndDelivery extends StatelessWidget {
  const _SearchAndDelivery();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: VoiceSearchWidget(
        controller: TextEditingController(),
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

class _StickySearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StickySearchHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 120;

  @override
  double get maxExtent => 126;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFFF7FAF4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickySearchHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
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
      'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=1200&q=80',
    ),
    (
      'Daily dairy',
      'Morning essentials',
      'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?auto=format&fit=crop&w=1200&q=80',
    ),
    (
      'Fresh vegetables',
      'Farm to table',
      'https://ts4.mm.bing.net/th?id=OIP.f_11dVu0mmQ8AzHvruohJQHaE8&pid=15.1&o=7&rm=3', // replace with one of the above Unsplash links,
    ),
    (
      'Kitchen staples',
      'Rice, dal and oil',
      'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=1200&q=80',
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
          height: 190,
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
                    borderRadius: BorderRadius.circular(24),
                    image: DecorationImage(
                      image: NetworkImage(banner.$3),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xCC000000), Color(0x22000000)],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
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
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
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
                        const Text(
                          'Shop now',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
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
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
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
    final categories = [
      (
        'Vegetables',
        'assets/images/categories/vegetables.png',
        const Color(0xFFE7F7EC),
      ),
      (
        'Fruits',
        'assets/images/categories/fruits.png',
        const Color(0xFFFFF0D7),
      ),
      ('Dairy', 'assets/images/categories/dairy.png', const Color(0xFFEAF1FF)),
      (
        'Staples',
        'assets/images/categories/staples.png',
        const Color(0xFFFFEFEA),
      ),
      (
        'Snacks',
        'assets/images/categories/snacks.png',
        const Color(0xFFFFF8D8),
      ),
      (
        'Cleaning',
        'assets/images/categories/cleaning.png',
        const Color(0xFFEFF3F0),
      ),
      (
        'Personal',
        'assets/images/categories/personal.png',
        const Color(0xFFF2EAFE),
      ),
      (
        'Baby care',
        'assets/images/categories/baby_care.png',
        const Color(0xFFFFEAF3),
      ),
    ];
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () =>
              Navigator.pushNamed(context, ProductListScreen.routeName),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: category.$3,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(9),
                      child: Image.asset(category.$2, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                category.$1,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
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
          height: 260,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) => SizedBox(
              width: 168,
              child: ProductCard(
                product: products[index],
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

class _EssentialsGrid extends StatelessWidget {
  const _EssentialsGrid();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final products = state.products.toList();
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.76,
          ),
          itemBuilder: (context, index) => ProductCard(
            product: products[index],
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

class _OperationsEntry extends StatelessWidget {
  const _OperationsEntry();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: const Text('Team access'),
        subtitle: const Text('Delivery, admin and super admin tools'),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, DeliveryHomeScreen.routeName),
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
    );
  }
}
