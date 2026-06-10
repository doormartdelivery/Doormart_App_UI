import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

// ─── Palette ──────────────────────────────────────────────────────────────────
const _kGreen = Color(0xFFE8541A);
const _kGreenLight = Color(0xFFFFF0EB);
const _kBg = Color(0xFFF6F6F6);
const _kTextDark = Color(0xFF1A1A1A);
const _kTextMid = Color(0xFF9E9E9E);
const _kBorder = Color(0xFFE8E8E8);

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});
  static const routeName = '/';

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen>
    with SingleTickerProviderStateMixin {
  _EssentialsSort _sort = _EssentialsSort.relevance;
  String _selectedCategory = 'All';

  // Page-entry animation
  late final AnimationController _pageCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  late final Animation<double> _pageFade =
      CurvedAnimation(parent: _pageCtrl, curve: const Interval(0, 0.6, curve: Curves.easeOut));

  late final Animation<Offset> _pageSlide = Tween<Offset>(
    begin: const Offset(0, 0.04),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut));

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: GradientBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _pageFade,
            child: SlideTransition(
              position: _pageSlide,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(child: _HomeHeader()),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // ── Sticky search ──────────────────────────────────────
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SearchBarDelegate(),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  const SliverToBoxAdapter(child: _OfferBanners()),
                  const SliverToBoxAdapter(child: SizedBox(height: 22)),
                  const SliverToBoxAdapter(child: _SectionTitle('Shop by category')),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  const SliverToBoxAdapter(child: _CategoryGrid()),
                  const SliverToBoxAdapter(child: SizedBox(height: 22)),
                  const SliverToBoxAdapter(child: _SectionTitle('Fresh picks today', actionColor: _kGreen)),
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  const SliverToBoxAdapter(child: _ProductRail()),
                  const SliverToBoxAdapter(child: SizedBox(height: 22)),
                  const SliverToBoxAdapter(child: _SectionTitle('Daily essentials', actionColor: _kGreen)),
                  SliverToBoxAdapter(
                    child: _EssentialsFilters(
                      sort: _sort,
                      selectedCategory: _selectedCategory,
                      onFilterTap: _showFilterSheet,
                      onSortTap: _showSortSheet,
                      onCategorySelected: (v) =>
                          setState(() => _selectedCategory = v),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _EssentialsGrid(
                      sort: _sort,
                      selectedCategory: _selectedCategory,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 14)),
                  const SliverToBoxAdapter(child: _SectionTitle('Popular Products')),
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  const SliverToBoxAdapter(child: _TopOffersFeed()),
                  const SliverToBoxAdapter(child: SizedBox(height: 14)),
                  const SliverToBoxAdapter(child: _OperationsEntry()),
                  const SliverToBoxAdapter(child: WalkingMascotWidget()),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        index: 0,
        onTap: (index) => BottomNavBar.navigate(context, index),
      ),
    );
  }

  // ── Filter & sort sheets (unchanged logic, refreshed style) ───────────────

  void _showFilterSheet() {
    final categories = context.read<AppState>().categoryCatalog;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose category',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: _kTextDark,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: categories.map((cat) {
                  final sel = _selectedCategory == cat.name;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    child: ChoiceChip(
                      label: Text(cat.name),
                      selected: sel,
                      selectedColor: _kGreenLight,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: sel ? _kGreen : _kTextMid,
                      ),
                      onSelected: (_) =>
                          setModal(() => _selectedCategory = cat.name),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _kGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(sheetCtx);
                  },
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...[
                ('Relevance', _EssentialsSort.relevance),
                ('Price: Low to High', _EssentialsSort.priceLowHigh),
                ('Price: High to Low', _EssentialsSort.priceHighLow),
                ('Rating: High to Low', _EssentialsSort.ratingHighLow),
                ('Name: A to Z', _EssentialsSort.nameAZ),
              ].map(
                (e) => _SortTile(
                  label: e.$1,
                  selected: _sort == e.$2,
                  onTap: () => setModal(() => _sort = e.$2),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _kGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(sheetCtx);
                  },
                  child: const Text(
                    'Apply Sort',
                    style: TextStyle(fontWeight: FontWeight.w800),
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

// ─── Sticky Search Delegate ───────────────────────────────────────────────────

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  static const double _h = 72.0;
  final TextEditingController _ctrl = TextEditingController();

  @override
  double get minExtent => _h;
  @override
  double get maxExtent => _h;
  @override
  bool shouldRebuild(_SearchBarDelegate old) => false;

  @override
  Widget build(BuildContext ctx, double shrink, bool overlaps) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: _kBg,
        boxShadow: overlaps
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: VoiceSearchWidget(
        controller: _ctrl,
        readOnly: true,
        hintText: 'Search atta, milk, fruits…',
        onTap: () => Navigator.pushNamed(ctx, SearchScreen.routeName),
        onSearchChanged: (q) {
          if (q.trim().isEmpty) return;
          Navigator.pushNamed(ctx, SearchScreen.routeName, arguments: q.trim());
        },
      ),
    );
  }
}

// ─── Home Header ─────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        final addr = state.selectedAddress?.fullAddress ?? 'Add delivery address';
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _kBorder),
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
                // Orange badge
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8541A), Color(0xFFFF8A5C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _kGreen.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery in 20 minutes',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: _kTextDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 14, color: _kGreen),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              addr,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _kTextMid,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Cart + Profile
                _IconBtn(
                  icon: Icons.shopping_bag_rounded,
                  onTap: () => Navigator.pushNamed(ctx, CartScreen.routeName),
                ),
                const SizedBox(width: 6),
                _IconBtn(
                  icon: Icons.person_rounded,
                  onTap: () => Navigator.pushNamed(ctx, ProfileScreen.routeName),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _IconBtn extends StatefulWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    lowerBound: 0,
    upperBound: 0.08,
  );
  late final Animation<double> _scale =
      Tween<double>(begin: 1, end: 0.88).animate(
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
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kGreenLight,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(widget.icon, size: 20, color: _kGreen),
            ),
          ),
    );
  }
}

// ─── Offer Banners ────────────────────────────────────────────────────────────

class _OfferBanners extends StatefulWidget {
  const _OfferBanners();

  @override
  State<_OfferBanners> createState() => _OfferBannersState();
}

class _OfferBannersState extends State<_OfferBanners> {
  final PageController _ctrl = PageController(viewportFraction: 0.88);
  int _page = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _next());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _next() {
    if (!_ctrl.hasClients) return;
    final banners = context.read<AppState>().banners;
    if (banners.isEmpty) return;
    _ctrl.animateToPage(
      (_page + 1) % banners.length,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final banners = state.banners;
        final fallback = _defaultBanners;
        final items = banners.isEmpty
            ? fallback
            : banners
                .map(
                  (b) => (
                    b.title,
                    'Fresh, admin-managed offer',
                    b.imageUrl,
                    _accentForTitle(b.title),
                    _accentForTitle(b.title).withValues(alpha: 0.85),
                  ),
                )
                .toList();

        if (_page >= items.length && items.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _page = 0);
          });
        }

        return Column(
          children: [
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _ctrl,
                itemCount: items.length,
                onPageChanged: (v) => setState(() => _page = v),
                itemBuilder: (ctx, i) {
                  final b = items[i];
                  return AnimatedScale(
                    scale: _page == i ? 1.0 : 0.95,
                    duration: const Duration(milliseconds: 300),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: i == 0 ? 16 : 6,
                        right: i == items.length - 1 ? 16 : 6,
                      ),
                      child: _BannerCard(banner: b),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                items.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  width: i == _page ? 22 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == _page ? items[_page].$4 : const Color(0xFFD3DDD0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner});

  final (String, String, String, Color, Color) banner;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: banner.$4.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: _BannerImage(path: banner.$3, title: banner.$1),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    banner.$4.withValues(alpha: 0.88),
                    banner.$4.withValues(alpha: 0.56),
                    Colors.black.withValues(alpha: 0.20),
                  ],
                  stops: const [0.0, 0.62, 1.0],
                ),
              ),
            ),
          ),
          // Text content
          Positioned(
            left: 20,
            top: 20,
            bottom: 20,
            right: 130,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '🎉  Limited offer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  banner.$1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  banner.$2,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    'Shop now →',
                    style: TextStyle(
                      color: banner.$4,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
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

IconData _bannerIconFor(String title) {
  final l = title.toLowerCase();
  if (l.contains('fruit')) return Icons.apple_rounded;
  if (l.contains('vegetable')) return Icons.eco_rounded;
  if (l.contains('dairy')) return Icons.water_drop_rounded;
  return Icons.local_grocery_store_rounded;
}

class _BannerImage extends StatelessWidget {
  const _BannerImage({required this.path, required this.title});
  final String path;
  final String title;

  @override
  Widget build(BuildContext context) {
    Widget img;
    if (path.startsWith('http')) {
      img = Image.network(path, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _BannerFallback(title: title));
    } else {
      img = Image.asset(path, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _BannerFallback(title: title));
    }
    return img;
  }
}

const _defaultBanners = [
  (
    'Fresh Fruits',
    'Up to 30% off today',
    'assets/images/banners/grocery_bag.png',
    Color(0xFF0F9D58),
    Color(0xFF34C77B),
  ),
  (
    'Daily Dairy',
    'Morning essentials delivered',
    'assets/images/banners/coupon_basket.png',
    Color(0xFF1565C0),
    Color(0xFF42A5F5),
  ),
];

Color _accentForTitle(String title) {
  final value = title.toLowerCase();
  if (value.contains('dairy')) return const Color(0xFF1565C0);
  if (value.contains('vegetable')) return const Color(0xFF558B2F);
  if (value.contains('staple')) return const Color(0xFFE65100);
  if (value.contains('fruit')) return const Color(0xFF0F9D58);
  return const Color(0xFF0F766E);
}

class _BannerFallback extends StatelessWidget {
  const _BannerFallback({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(_bannerIconFor(title), size: 80, color: Colors.white70),
    );
  }
}

// ─── Section Title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.actionColor = _kGreen});
  final String title;
  final Color actionColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: _kTextDark,
                letterSpacing: -0.4,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pushNamed(context, ProductListScreen.routeName),
            style: TextButton.styleFrom(
              foregroundColor: actionColor,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text(
              'See all →',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category Grid ────────────────────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        final cats = state.categoryCatalog;
        if (cats.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('No categories available'),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cats.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.76,
          ),
          itemBuilder: (ctx, i) =>
              _CategoryTile(category: cats[i], index: i, delay: i * 55),
        );
      },
    );
  }
}

class _CategoryTile extends StatefulWidget {
  const _CategoryTile({
    required this.category,
    required this.index,
    required this.delay,
  });
  final dynamic category;
  final int index;
  final int delay;

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    lowerBound: 0,
    upperBound: 1,
  );

  late final Animation<double> _scale =
      Tween<double>(begin: 1.0, end: 0.90).animate(
    CurvedAnimation(parent: _c, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grad = _categoryGradient(widget.index);
    final tint = _categoryTint(widget.index);

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        _c.forward();
      },
      onTapUp: (_) {
        _c.reverse();
        Navigator.pushNamed(
          context,
          ProductListScreen.routeName,
          arguments: widget.category.name,
        );
      },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradient bg
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: grad,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    // Image fills tile
                    _CategoryImage(imageUrl: widget.category.imageUrl),
                    // Soft vignette at bottom
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 40,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              grad.last.withValues(alpha: 0.55),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    // Tinted border ring
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: tint.withValues(alpha: 0.45),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _kTextDark,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryImage extends StatelessWidget {
  const _CategoryImage({required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const _CategoryFallback());
    }
    if (imageUrl.startsWith('http')) {
      return Image.network(imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const _CategoryFallback());
    }
    return const _CategoryFallback();
  }
}

class _CategoryFallback extends StatelessWidget {
  const _CategoryFallback();

  @override
  Widget build(BuildContext context) => const Center(
        child: Icon(Icons.category_rounded, size: 34, color: _kGreen),
      );
}

List<Color> _categoryGradient(int i) {
  const g = [
    [Color(0xFFC8F2D8), Color(0xFF7ECFA0)],
    [Color(0xFFFFEBB8), Color(0xFFFFBF47)],
    [Color(0xFFCDE3FF), Color(0xFF80B8F8)],
    [Color(0xFFFFD8CC), Color(0xFFFF8C69)],
    [Color(0xFFEEDEFF), Color(0xFFBD94F5)],
    [Color(0xFFC5F5E8), Color(0xFF5ED4B0)],
    [Color(0xFFFFDCED), Color(0xFFEE82C0)],
    [Color(0xFFFFF2C2), Color(0xFFFFCA2C)],
  ];
  return g[i % g.length].toList();
}

Color _categoryTint(int i) {
  const t = [
    Color(0xFF7ECFA0),
    Color(0xFFFFBF47),
    Color(0xFF80B8F8),
    Color(0xFFFF8C69),
    Color(0xFFBD94F5),
    Color(0xFF5ED4B0),
    Color(0xFFEE82C0),
    Color(0xFFFFCA2C),
  ];
  return t[i % t.length];
}

// ─── Product Rail ─────────────────────────────────────────────────────────────

class _ProductRail extends StatelessWidget {
  const _ProductRail();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        final products = state.products;
        return SizedBox(
          height: 320,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) => _AnimatedProductCard(
              index: i,
              child: SizedBox(
                width: 168,
                child: ProductCard(
                  product: products[i],
                  isFavorite: state.isFavorite(products[i]),
                  onFavoriteToggle: () => state.toggleFavorite(products[i]),
                  onTap: () => showProductBottomSheet(
                    ctx,
                    products[i],
                    onAddToCart: (qty) async {
                      final ok = await state.addToCart(products[i], quantity: qty);
                      if (!ctx.mounted) return;
                      showToast(ctx,
                          ok ? '${products[i].name} added to cart' : state.error ?? 'Please login first');
                    },
                  ),
                  onAdd: () async {
                    final ok = await state.addToCart(products[i]);
                    if (!ctx.mounted) return;
                    showToast(ctx,
                        ok ? '${products[i].name} added to cart' : state.error ?? 'Please login first');
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Staggered fade+slide for list items
class _AnimatedProductCard extends StatefulWidget {
  const _AnimatedProductCard({required this.child, required this.index});
  final Widget child;
  final int index;

  @override
  State<_AnimatedProductCard> createState() => _AnimatedProductCardState();
}

class _AnimatedProductCardState extends State<_AnimatedProductCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: const Interval(0, 0.7, curve: Curves.easeOut));

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0.12, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

class _HomeFeedCard extends StatelessWidget {
  const _HomeFeedCard({
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
                    child: _HomeFeedImage(imageUrl: product.imageUrl),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _HomeRatingChip(
                    rating: product.rating.toStringAsFixed(1),
                  ),
                ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: _HomeTextChip(
                    'ITEMS',
                    subText: 'AT Rs ${product.price.toStringAsFixed(0)}',
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
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
                        color: _kTextDark,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _kTextMid,
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'Rs ${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: _kTextDark,
                          ),
                        ),
                        const Spacer(),
                        _QuantityLikeFavorite(
                          isFavorite: isFavorite,
                          onTap: onFavoriteToggle,
                        ),
                        const SizedBox(width: 14),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: _kGreen,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: _kGreen.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: 230,
                        child: FilledButton(
                          onPressed: onAdd,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            shadowColor: Colors.transparent,
                            elevation: 0,
                          ),
                          child: const Text(
                            'Add to Cart',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
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

class _QuantityLikeFavorite extends StatelessWidget {
  const _QuantityLikeFavorite({required this.isFavorite, required this.onTap});
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
              color: const Color(0xFFE8541A).withValues(alpha: 0.18),
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

class _HomeRatingChip extends StatelessWidget {
  const _HomeRatingChip({required this.rating});
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

class _HomeFeedImage extends StatelessWidget {
  const _HomeFeedImage({required this.imageUrl});
  final String imageUrl;
  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('assets/')) {
      return SizedBox.expand(
        child: Image.asset(imageUrl, fit: BoxFit.cover),
      );
    }
    if (imageUrl.startsWith('http')) {
      return SizedBox.expand(
        child: Image.network(imageUrl, fit: BoxFit.cover),
      );
    }
    return const ColoredBox(
      color: Color(0xFFF1F5F9),
      child: Center(
        child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF64748B)),
      ),
    );
  }
}

class _HomeBadgeButton extends StatelessWidget {
  const _HomeBadgeButton({
    required this.active,
    required this.child,
    required this.onTap,
  });
  final bool active;
  final Widget child;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: active ? 0.34 : 0.22),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: child,
        ),
      ),
    );
  }
}

class _HomeTextChip extends StatelessWidget {
  const _HomeTextChip(this.label, {required this.subText});
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
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
            Text(subText, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

// ─── Essentials ───────────────────────────────────────────────────────────────

enum _EssentialsSort { relevance, priceLowHigh, priceHighLow, ratingHighLow, nameAZ }

class _EssentialsGrid extends StatelessWidget {
  const _EssentialsGrid({required this.sort, required this.selectedCategory});
  final _EssentialsSort sort;
  final String selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        var products = List<ProductModel>.from(state.products);
        if (selectedCategory != 'All') {
          products = products
              .where((p) => p.category.toLowerCase() == selectedCategory.toLowerCase())
              .toList();
        }
        switch (sort) {
          case _EssentialsSort.priceLowHigh:
            products.sort((a, b) => a.price.compareTo(b.price));
          case _EssentialsSort.priceHighLow:
            products.sort((a, b) => b.price.compareTo(a.price));
          case _EssentialsSort.ratingHighLow:
            products.sort((a, b) => b.rating.compareTo(a.rating));
          case _EssentialsSort.nameAZ:
            products.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          default:
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
          itemBuilder: (ctx, i) => ProductCard(
            product: products[i],
            isFavorite: state.isFavorite(products[i]),
            onFavoriteToggle: () => state.toggleFavorite(products[i]),
            onTap: () => showProductBottomSheet(ctx, products[i],
                onAddToCart: (qty) async {
              final ok = await state.addToCart(products[i], quantity: qty);
              if (!ctx.mounted) return;
              showToast(ctx,
                  ok ? '${products[i].name} added to cart' : state.error ?? 'Please login first');
            }),
            onAdd: () async {
              final ok = await state.addToCart(products[i]);
              if (!ctx.mounted) return;
              showToast(ctx,
                  ok ? '${products[i].name} added to cart' : state.error ?? 'Please login first');
            },
          ),
        );
      },
    );
  }
}

class _TopOffersFeed extends StatelessWidget {
  const _TopOffersFeed();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        final products = state.products;
        if (products.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('No top offers available'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          separatorBuilder: (_, __) => const SizedBox(height: 18),
          itemBuilder: (ctx, i) {
            final product = products[i];
            return _HomeFeedCard(
              product: product,
              isFavorite: state.isFavorite(product),
              onFavoriteToggle: () => state.toggleFavorite(product),
              onTap: () => showProductBottomSheet(
                ctx,
                product,
                onAddToCart: (qty) async {
                  final ok = await state.addToCart(product, quantity: qty);
                  if (!ctx.mounted) return;
                  showToast(
                    ctx,
                    ok ? '${product.name} added to cart' : state.error ?? 'Please login first',
                  );
                },
              ),
              onAdd: () async {
                final ok = await state.addToCart(product);
                if (!ctx.mounted) return;
                showToast(
                  ctx,
                  ok ? '${product.name} added to cart' : state.error ?? 'Please login first',
                );
              },
            );
          },
        );
      },
    );
  }
}

// ─── Filter chips ─────────────────────────────────────────────────────────────

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
      _FeedChipData('Filter', Icons.tune_rounded, selectedCategory != 'All'),
      _FeedChipData('Sort by', Icons.sort_rounded, sort != _EssentialsSort.relevance),
      _FeedChipData(
        selectedCategory == 'All' ? 'All Categories' : selectedCategory,
        Icons.category_rounded,
        selectedCategory != 'All',
      ),
    ];
    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final chip = chips[i];
          return _FeedChip(
            label: chip.label,
            icon: chip.icon,
            active: chip.active,
            onTap: () => i == 0
                ? onFilterTap()
                : i == 1
                    ? onSortTap()
                    : onFilterTap(),
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

class _FeedChip extends StatefulWidget {
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
  State<_FeedChip> createState() => _FeedChipState();
}

class _FeedChipState extends State<_FeedChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    lowerBound: 0,
    upperBound: 1,
  );
  late final Animation<double> _scale =
      Tween<double>(begin: 1.0, end: 0.92).animate(
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minWidth: 92),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.active
                ? _kGreen
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.active
                  ? _kGreen
                  : _kBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon,
                  size: 16,
                  color: widget.active ? Colors.white : _kTextDark),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: widget.active ? Colors.white : _kTextDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sort tile ────────────────────────────────────────────────────────────────

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
          color: selected ? _kGreen : _kTextDark,
        ),
      ),
      trailing: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: selected
            ? const Icon(Icons.check_circle_rounded, color: _kGreen, key: ValueKey(true))
            : const Icon(Icons.circle_outlined, color: Color(0xFFB7B0A6), key: ValueKey(false)),
      ),
    );
  }
}

// ─── Operations Entry ─────────────────────────────────────────────────────────

class _OperationsEntry extends StatelessWidget {
  const _OperationsEntry();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          shape: const Border(),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kGreenLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.manage_accounts_rounded,
                color: _kGreen, size: 20),
          ),
          title: const Text(
            'Team access',
            style: TextStyle(fontWeight: FontWeight.w800, color: _kTextDark),
          ),
          subtitle: const Text(
            'Delivery, admin & super admin',
            style: TextStyle(fontSize: 12, color: _kTextMid),
          ),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TeamBtn(
                  icon: Icons.delivery_dining_rounded,
                  label: 'Delivery',
                  onTap: () => Navigator.pushNamed(
                      context, DeliveryHomeScreen.routeName),
                ),
                _TeamBtn(
                  icon: Icons.admin_panel_settings_rounded,
                  label: 'Admin',
                  onTap: () => Navigator.pushNamed(
                      context, AdminDashboardScreen.routeName),
                ),
                _TeamBtn(
                  icon: Icons.insights_rounded,
                  label: 'Super admin',
                  onTap: () => Navigator.pushNamed(
                      context, SuperAdminDashboardScreen.routeName),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamBtn extends StatelessWidget {
  const _TeamBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: _kGreen,
        side: const BorderSide(color: _kBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
