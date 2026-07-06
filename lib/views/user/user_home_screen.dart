import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../mascot/walking_mascot_widget.dart';
import '../../core/utils/network_image_url.dart';
import '../../models/product_model.dart';
import '../../providers/app_state.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/product_bottom_sheet.dart';
import '../../widgets/product_card.dart';
import '../../widgets/toast_widget.dart';
import '../../features/customer/search/voice_search_widget.dart';
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
  _EssentialsSort _popularSort = _EssentialsSort.relevance;
  String _selectedCategory = 'All';
  String _popularSelectedCategory = 'All';

  // Page-entry animation
  late final AnimationController _pageCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  late final Animation<double> _pageFade = CurvedAnimation(
    parent: _pageCtrl,
    curve: const Interval(0, 0.6, curve: Curves.easeOut),
  );

  late final Animation<Offset> _pageSlide = Tween<Offset>(
    begin: const Offset(0, 0.04),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut));

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleFavoriteGuarded(
    AppState state,
    BuildContext context,
    ProductModel product,
  ) async {
    if (!state.signedIn) {
      showToast(context, 'Please login first');
      return;
    }
    await state.toggleFavorite(product);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _pageFade,
          child: SlideTransition(
            position: _pageSlide,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CustomScrollView(
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
                    const SliverToBoxAdapter(
                      child: _SectionTitle('Shop by category'),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    const SliverToBoxAdapter(child: _CategoryGrid()),
                    const SliverToBoxAdapter(child: SizedBox(height: 22)),
                    const SliverToBoxAdapter(
                      child: _SectionTitle(
                        'Fresh picks today',
                        actionColor: _kGreen,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 10)),
                    const SliverToBoxAdapter(child: _ProductRail()),
                    const SliverToBoxAdapter(child: SizedBox(height: 18)),
                    const SliverToBoxAdapter(child: _SummerSipSection()),
                    const SliverToBoxAdapter(child: SizedBox(height: 18)),
                    const SliverToBoxAdapter(child: SizedBox(height: 22)),
                    const SliverToBoxAdapter(
                      child: _SectionTitle(
                        'Daily essentials',
                        actionColor: _kGreen,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _EssentialsFilters(
                        sort: _sort,
                        onFilterTap: _showFilterSheet,
                        onSortTap: _showSortSheet,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _EssentialsGrid(
                        sort: _sort,
                        selectedCategory: _selectedCategory,
                        onFavoriteToggle: (product) =>
                            _toggleFavoriteGuarded(
                              context.read<AppState>(),
                              context,
                              product,
                            ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 18)),
                    const SliverToBoxAdapter(child: _GroceryComboSection()),
                    const SliverToBoxAdapter(child: SizedBox(height: 14)),
                    const SliverToBoxAdapter(
                      child: _SectionTitle('Popular Products'),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 10)),
                    SliverToBoxAdapter(
                      child: _PopularFilters(
                        sort: _popularSort,
                        selectedCategory: _popularSelectedCategory,
                        onFilterTap: _showPopularFilterSheet,
                        onSortTap: _showPopularSortSheet,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _PopularProductsGrid(
                        sort: _popularSort,
                        selectedCategory: _popularSelectedCategory,
                        onFavoriteToggle: (product) =>
                            _toggleFavoriteGuarded(
                              context.read<AppState>(),
                              context,
                              product,
                            ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 170)),
                    SliverToBoxAdapter(child: SizedBox(height: bottomInset)),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: BottomNavBar(
                    index: 0,
                    onTap: (index) => BottomNavBar.navigate(context, index),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 25 + bottomInset,
                  child: const IgnorePointer(
                    child: WalkingMascotWidget(),
                  ),
                ),
              ],
            ),
          ),
        ),
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
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    child: ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedCategory == 'All',
                      selectedColor: _kGreenLight,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _selectedCategory == 'All' ? _kGreen : _kTextMid,
                      ),
                      onSelected: (_) =>
                          setModal(() => _selectedCategory = 'All'),
                    ),
                  ),
                  ...categories.map((cat) {
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
                  }),
                ],
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

  void _showPopularFilterSheet() {
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
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _popularSelectedCategory == 'All',
                    selectedColor: _kGreenLight,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _popularSelectedCategory == 'All'
                          ? _kGreen
                          : _kTextMid,
                    ),
                    onSelected: (_) =>
                        setModal(() => _popularSelectedCategory = 'All'),
                  ),
                  ...categories.map((cat) {
                    final sel = _popularSelectedCategory == cat.name;
                    return ChoiceChip(
                      label: Text(cat.name),
                      selected: sel,
                      selectedColor: _kGreenLight,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: sel ? _kGreen : _kTextMid,
                      ),
                      onSelected: (_) =>
                          setModal(() => _popularSelectedCategory = cat.name),
                    );
                  }),
                ],
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

  void _showPopularSortSheet() {
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
                'Sort products',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: _kTextDark,
                ),
              ),
              const SizedBox(height: 14),
              _SortTile(
                label: 'Relevance',
                selected: _popularSort == _EssentialsSort.relevance,
                onTap: () =>
                    setModal(() => _popularSort = _EssentialsSort.relevance),
              ),
              _SortTile(
                label: 'Price: Low to High',
                selected: _popularSort == _EssentialsSort.priceLowHigh,
                onTap: () =>
                    setModal(() => _popularSort = _EssentialsSort.priceLowHigh),
              ),
              _SortTile(
                label: 'Price: High to Low',
                selected: _popularSort == _EssentialsSort.priceHighLow,
                onTap: () =>
                    setModal(() => _popularSort = _EssentialsSort.priceHighLow),
              ),
              _SortTile(
                label: 'Rating: High to Low',
                selected: _popularSort == _EssentialsSort.ratingHighLow,
                onTap: () => setModal(
                  () => _popularSort = _EssentialsSort.ratingHighLow,
                ),
              ),
              _SortTile(
                label: 'Name: A to Z',
                selected: _popularSort == _EssentialsSort.nameAZ,
                onTap: () =>
                    setModal(() => _popularSort = _EssentialsSort.nameAZ),
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
        final addr =
            state.selectedAddress?.fullAddress ?? 'Add delivery address';
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
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Door Mart',
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
                          const Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: _kGreen,
                          ),
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
                  onTap: () =>
                      Navigator.pushNamed(ctx, ProfileScreen.routeName),
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
  late final Animation<double> _scale = Tween<double>(
    begin: 1,
    end: 0.88,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

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
                      child: _BannerCard(
                        banner: b,
                        onTap: () => Navigator.pushNamed(
                          ctx,
                          ProductListScreen.routeName,
                        ),
                      ),
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
                    color: i == _page
                        ? items[_page].$4
                        : const Color(0xFFD3DDD0),
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
  const _BannerCard({required this.banner, required this.onTap});

  final (String, String, String, Color, Color) banner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(28),
        child: Container(
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
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
        ),
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
    final normalized = NetworkImageUrl.normalize(path);
    Widget img;
    if (normalized.startsWith('http')) {
      img = Image.network(
        normalized,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _BannerFallback(title: title),
      );
    } else {
      img = Image.asset(
        normalized,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _BannerFallback(title: title),
      );
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
    final lower = title.toLowerCase();
    final asset = lower.contains('dairy')
        ? 'assets/images/banners/coupon_basket.png'
        : 'assets/images/banners/grocery_bag.png';
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => Center(
        child: Icon(_bannerIconFor(title), size: 80, color: Colors.white70),
      ),
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

  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 0.90,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

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
    final normalized = NetworkImageUrl.normalize(imageUrl);
    if (normalized.startsWith('assets/')) {
      return Image.asset(
        normalized,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const _CategoryFallback(),
      );
    }
    if (normalized.startsWith('http')) {
      return Image.network(
        normalized,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const _CategoryFallback(),
      );
    }
    return const _CategoryFallback();
  }
}

class _CategoryFallback extends StatelessWidget {
  const _CategoryFallback();

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/categories/vegetables.png',
    fit: BoxFit.cover,
    gaplessPlayback: true,
    errorBuilder: (_, __, ___) => const Center(
      child: Icon(Icons.category_rounded, size: 34, color: _kGreen),
    ),
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
        final products = state.products
            .where((p) => p.dashboardSection == 'fresh_picks')
            .toList();
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
                  onFavoriteToggle: () {
                    if (!state.signedIn) {
                      showToast(ctx, 'Please login first');
                      return;
                    }
                    state.toggleFavorite(products[i]);
                  },
                  onTap: () => showProductBottomSheet(
                    ctx,
                    products[i],
                    onAddToCart: (qty) async {
                      final ok = await state.addToCart(
                        products[i],
                        quantity: qty,
                      );
                      if (!ctx.mounted) return;
                      showToast(
                        ctx,
                        ok
                            ? '${products[i].name} added to cart'
                            : state.error ?? 'Please login first',
                      );
                    },
                  ),
                  onAdd: () async {
                    final ok = await state.addToCart(products[i]);
                    if (!ctx.mounted) return;
                    showToast(
                      ctx,
                      ok
                          ? '${products[i].name} added to cart'
                          : state.error ?? 'Please login first',
                    );
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

  late final Animation<double> _fade = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.7, curve: Curves.easeOut),
  );

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
      child: Stack(
        children: [
          Container(
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
                      clipBehavior: Clip.antiAlias,
                      borderRadius: BorderRadius.circular(22),
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
                        'PACK',
                        subText: _unitLabel(product.unit),
                      ),
                    ),
                  ],
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
                          maxLines: 1,
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
                          '${product.category} • ${_unitLabel(product.unit)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _kTextMid,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          product.description.isNotEmpty
                              ? product.description
                              : 'Fresh, handpicked and ready to add to your basket.',
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
                              '₹ ${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: _kTextDark,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '₹ ${_mrpValue(product).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _kTextMid,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: _kTextMid,
                                decorationThickness: 1.5,
                              ),
                            ),
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
                            width: double.infinity,
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
                                  fontSize: 12,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                shadowColor: Colors.transparent,
                                elevation: 0,
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
          Positioned(
            top: 12,
            right: 12,
            child: _QuantityLikeFavorite(
              isFavorite: isFavorite,
              onTap: onFavoriteToggle,
            ),
          ),
        ],
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
    final normalized = NetworkImageUrl.normalize(imageUrl);
    debugPrint('Cloudinary Image URL (home feed): $normalized');
    Widget child;
    if (normalized.startsWith('assets/')) {
      child = Image.asset(
        normalized,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    } else if (normalized.startsWith('http')) {
      child = Image.network(
        normalized,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Image Load Error (home feed): $error');
          return const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Color(0xFF64748B),
            ),
          );
        },
      );
    } else {
      child = Image.asset(
        imageUrl.toLowerCase().contains('banner')
            ? 'assets/images/banners/grocery_bag.png'
            : 'assets/images/products/tomato.png',
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }
    return ClipRRect(
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox.expand(child: child),
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
        child: Padding(padding: const EdgeInsets.all(8), child: child),
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

// ─── Essentials ───────────────────────────────────────────────────────────────

enum _EssentialsSort {
  relevance,
  priceLowHigh,
  priceHighLow,
  ratingHighLow,
  nameAZ,
}

class _EssentialsGrid extends StatelessWidget {
  const _EssentialsGrid({
    required this.sort,
    required this.selectedCategory,
    required this.onFavoriteToggle,
  });
  final _EssentialsSort sort;
  final String selectedCategory;
  final Future<void> Function(ProductModel product) onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        var products = state.products
            .where((p) => p.dashboardSection == 'daily_essentials')
            .toList();
        if (selectedCategory != 'All') {
          products = products
              .where(
                (p) =>
                    p.category.toLowerCase() == selectedCategory.toLowerCase(),
              )
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
            products.sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
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
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.58,
          ),
          itemBuilder: (ctx, i) {
            final product = products[i];
            return _PopularStyleProductCard(
              product: product,
              isFavorite: state.isFavorite(product),
              onFavoriteToggle: () => onFavoriteToggle(product),
              onTap: () => showProductBottomSheet(
                ctx,
                product,
                onAddToCart: (qty) async {
                  final ok = await state.addToCart(product, quantity: qty);
                  if (!ctx.mounted) return;
                  showToast(
                    ctx,
                    ok
                        ? '${product.name} added to cart'
                        : state.error ?? 'Please login first',
                  );
                },
              ),
              onAdd: () async {
                final ok = await state.addToCart(product);
                if (!ctx.mounted) return;
                showToast(
                  ctx,
                  ok
                      ? '${product.name} added to cart'
                      : state.error ?? 'Please login first',
                );
              },
            );
          },
        );
      },
    );
  }
}

class _PopularStyleProductCard extends StatelessWidget {
  const _PopularStyleProductCard({
    required this.product,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onAdd,
    required this.onTap,
  });

  final ProductModel product;
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
        child: Column(
          children: [
            Expanded(
              flex: 62,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                    child: _HomeFeedImage(imageUrl: product.imageUrl),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _QuantityLikeFavorite(
                      isFavorite: isFavorite,
                      onTap: onFavoriteToggle,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 55,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _kTextDark,
                        height: 1.25,
                      ),
                    ),
                    Text(
                      '${product.category} • ${_unitLabel(product.unit)}',
                      style: const TextStyle(fontSize: 12, color: _kTextMid),
                    ),
                    Text(
                      product.description.isNotEmpty
                          ? product.description
                          : 'Fresh, handpicked and ready to add to your basket.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.2,
                        color: Colors.black.withValues(alpha: 0.58),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '₹ ${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: _kTextDark,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '₹ ${_mrpValue(product).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _kTextMid,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: _kTextMid,
                            decorationThickness: 1.6,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${product.stock > 20 ? 10 : 18} min',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _kTextMid,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: 38,
                      width: double.infinity,
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
                      child: FilledButton(
                        onPressed: onAdd,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text(
                          'Add to Cart',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
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

double _mrpValue(ProductModel product) {
  final mrp = product.mrp;
  if (mrp > 0) return mrp;
  return product.price * 1.12;
}

class _TopOffersFeed extends StatelessWidget {
  const _TopOffersFeed();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        final products = state.products
            .where((p) => p.dashboardSection == 'popular_products')
            .toList();
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
              onFavoriteToggle: () {
                if (!state.signedIn) {
                  showToast(ctx, 'Please login first');
                  return;
                }
                state.toggleFavorite(product);
              },
              onTap: () => showProductBottomSheet(
                ctx,
                product,
                onAddToCart: (qty) async {
                  final ok = await state.addToCart(product, quantity: qty);
                  if (!ctx.mounted) return;
                  showToast(
                    ctx,
                    ok
                        ? '${product.name} added to cart'
                        : state.error ?? 'Please login first',
                  );
                },
              ),
              onAdd: () async {
                final ok = await state.addToCart(product);
                if (!ctx.mounted) return;
                showToast(
                  ctx,
                  ok
                      ? '${product.name} added to cart'
                      : state.error ?? 'Please login first',
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SummerSipSection extends StatelessWidget {
  const _SummerSipSection();

  static const _tiles = [
    _SipTile(
      'Fresh\nGrocery Deals',
      '₹66',
      '🛒',
      Color(0xFFFF6B2C),
      '',
      'assets/images/banners/grocery_bag.png',
    ),
    _SipTile(
      'Milk &\nDairy',
      '₹19',
      '🥛',
      Color(0xFFFF8A3D),
      '',
      'assets/images/categories/dairy.png',
    ),
    _SipTile(
      'Fresh\nVegetables',
      '₹29',
      '🥬',
      Color(0xFFFF7A1A),
      '',
      'assets/images/categories/vegetables.png',
    ),
    _SipTile(
      'Fruits\nBundle',
      '₹19',
      '🍎',
      Color(0xFFFF9A3D),
      '',
      'assets/images/categories/fruits.png',
    ),
    _SipTile(
      'Staples\nEssentials',
      '₹19',
      '🛍️',
      Color(0xFFFFB14A),
      '',
      'assets/images/categories/staples.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF7A1A), Color(0xFFFF8C42), Color(0xFFFFA85C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF7A1A).withValues(alpha: 0.30),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -18,
              right: 90,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -10,
              left: -10,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            const Positioned(
              top: 6,
              right: 12,
              child: _GroceriesIllustration(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Door Mart',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFFF0D5),
                                letterSpacing: 1.5,
                                height: 1.0,
                              ),
                            ),
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Hot',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      fontStyle: FontStyle.italic,
                                      height: 1.1,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' ',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFFFF0D5),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Deals',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 100),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _TileGrid(tiles: _tiles),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroceryComboSection extends StatelessWidget {
  const _GroceryComboSection();

  static const _tiles = [
    _SipTile(
      'Value\nBundle',
      '₹49',
      '🧺',
      Color(0xFFFF8C42),
      'SAVE\nMORE',
      'assets/images/categories/staples.png',
    ),
    _SipTile(
      'Daily\nMilk Pack',
      '₹22',
      '🥛',
      Color(0xFFFF7A1A),
      '',
      'assets/images/categories/dairy.png',
    ),
    _SipTile(
      'Fresh\nFarm Picks',
      '₹35',
      '',
      Color(0xFFFFA24A),
      'NEW',
      'assets/images/categories/vegetables.png',
    ),
    _SipTile(
      'Fruit\nCombo',
      '₹27',
      '🍇',
      Color(0xFFFF6B2C),
      '',
      'assets/images/categories/fruits.png',
    ),
    _SipTile(
      'Kitchen\nBasics',
      '₹19',
      '🛍️',
      Color(0xFFFFB14A),
      '',
      'assets/images/banners/grocery_bag.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF26522), Color(0xFFFF8A3D), Color(0xFFFFB14A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF26522).withValues(alpha: 0.26),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -16,
              right: 94,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -12,
              left: -8,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            const Positioned(
              top: 8,
              right: 12,
              child: _GroceriesIllustration(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GROCERY',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFFF4E3),
                                letterSpacing: 1.5,
                                height: 1.0,
                              ),
                            ),
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Best',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      fontStyle: FontStyle.italic,
                                      height: 1.1,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' ',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFFFF4E3),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Buys',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 100),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _TileGrid(tiles: _tiles),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.tiles});
  final List<_SipTile> tiles;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: _BigTile(tile: tiles[0])),
        const SizedBox(width: 8),
        Expanded(
          flex: 9,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _SmallTile(tile: tiles[1])),
                  const SizedBox(width: 6),
                  Expanded(child: _SmallTile(tile: tiles[2])),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: _SmallTile(tile: tiles[3])),
                  const SizedBox(width: 6),
                  Expanded(child: _SmallTile(tile: tiles[4])),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BigTile extends StatelessWidget {
  const _BigTile({required this.tile});
  final _SipTile tile;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 148,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        gradient: LinearGradient(
          colors: [tile.color, tile.color.withValues(alpha: 0.70)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: tile.color.withValues(alpha: 0.40),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.80,
              child: _TileBackgroundImage(path: tile.backgroundImage),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.70),
                    Colors.black.withValues(alpha: 0.70),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -6,
            right: -6,
            child: Text(tile.emoji, style: const TextStyle(fontSize: 44)),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tile.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                const Spacer(),
                Text(
                  '₹89',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.60),
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.white60,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE135),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tile.price,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A2E),
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

class _SmallTile extends StatelessWidget {
  const _SmallTile({required this.tile});
  final _SipTile tile;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tile.color, tile.color.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: tile.color.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.70,
              child: _TileBackgroundImage(path: tile.backgroundImage),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.80),
                    Colors.black.withValues(alpha: 0.04),
                  ],
                ),
              ),
            ),
          ),
          if (tile.badge.isNotEmpty)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  tile.badge,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF3B2DA8),
                    height: 1.2,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        tile.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                    Text(tile.emoji, style: const TextStyle(fontSize: 16)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE135),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tile.price,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A2E),
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

class _GroceriesIllustration extends StatelessWidget {
  const _GroceriesIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 2,
            child: Container(
              width: 54,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shopping_bag_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 8,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_grocery_store_rounded,
                size: 10,
                color: Color(0xFFF26522),
              ),
            ),
          ),
          Positioned(top: 8, left: 10, child: _Bubble(size: 8, opacity: 0.60)),
          Positioned(top: 18, left: 20, child: _Bubble(size: 5, opacity: 0.40)),
          Positioned(top: 4, right: 6, child: _Bubble(size: 6, opacity: 0.50)),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.opacity});
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _TileBackgroundImage extends StatelessWidget {
  const _TileBackgroundImage({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    final normalized = NetworkImageUrl.normalize(path);
    if (normalized.startsWith('assets/')) {
      return Image.asset(
        normalized,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    if (normalized.startsWith('http')) {
      return Image.network(
        normalized,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    return const SizedBox.shrink();
  }
}

class _SipTile {
  const _SipTile(
    this.label,
    this.price,
    this.emoji,
    this.color,
    this.badge,
    this.backgroundImage,
  );
  final String label;
  final String price;
  final String emoji;
  final Color color;
  final String badge;
  final String backgroundImage;
}

class _PopularProductsGrid extends StatelessWidget {
  const _PopularProductsGrid({
    required this.sort,
    required this.selectedCategory,
    required this.onFavoriteToggle,
  });
  final _EssentialsSort sort;
  final String selectedCategory;
  final Future<void> Function(ProductModel product) onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        var products = state.products
            .where((p) => p.dashboardSection == 'popular_products')
            .toList();
        if (selectedCategory != 'All') {
          products = products
              .where(
                (p) =>
                    p.category.toLowerCase() == selectedCategory.toLowerCase(),
              )
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
            products.sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
          default:
            break;
        }
        if (products.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('No popular products found'),
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
              onFavoriteToggle: () => onFavoriteToggle(product),
              onTap: () => showProductBottomSheet(
                ctx,
                product,
                onAddToCart: (qty) async {
                  final ok = await state.addToCart(product, quantity: qty);
                  if (!ctx.mounted) return;
                  showToast(
                    ctx,
                    ok
                        ? '${product.name} added to cart'
                        : state.error ?? 'Please login first',
                  );
                },
              ),
              onAdd: () async {
                final ok = await state.addToCart(product);
                if (!ctx.mounted) return;
                showToast(
                  ctx,
                  ok
                      ? '${product.name} added to cart'
                      : state.error ?? 'Please login first',
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
  });
  final _EssentialsSort sort;
  final VoidCallback onFilterTap;
  final VoidCallback onSortTap;

  @override
  Widget build(BuildContext context) {
    final chips = [
      const _FeedChipData('Filter', Icons.tune_rounded, false),
      _FeedChipData(
        'Sort by',
        Icons.sort_rounded,
        sort != _EssentialsSort.relevance,
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
            onTap: () => i == 0 ? onFilterTap() : onSortTap(),
          );
        },
      ),
    );
  }
}

class _PopularFilters extends StatelessWidget {
  const _PopularFilters({
    required this.sort,
    required this.selectedCategory,
    required this.onFilterTap,
    required this.onSortTap,
  });

  final _EssentialsSort sort;
  final String selectedCategory;
  final VoidCallback onFilterTap;
  final VoidCallback onSortTap;

  @override
  Widget build(BuildContext context) {
    final active = selectedCategory != 'All';
    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        scrollDirection: Axis.horizontal,
        itemCount: 2,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _FeedChip(
              label: 'Filter',
              icon: Icons.tune_rounded,
              active: active,
              onTap: onFilterTap,
            );
          }
          return _FeedChip(
            label: 'Sort by',
            icon: Icons.sort_rounded,
            active: sort != _EssentialsSort.relevance,
            onTap: onSortTap,
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
  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 0.92,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

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
            gradient: LinearGradient(
              colors: widget.active
                  ? const [Color(0xFFFFF0EB), Color(0xFFFFE3D3)]
                  : const [Colors.white, Color(0xFFFFF7F2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.active ? _kGreen : const Color(0xFFF1CDBD),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: _kGreen.withValues(alpha: widget.active ? 0.28 : 0.16),
                blurRadius: widget.active ? 18 : 14,
                spreadRadius: widget.active ? 0.6 : 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: _kGreen),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: _kGreen,
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
            ? Icon(
                Icons.check_circle_rounded,
                color: _kGreen,
                key: const ValueKey(true),
              )
            : const Icon(
                Icons.circle_outlined,
                color: Color(0xFFB7B0A6),
                key: ValueKey(false),
              ),
      ),
    );
  }
}
