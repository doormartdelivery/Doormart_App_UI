import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../mascot/walking_mascot_widget.dart';
import '../../core/utils/network_image_url.dart';
import '../../models/product_model.dart';
import '../../providers/app_state.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/product_bottom_sheet.dart';
import '../../widgets/product_card.dart';
import '../../widgets/toast_widget.dart';
import '../../features/customer/search/voice_search_widget.dart';
import '../../features/operations/services/location_service.dart';
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
const _supportPhoneUri = '+918248118563';

void _logNextFrame(String label, Stopwatch sw) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    debugPrint('[perf][$label][ui] ${sw.elapsedMilliseconds}ms');
  });
}

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

  Future<void> _openWhatsAppSupport() async {
    final uri = Uri.parse(
      'https://wa.me/$_supportPhoneUri?text=${Uri.encodeComponent('Hi Doormart, I need help with the app.')}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
                        onFavoriteToggle: (product) => _toggleFavoriteGuarded(
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
                      child: _SectionTitle('Shops near you'),
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
                      child: _NearbyShopsList(
                        sort: _popularSort,
                        selectedCategory: _popularSelectedCategory,
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
                  child: const IgnorePointer(child: WalkingMascotWidget()),
                ),
                Positioned(
                  right: 16,
                  bottom: 106 + bottomInset,
                  child: _WhatsAppFab(onTap: _openWhatsAppSupport),
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _PremiumCategorySheet(
        categories: categories.map((category) => category.name).toList(),
        selectedCategory: _selectedCategory,
        onApply: (category) {
          setState(() => _selectedCategory = category);
          Navigator.pop(sheetCtx);
        },
      ),
    );
  }

  void _showPopularFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _PremiumCategorySheet(
        title: 'Filter shops',
        subtitle: 'Choose how you want to browse nearby shops.',
        categories: const [
          'Open now',
          'Fastest delivery',
          'Lowest delivery fee',
        ],
        selectedCategory: _popularSelectedCategory,
        onApply: (category) {
          setState(() => _popularSelectedCategory = category);
          Navigator.pop(sheetCtx);
        },
      ),
    );
  }

  void _showPopularSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _PremiumSortSheet(
        selected: _popularSort,
        shopMode: true,
        onApply: (sort) {
          setState(() => _popularSort = sort);
          Navigator.pop(sheetCtx);
        },
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _PremiumSortSheet(
        selected: _sort,
        onApply: (sort) {
          setState(() => _sort = sort);
          Navigator.pop(sheetCtx);
        },
      ),
    );
  }
}

class _PremiumCategorySheet extends StatefulWidget {
  const _PremiumCategorySheet({
    required this.categories,
    required this.selectedCategory,
    required this.onApply,
    this.title = 'Filter products',
    this.subtitle = 'Choose a category to refine your essentials.',
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onApply;
  final String title;
  final String subtitle;

  @override
  State<_PremiumCategorySheet> createState() => _PremiumCategorySheetState();
}

class _PremiumCategorySheetState extends State<_PremiumCategorySheet> {
  late String _selected = widget.selectedCategory;

  @override
  Widget build(BuildContext context) {
    final options = ['All', ...widget.categories];
    return _PremiumSheetFrame(
      icon: Icons.tune_rounded,
      title: widget.title,
      subtitle: widget.subtitle,
      actionLabel: 'Apply Filters',
      onAction: () => widget.onApply(_selected),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final category in options)
            _PremiumCategoryOption(
              label: category,
              selected: _selected == category,
              onTap: () => setState(() => _selected = category),
            ),
        ],
      ),
    );
  }
}

class _PremiumCategoryOption extends StatelessWidget {
  const _PremiumCategoryOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: BoxConstraints(
          minHeight: 44,
          maxWidth: MediaQuery.sizeOf(context).width - 56,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _kGreenLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _kGreen : const Color(0xFFE8E2DD),
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _kGreen.withValues(alpha: 0.14),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 17,
              color: selected ? _kGreen : const Color(0xFFB7B0A6),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: selected ? _kGreen : _kTextDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumSortSheet extends StatefulWidget {
  const _PremiumSortSheet({
    required this.selected,
    required this.onApply,
    this.shopMode = false,
  });

  final _EssentialsSort selected;
  final ValueChanged<_EssentialsSort> onApply;
  final bool shopMode;

  @override
  State<_PremiumSortSheet> createState() => _PremiumSortSheetState();
}

class _PremiumSortSheetState extends State<_PremiumSortSheet> {
  late _EssentialsSort _selected = widget.selected;

  @override
  Widget build(BuildContext context) {
    final options = widget.shopMode
        ? [
            ('Distance', _EssentialsSort.relevance),
            ('Delivery fee: Low to High', _EssentialsSort.priceLowHigh),
            ('Fastest delivery', _EssentialsSort.priceHighLow),
            ('Rating: High to Low', _EssentialsSort.ratingHighLow),
            ('Name: A to Z', _EssentialsSort.nameAZ),
          ]
        : [
            ('Relevance', _EssentialsSort.relevance),
            ('Price: Low to High', _EssentialsSort.priceLowHigh),
            ('Price: High to Low', _EssentialsSort.priceHighLow),
            ('Rating: High to Low', _EssentialsSort.ratingHighLow),
            ('Name: A to Z', _EssentialsSort.nameAZ),
          ];

    return _PremiumSheetFrame(
      icon: Icons.swap_vert_rounded,
      title: widget.shopMode ? 'Sort shops' : 'Sort products',
      subtitle: widget.shopMode
          ? 'Choose how nearby shops should appear.'
          : 'Choose how products should appear on this page.',
      actionLabel: 'Apply Sort',
      onAction: () => widget.onApply(_selected),
      child: Column(
        children: [
          for (final option in options)
            _SortTile(
              label: option.$1,
              selected: _selected == option.$2,
              onTap: () => setState(() => _selected = option.$2),
            ),
        ],
      ),
    );
  }
}

class _PremiumSheetFrame extends StatelessWidget {
  const _PremiumSheetFrame({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFCFA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3D9D1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFEFE7), Color(0xFFFFD8C3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(icon, color: _kGreen, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: _kTextDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: _kTextMid,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              child,
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF26522), Color(0xFFE54518)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: [
                      BoxShadow(
                        color: _kGreen.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: FilledButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      actionLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.15,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
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

class _WhatsAppFab extends StatefulWidget {
  const _WhatsAppFab({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_WhatsAppFab> createState() => _WhatsAppFabState();
}

class _WhatsAppFabState extends State<_WhatsAppFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  late final Animation<double> _glow = CurvedAnimation(
    parent: _glowCtrl,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) {
        final t = _glow.value;
        return Transform.scale(
          scale: 1.0 + (t * 0.02),
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFF25D366,
                  ).withValues(alpha: 0.45 + (t * 0.35)),
                  blurRadius: 22 + (t * 14),
                  spreadRadius: 2 + (t * 3),
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                customBorder: const CircleBorder(),
                child: child,
              ),
            ),
          ),
        );
      },
      child: Image.asset(
        'assets/whatsapp_icon.png',
        width: 62,
        height: 62,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.chat_rounded, color: Colors.white, size: 34),
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
                  padding: const EdgeInsets.all(8),
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
                  child: Center(
                    child: Image.asset(
                      'assets/images/doormartLogo.jpeg',
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
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
                      b.logoUrl,
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

  final (String, String, String, Color, Color, String) banner;
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
              Positioned(
                top: 18,
                right: 18,
                child: _StoreLogoBadge(
                  logoUrl: banner.$6,
                  title: banner.$1,
                  tint: banner.$4,
                ),
              ),
              // Text content
              Positioned(
                left: 20,
                top: 20,
                bottom: 20,
                right: 110,
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

class _StoreLogoBadge extends StatelessWidget {
  const _StoreLogoBadge({
    required this.logoUrl,
    required this.title,
    required this.tint,
  });

  final String logoUrl;
  final String title;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final normalized = NetworkImageUrl.normalize(logoUrl);
    return Container(
      width: 54,
      height: 54,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: normalized.isNotEmpty && normalized != 'null'
            ? (normalized.startsWith('http')
                  ? Image.network(
                      normalized,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback(),
                    )
                  : Image.asset(
                      normalized,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback(),
                    ))
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return ColoredBox(
      color: Colors.white,
      child: Center(child: Icon(_bannerIconFor(title), color: tint, size: 26)),
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
    '',
  ),
  (
    'Daily Dairy',
    'Morning essentials delivered',
    'assets/images/banners/coupon_basket.png',
    Color(0xFF1565C0),
    Color(0xFF42A5F5),
    '',
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
        final products = _freshPickProducts(state.products);
        if (products.isEmpty) {
          return const _EmptyProductsCard(
            height: 352,
            icon: Icons.local_fire_department_rounded,
          );
        }
        return SizedBox(
          height: 352,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) => Selector<AppState, bool>(
              selector: (_, appState) => appState.isFavorite(products[i]),
              builder: (ctx, isFavorite, _) {
                return _AnimatedProductCard(
                  index: i,
                  child: SizedBox(
                    width: 168,
                    child: ProductCard(
                      product: products[i],
                      isFavorite: isFavorite,
                      imageFallbackBuilder: _funnyMissingImageFallback,
                      onFavoriteToggle: () {
                        final tapSw = Stopwatch()..start();
                        if (!state.signedIn) {
                          showToast(ctx, 'Please login first');
                          _logNextFrame('favorite:home', tapSw);
                          return;
                        }
                        state.toggleFavorite(products[i]).whenComplete(() {
                          _logNextFrame('favorite:home', tapSw);
                        });
                      },
                      onTap: () => showProductBottomSheet(
                        ctx,
                        products[i],
                        onAddToCart: (qty, variant) async {
                          final tapSw = Stopwatch()..start();
                          final ok = await state.addToCart(
                            products[i],
                            quantity: qty,
                            unit: variant.unit,
                            price: variant.price,
                            discountCost: variant.discountCost,
                            stock: variant.stock,
                          );
                          if (!ctx.mounted) return;
                          showToast(
                            ctx,
                            ok
                                ? '${products[i].name} added to cart'
                                : state.error ?? 'Please login first',
                          );
                          _logNextFrame('cart:home', tapSw);
                        },
                      ),
                      onAdd: () async {
                        final tapSw = Stopwatch()..start();
                        final ok = await state.addToCart(products[i]);
                        if (!ctx.mounted) return;
                        showToast(
                          ctx,
                          ok
                              ? '${products[i].name} added to cart'
                              : state.error ?? 'Please login first',
                        );
                        _logNextFrame('cart:home', tapSw);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

Widget _funnyMissingImageFallback(BuildContext context, ProductModel product) {
  final accent = _categoryAccent(product.category);

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
        Positioned(
          left: 14,
          bottom: 14,
          child: Icon(
            Icons.sentiment_satisfied_rounded,
            size: 18,
            color: accent.withValues(alpha: 0.55),
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
    _ => _kGreen,
  };
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
    required this.ratingSummary,
    required this.ratingLoading,
    this.imageFallbackBuilder,
  });

  final dynamic product;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onAdd;
  final VoidCallback? onTap;
  final _ReviewSummary ratingSummary;
  final bool ratingLoading;
  final Widget Function(BuildContext context, ProductModel product)?
  imageFallbackBuilder;

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
                        child: _HomeFeedImage(
                          imageUrl: product.imageUrl,
                          imageFallbackBuilder: imageFallbackBuilder,
                          product: product,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _HomeRatingChip(
                        summary: ratingSummary,
                        loading: ratingLoading,
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
  const _HomeRatingChip({required this.summary, required this.loading});

  final _ReviewSummary summary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(12),
      ),
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD54F)),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Color(0xFFFFD54F),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      summary.averageLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  summary.countLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }
}

class _ReviewSummary {
  const _ReviewSummary({required this.average, required this.count});

  final double average;
  final int count;

  String get averageLabel =>
      average > 0 ? average.toStringAsFixed(1) : 'No rating';

  String get countLabel {
    if (count <= 0) return 'Customer reviews';
    return '$count review${count == 1 ? '' : 's'}';
  }
}

_ReviewSummary _reviewSummaryFor(
  ProductModel product,
  List<ProductReviewModel> reviews,
) {
  if (reviews.isNotEmpty) {
    final average =
        reviews.fold<double>(0, (sum, review) => sum + review.rating) /
        reviews.length;
    return _ReviewSummary(average: average, count: reviews.length);
  }

  return _ReviewSummary(average: product.rating, count: product.ratingCount);
}

class _HomeFeedImage extends StatelessWidget {
  const _HomeFeedImage({
    required this.imageUrl,
    required this.product,
    this.imageFallbackBuilder,
  });
  final String imageUrl;
  final ProductModel product;
  final Widget Function(BuildContext context, ProductModel product)?
  imageFallbackBuilder;

  @override
  Widget build(BuildContext context) {
    final normalized = NetworkImageUrl.normalize(imageUrl);
    final fallbackBuilder = imageFallbackBuilder;
    debugPrint('Cloudinary Image URL (home feed): $normalized');
    Widget child;
    if (normalized.startsWith('assets/')) {
      child = Image.asset(
        normalized,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Image Load Error (home feed asset): $error');
          if (fallbackBuilder != null) {
            return fallbackBuilder(context, product);
          }
          return const Center(
            child: Icon(Icons.broken_image_outlined, color: Color(0xFF64748B)),
          );
        },
      );
    } else if (normalized.startsWith('http')) {
      child = Image.network(
        normalized,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Image Load Error (home feed): $error');
          if (fallbackBuilder != null) {
            return fallbackBuilder(context, product);
          }
          return const Center(
            child: Icon(Icons.broken_image_outlined, color: Color(0xFF64748B)),
          );
        },
      );
    } else {
      if (fallbackBuilder != null) {
        child = fallbackBuilder(context, product);
      } else {
        child = Image.asset(
          imageUrl.toLowerCase().contains('banner')
              ? 'assets/images/banners/grocery_bag.png'
              : 'assets/images/products/tomato.png',
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
      }
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
        var products = _sectionProducts(state.products, 'daily_essentials');
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
            child: _EmptyProductsCard(
              height: 220,
              icon: Icons.local_fire_department_rounded,
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 600 ? 3 : 2;
            const spacing = 14.0;
            final cardWidth =
                (constraints.maxWidth - (columns - 1) * spacing) / columns;
            final cardHeight = (cardWidth * 1.72).clamp(270.0, 348.0);

            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                mainAxisExtent: cardHeight,
              ),
              itemBuilder: (ctx, i) {
                final product = products[i];
                return Selector<AppState, bool>(
                  selector: (_, appState) => appState.isFavorite(product),
                  builder: (ctx, isFavorite, _) {
                    return _PopularStyleProductCard(
                      product: product,
                      isFavorite: isFavorite,
                      imageFallbackBuilder: _funnyMissingImageFallback,
                      onFavoriteToggle: () => onFavoriteToggle(product),
                      onTap: () => showProductBottomSheet(
                        ctx,
                        product,
                        onAddToCart: (qty, variant) async {
                          final tapSw = Stopwatch()..start();
                          final ok = await state.addToCart(
                            product,
                            quantity: qty,
                            unit: variant.unit,
                            price: variant.price,
                            discountCost: variant.discountCost,
                            stock: variant.stock,
                          );
                          if (!ctx.mounted) return;
                          showToast(
                            ctx,
                            ok
                                ? '${product.name} added to cart'
                                : state.error ?? 'Please login first',
                          );
                          _logNextFrame('cart:popular', tapSw);
                        },
                      ),
                      onAdd: () async {
                        final tapSw = Stopwatch()..start();
                        final ok = await state.addToCart(product);
                        if (!ctx.mounted) return;
                        showToast(
                          ctx,
                          ok
                              ? '${product.name} added to cart'
                              : state.error ?? 'Please login first',
                        );
                        _logNextFrame('cart:popular', tapSw);
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _NearbyShop {
  _NearbyShop({
    required this.id,
    required this.name,
    required this.city,
    required this.logo,
    required this.productCount,
    required this.rating,
    required this.etaMinutes,
    required this.deliveryFee,
    this.distanceKm,
  });
  final String id;
  final String name;
  final String city;
  final String logo;
  int productCount;
  final double rating;
  final int etaMinutes;
  final double deliveryFee;
  final double? distanceKm;

  factory _NearbyShop.fromVendor(Map<String, dynamic> json) {
    return _NearbyShop(
      id: json['vendorId']?.toString() ?? '',
      name: json['name']?.toString().trim().isNotEmpty == true
          ? json['name'].toString()
          : 'Local grocery shop',
      city: json['city']?.toString().trim().isNotEmpty == true
          ? json['city'].toString()
          : 'Nearby',
      logo: json['logoUrl']?.toString() ?? '',
      productCount: 0,
      rating: 4.5,
      etaMinutes: 25,
      deliveryFee: 30,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }

  factory _NearbyShop.fromProducts(String id, List<ProductModel> products) {
    final first = products.first;
    final ratings = products
        .where((p) => p.rating > 0)
        .map((p) => p.rating)
        .toList();
    final rating = ratings.isEmpty
        ? 4.5
        : ratings.reduce((a, b) => a + b) / ratings.length;
    return _NearbyShop(
      id: id,
      name: first.supplierName.trim().isNotEmpty
          ? first.supplierName.trim()
          : (id == 'main' ? 'Doormart Fresh' : 'Local grocery shop'),
      city: first.supplierCity.trim().isNotEmpty
          ? first.supplierCity.trim()
          : 'Nearby',
      logo: first.supplierLogo,
      productCount: products.length,
      rating: rating,
      etaMinutes: id == 'main' ? 25 : 30,
      deliveryFee: id == 'main' ? 30 : 30,
      distanceKm: null,
    );
  }
}

class _NearbyShopCard extends StatelessWidget {
  const _NearbyShopCard({required this.shop});
  final _NearbyShop shop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: shop.logo.isNotEmpty
                ? Image.network(
                    shop.logo,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _shopIcon(),
                  )
                : _shopIcon(),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _kTextDark,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Open now · ${shop.distanceKm != null ? '${shop.distanceKm!.toStringAsFixed(1)} km · ' : ''}${shop.city}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kTextMid,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: Color(0xFFF5A623),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      shop.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      '${shop.etaMinutes}–${shop.etaMinutes + 5} min',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _kTextMid,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      '${shop.productCount} items',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _kTextMid,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Delivery ₹${shop.deliveryFee.toStringAsFixed(0)} · Min order ₹199',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kTextDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: _kGreen, size: 24),
        ],
      ),
    );
  }

  Widget _shopIcon() => Container(
    width: 72,
    height: 72,
    color: _kGreenLight,
    child: const Icon(Icons.storefront_rounded, color: _kGreen, size: 34),
  );
}

class _PopularStyleProductCard extends StatelessWidget {
  const _PopularStyleProductCard({
    required this.product,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onAdd,
    required this.onTap,
    this.imageFallbackBuilder,
  });

  final ProductModel product;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onAdd;
  final VoidCallback? onTap;
  final Widget Function(BuildContext context, ProductModel product)?
  imageFallbackBuilder;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
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
                    child: _HomeFeedImage(
                      imageUrl: product.imageUrl,
                      product: product,
                      imageFallbackBuilder: imageFallbackBuilder,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _EssentialsRatingBadge(rating: product.rating),
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
                padding: EdgeInsets.fromLTRB(
                  compact ? 9 : 12,
                  compact ? 7 : 8,
                  compact ? 9 : 12,
                  compact ? 8 : 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 14 : 16,
                        fontWeight: FontWeight.w800,
                        color: _kTextDark,
                        height: 1.25,
                      ),
                    ),
                    Text(
                      '${product.category} • ${_unitLabel(product.unit)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 10.5 : 12,
                        color: _kTextMid,
                      ),
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: FittedBox(
                            alignment: Alignment.centerLeft,
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '₹ ${product.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: compact ? 14 : 15,
                                fontWeight: FontWeight.w900,
                                color: _kTextDark,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '₹ ${_mrpValue(product).toStringAsFixed(0)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: compact ? 10.5 : 12,
                              fontWeight: FontWeight.w700,
                              color: _kTextMid,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: _kTextMid,
                              decorationThickness: 1.6,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${product.stock > 20 ? 10 : 18} min',
                          style: TextStyle(
                            fontSize: compact ? 8 : 9,
                            fontWeight: FontWeight.w700,
                            color: _kTextMid,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: compact ? 34 : 38,
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
                        child: Text(
                          'Add to Cart',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: compact ? 11 : 12,
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

class _EssentialsRatingBadge extends StatelessWidget {
  const _EssentialsRatingBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFD54F)),
          const SizedBox(width: 3),
          Text(
            rating > 0 ? rating.toStringAsFixed(1) : 'New',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
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

double _mrpValue(ProductModel product) {
  final mrp = product.mrp;
  if (mrp > 0) return mrp;
  return product.price * 1.12;
}

List<ProductModel> _sectionProducts(
  List<ProductModel> products,
  String section,
) {
  final scoped = products
      .where((product) => product.dashboardSection == section)
      .toList();
  return scoped.isNotEmpty ? scoped : List<ProductModel>.from(products);
}

List<ProductModel> _freshPickProducts(List<ProductModel> products) {
  return products
      .where((product) => product.dashboardSection == 'fresh_picks')
      .toList();
}

class _EmptyProductsCard extends StatelessWidget {
  const _EmptyProductsCard({required this.height, required this.icon});

  final double height;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: _kGreenLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: _kGreen),
              ),
              const SizedBox(height: 12),
              const Text(
                'No fresh picks yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: _kTextDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Vendors can mark products as fresh picks while adding them.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kTextMid,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
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
            return FutureBuilder<List<ProductReviewModel>>(
              future: state.loadProductReviews(product.id),
              builder: (context, snapshot) {
                final reviews = snapshot.data ?? const <ProductReviewModel>[];
                final summary = _reviewSummaryFor(product, reviews);
                return _HomeFeedCard(
                  product: product,
                  isFavorite: state.isFavorite(product),
                  imageFallbackBuilder: _funnyMissingImageFallback,
                  ratingSummary: summary,
                  ratingLoading:
                      snapshot.connectionState == ConnectionState.waiting &&
                      reviews.isEmpty,
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
                    onAddToCart: (qty, variant) async {
                      final ok = await state.addToCart(
                        product,
                        quantity: qty,
                        unit: variant.unit,
                        price: variant.price,
                        discountCost: variant.discountCost,
                        stock: variant.stock,
                      );
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
                border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
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

class _NearbyShopsList extends StatefulWidget {
  const _NearbyShopsList({
    required this.sort,
    required this.selectedCategory,
  });
  final _EssentialsSort sort;
  final String selectedCategory;

  @override
  State<_NearbyShopsList> createState() => _NearbyShopsListState();
}

class _NearbyShopsListState extends State<_NearbyShopsList> {
  List<_NearbyShop> _shops = const [];
  bool _loading = true;
  bool _locationUnavailable = false;

  @override
  void initState() {
    super.initState();
    _loadNearbyShops();
  }

  Future<void> _loadNearbyShops() async {
    try {
      final location = await LocationService().currentLocation();
      final state = context.read<AppState>();
      final response = await state.apiService.get(
        '/vendors/nearby?latitude=${location.latitude}&longitude=${location.longitude}&radiusKm=25',
        token: state.token,
      );
      final vendors = response is List ? response : const [];
      if (!mounted) return;
      setState(() {
        _shops = vendors.whereType<Map<String, dynamic>>().map(_NearbyShop.fromVendor).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationUnavailable = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Center(child: CircularProgressIndicator(color: _kGreen)),
      );
    }
    if (_locationUnavailable) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Text('Allow location access to see shops near you.', style: TextStyle(color: _kTextMid, fontWeight: FontWeight.w600)),
      );
    }
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        final shops = [..._shops];
        final products = _sectionProducts(state.products, 'popular_products');
        for (final shop in shops) {
          shop.productCount = products.where((product) => product.vendorId == shop.id).length;
        }
        if (shops.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _EmptyProductsCard(height: 220, icon: Icons.storefront_rounded),
          );
        }
        if (widget.selectedCategory == 'Fastest delivery') {
          shops.removeWhere((shop) => shop.etaMinutes > 25);
        } else if (widget.selectedCategory == 'Lowest delivery fee' && shops.isNotEmpty) {
          final lowestFee = shops.map((shop) => shop.deliveryFee).reduce((a, b) => a < b ? a : b);
          shops.removeWhere((shop) => shop.deliveryFee != lowestFee);
        }
        if (shops.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _EmptyProductsCard(
              height: 220,
              icon: Icons.local_fire_department_rounded,
            ),
          );
        }
        if (widget.sort == _EssentialsSort.ratingHighLow)
          shops.sort((a, b) => b.rating.compareTo(a.rating));
        if (widget.sort == _EssentialsSort.priceLowHigh)
          shops.sort((a, b) => a.deliveryFee.compareTo(b.deliveryFee));
        if (widget.sort == _EssentialsSort.priceHighLow)
          shops.sort((a, b) => a.etaMinutes.compareTo(b.etaMinutes));
        if (widget.sort == _EssentialsSort.nameAZ)
          shops.sort((a, b) => a.name.compareTo(b.name));
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: shops.length,
          separatorBuilder: (_, __) => const SizedBox(height: 18),
          itemBuilder: (ctx, i) {
            return _NearbyShopCard(shop: shops[i]);
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
          constraints: const BoxConstraints(minWidth: 104, minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.active
                      ? _kGreen.withValues(alpha: 0.16)
                      : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(widget.icon, size: 15, color: _kGreen),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: _kGreen,
                  letterSpacing: 0.1,
                ),
              ),
              if (widget.active) ...[
                const SizedBox(width: 7),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 15,
                  color: _kGreen,
                ),
              ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? _kGreenLight : const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? _kGreen.withValues(alpha: 0.45) : _kBorder,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: _kGreen.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: selected ? _kGreen : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? _kGreen : const Color(0xFFD6D6D6),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.sort_rounded,
                      size: 15,
                      color: selected ? Colors.white : _kTextMid,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: selected ? _kGreen : _kTextDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected ? _kGreen : const Color(0xFFB7B0A6),
                  size: 21,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
