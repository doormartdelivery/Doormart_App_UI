import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../mascot/walking_mascot_widget.dart';
import '../../providers/app_state.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/product_card.dart';
import '../admin/admin_dashboard_screen.dart';
import '../delivery/delivery_home_screen.dart';
import '../super_admin/super_admin_dashboard_screen.dart';
import 'cart_screen.dart';
import 'product_list_screen.dart';

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF4),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _HomeHeader()),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            const SliverToBoxAdapter(child: _SearchAndDelivery()),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            const SliverToBoxAdapter(child: _OfferBanners()),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
            const SliverToBoxAdapter(child: _SectionTitle('Shop by category')),
            const SliverToBoxAdapter(child: _CategoryGrid()),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
            const SliverToBoxAdapter(child: _SectionTitle('Fresh picks today')),
            const SliverToBoxAdapter(child: _ProductRail()),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
            const SliverToBoxAdapter(child: _SectionTitle('Daily essentials')),
            const SliverToBoxAdapter(child: _EssentialsGrid()),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
            const SliverToBoxAdapter(child: _OperationsEntry()),
            const SliverToBoxAdapter(child: WalkingMascotWidget()),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(index: 0, onTap: (_) {}),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.location_on, size: 18, color: Color(0xFF667064)),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Anna Nagar, Chennai',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Color(0xFF667064)),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down, size: 18),
                  ],
                ),
              ],
            ),
          ),
          Consumer<AppState>(
            builder: (context, state, _) => Badge(
              isLabelVisible: state.cartCount > 0,
              label: Text('${state.cartCount}'),
              child: IconButton.filledTonal(
                tooltip: 'Cart',
                onPressed: () =>
                    Navigator.pushNamed(context, CartScreen.routeName),
                icon: const Icon(Icons.shopping_cart),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchAndDelivery extends StatelessWidget {
  const _SearchAndDelivery();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () =>
                  Navigator.pushNamed(context, ProductListScreen.routeName),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Color(0xFF667064)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search atta, milk, fruits...',
                        style: TextStyle(color: Color(0xFF667064)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFF8A00),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.mic, color: Colors.white),
          ),
        ],
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
      'assets/images/categories/fruits.png',
      Color(0xFFFFF0D7),
    ),
    (
      'Daily dairy',
      'Morning essentials',
      'assets/images/categories/dairy.png',
      Color(0xFFE7F7EC),
    ),
    (
      'Home care',
      'Cleaning deals',
      'assets/images/categories/cleaning.png',
      Color(0xFFEAF1FF),
    ),
    (
      'Kitchen staples',
      'Rice, dal and oil',
      'assets/images/categories/staples.png',
      Color(0xFFFFEFEA),
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
          height: 164,
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: banner.$4,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              banner.$1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              banner.$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Shop now',
                              style: TextStyle(
                                color: Color(0xFF0F9D58),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Image.asset(
                        banner.$3,
                        width: 82,
                        height: 82,
                        fit: BoxFit.contain,
                      ),
                    ],
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
                onAdd: () => state.addToCart(products[index]),
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
            onAdd: () => state.addToCart(products[index]),
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
