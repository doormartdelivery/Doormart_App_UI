import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/product_model.dart';
import '../../models/vendor_model.dart';
import '../../providers/app_state.dart';
import '../app_page.dart';
import 'admin_logout_confirm.dart';
import 'admin_dashboard_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_orders_screen.dart';
import 'manage_banners_screen.dart';
import 'manage_categories_screen.dart';
import 'manage_delivery_screen.dart';
import 'manage_users_screen.dart';
import 'admin_sidebar_drawer.dart';
import 'stock_screen.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});
  static const routeName = '/admin/products';

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  String _query = '';
  Future<List<VendorModel>>? _vendorsFuture;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final state = context.read<AppState>();
      await Future.wait([state.loadProducts(), state.loadCategories()]);
      if (!mounted) return;
      if (state.user?.role == UserRoles.superAdmin) {
        _vendorsFuture = state.adminVendors();
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _sortBy(int columnIndex) {
    setState(() {
      if (_sortColumnIndex == columnIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = columnIndex;
        _sortAscending = true;
      }
    });
  }

  List<ProductModel> _filteredProducts(List<ProductModel> products) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return products;
    return products.where((p) {
      final variantText = p.unitVariants
          .map((variant) => variant.unit)
          .join(' ');
      return p.name.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query) ||
          p.unit.toLowerCase().contains(query) ||
          variantText.toLowerCase().contains(query) ||
          p.stock.toString().contains(query) ||
          p.price.toStringAsFixed(0).contains(query);
    }).toList();
  }

  List<ProductModel> _sortedProducts(
    List<ProductModel> products, {
    required bool showVendorColumn,
  }) {
    final sorted = [...products];
    final categoryIndex = showVendorColumn ? 2 : 1;
    final stockIndex = showVendorColumn ? 3 : 2;
    final mrpIndex = showVendorColumn ? 4 : 3;
    final priceIndex = showVendorColumn ? 5 : 4;
    double mrpValue(ProductModel product) =>
        product.mrp > 0 ? product.mrp : product.cost;
    int compare(ProductModel a, ProductModel b) {
      if (_sortColumnIndex == 0) {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      if (_sortColumnIndex == categoryIndex) {
        return a.category.toLowerCase().compareTo(b.category.toLowerCase());
      }
      if (_sortColumnIndex == stockIndex) {
        return a.stock.compareTo(b.stock);
      }
      if (_sortColumnIndex == mrpIndex) {
        return mrpValue(a).compareTo(mrpValue(b));
      }
      if (_sortColumnIndex == priceIndex) {
        return a.price.compareTo(b.price);
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    }

    sorted.sort((a, b) => _sortAscending ? compare(a, b) : -compare(a, b));
    return sorted;
  }

  Future<void> _openAddProductForm() async {
    final added = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ProductDialog(),
    );
    if (!mounted || added != true) return;
    _showSnack('Product added successfully');
    setState(() {}); // force list refresh
  }

  Future<void> _openEditProductForm(ProductModel product) async {
    final updated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProductDialog(product: product),
    );
    if (!mounted || updated != true) return;
    _showSnack('Product updated successfully');
    setState(() {});
  }

  Future<void> _openViewProductDetails(
    ProductModel product, {
    String vendorName = 'Main store',
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) =>
          _ProductDetailsDialog(product: product, vendorName: vendorName),
    );
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteDialog(name: product.name),
    );
    if (confirmed != true || !mounted) return;
    await context.read<AppState>().deleteProduct(product.id);
    if (!mounted) return;
    _showSnack('${product.name} deleted');
    setState(() {});
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFE8541A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = context.read<AppState>().user?.role;
    final isVendor = role == UserRoles.vendor;
    final isSuperAdmin = role == UserRoles.superAdmin;
    return AppPage(
      title: isSuperAdmin
          ? 'Super admin products'
          : isVendor
          ? 'Vendor products'
          : 'Manage products',
      scaffoldKey: _scaffoldKey,
      drawer: AdminSidebarDrawer(
        currentRoute: ManageProductsScreen.routeName,
        onLogout: () async {
          if (!await confirmAdminLogout(context)) return;
          Navigator.pop(context);
          final logoutRoute = context.read<AppState>().logoutRouteName;
          await context.read<AppState>().logout();
          if (!context.mounted) return;
          Navigator.pushNamedAndRemoveUntil(context, logoutRoute, (_) => false);
        },
      ),
      leading: Builder(
        builder: (ctx) => Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton.filledTonal(
            tooltip: 'Menu',
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFFFF0EB),
              foregroundColor: const Color(0xFFE8541A),
            ),
            icon: const Icon(Icons.menu),
          ),
        ),
      ),
      children: [
        Consumer<AppState>(
          builder: (ctx, state, _) {
            final allProducts = _sortedProducts(
              state.products,
              showVendorColumn: isSuperAdmin,
            );
            final products = _filteredProducts(allProducts);

            if (state.loading && products.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (state.error != null && products.isEmpty) {
              return _ErrorCard(message: state.error!);
            }
            if (products.isEmpty && _query.isEmpty) {
              return _EmptyState(onAdd: _openAddProductForm);
            }

            if (!isSuperAdmin) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroCard(
                    products: allProducts,
                    onAdd: _openAddProductForm,
                    isVendor: isVendor,
                  ),
                  const SizedBox(height: 14),
                  _SearchField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    onClear: _query.isEmpty
                        ? null
                        : () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                  ),
                  const SizedBox(height: 14),
                  if (products.isEmpty)
                    const _NothingFound()
                  else
                    _ProductsTable(
                      products: products,
                      sortColumnIndex: _sortColumnIndex,
                      sortAscending: _sortAscending,
                      onSort: _sortBy,
                      onEdit: _openEditProductForm,
                      onDelete: _deleteProduct,
                      onView: (product) => _openViewProductDetails(product),
                      showVendorColumn: false,
                      resolveVendorName: _resolveVendorName,
                    ),
                ],
              );
            }

            return FutureBuilder<List<VendorModel>>(
              future: _vendorsFuture ?? state.adminVendors(),
              builder: (context, vendorSnapshot) {
                final vendors = vendorSnapshot.data ?? const <VendorModel>[];
                String resolveVendorName(String vendorId) =>
                    _resolveVendorName(vendorId, vendors);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroCard(
                      products: allProducts,
                      onAdd: _openAddProductForm,
                      isVendor: isVendor,
                    ),
                    const SizedBox(height: 14),
                    _SearchField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      onClear: _query.isEmpty
                          ? null
                          : () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                    ),
                    const SizedBox(height: 14),
                    if (vendorSnapshot.connectionState ==
                            ConnectionState.waiting &&
                        vendors.isEmpty &&
                        products.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (products.isEmpty)
                      const _NothingFound()
                    else
                      _ProductsTable(
                        products: products,
                        sortColumnIndex: _sortColumnIndex,
                        sortAscending: _sortAscending,
                        onSort: _sortBy,
                        onEdit: _openEditProductForm,
                        onDelete: _deleteProduct,
                        onView: (product) => _openViewProductDetails(
                          product,
                          vendorName: resolveVendorName(product.vendorId),
                        ),
                        showVendorColumn: true,
                        resolveVendorName: resolveVendorName,
                      ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

// ─── Delete Dialog ────────────────────────────────────────────────────────────

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: const Icon(
        Icons.delete_outline_rounded,
        color: Color(0xFFDC2626),
        size: 44,
      ),
      title: const Text(
        'Delete product',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      content: Text(
        'Remove "$name" from the product table?',
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

// ─── Admin Drawer ─────────────────────────────────────────────────────────────

class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer({required this.onNavigate, required this.onLogout});
  final void Function(String) onNavigate;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin =
        context.read<AppState>().user?.role == UserRoles.superAdmin;
    final items = [
      ('Overview', Icons.dashboard_rounded, AdminDashboardScreen.routeName),
      ('Orders', Icons.receipt_long_rounded, AdminOrdersScreen.routeName),
      if (isSuperAdmin)
        (
          'Notifications',
          Icons.notifications_active_rounded,
          AdminNotificationsScreen.routeName,
        ),
      ('Products', Icons.inventory_2_rounded, ManageProductsScreen.routeName),
      if (isSuperAdmin)
        (
          'Categories',
          Icons.category_rounded,
          ManageCategoriesScreen.routeName,
        ),
      if (isSuperAdmin)
        ('Banners', Icons.slideshow_rounded, ManageBannersScreen.routeName),
      if (isSuperAdmin)
        ('Users', Icons.groups_rounded, ManageUsersScreen.routeName),
      if (isSuperAdmin)
        (
          'Delivery partners',
          Icons.delivery_dining_rounded,
          ManageDeliveryScreen.routeName,
        ),
      ('Stock alerts', Icons.warning_amber_rounded, StockScreen.routeName),
    ];

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFFFFF0EB),
                    child: Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Color(0xFFE8541A),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin menu',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Control centre',
                          style: TextStyle(
                            color: Color(0xFF9E9E9E),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE7E7E7)),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final item = items[i];
                  final sel = item.$3 == ManageProductsScreen.routeName;
                  return Material(
                    color: sel ? const Color(0xFFFFF0EB) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => onNavigate(item.$3),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFE8541A,
                                ).withValues(alpha: sel ? 0.18 : 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                item.$2,
                                color: sel
                                    ? const Color(0xFFE8541A)
                                    : const Color(0xFF555555),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.$1,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: sel
                                      ? const Color(0xFFE8541A)
                                      : const Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: sel
                                  ? const Color(0xFFE8541A)
                                  : const Color(0xFFCCCCCC),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onLogout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE8541A),
                    side: const BorderSide(color: Color(0xFFE8541A)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFFFFF0EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text(
                    'Logout',
                    style: TextStyle(fontWeight: FontWeight.w800),
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

// ─── Hero Card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.products,
    required this.onAdd,
    required this.isVendor,
  });
  final List<ProductModel> products;
  final VoidCallback onAdd;
  final bool isVendor;

  @override
  Widget build(BuildContext context) {
    final lowStock = products.where((p) => p.stock <= 10).length;
    final categories = products.map((p) => p.category).toSet().length;
    final inventoryValue = products.fold<double>(
      0,
      (sum, product) => sum + _originalPriceValue(product) * product.stock,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Color(0xFFE8541A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isVendor ? 'Vendor inventory' : 'Product inventory',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE8541A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  isVendor ? 'Add Product' : 'Add Product',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Metric(
                '${products.length}',
                isVendor ? 'Your products' : 'Products',
                Icons.widgets_rounded,
                const Color(0xFFE8541A),
                const Color(0xFFFFF0EB),
              ),
              _Metric(
                '$categories',
                'Categories',
                Icons.category_rounded,
                const Color(0xFF2563EB),
                const Color(0xFFEFF6FF),
              ),
              _Metric(
                '$lowStock',
                'Low stock',
                Icons.warning_amber_rounded,
                const Color(0xFFB45309),
                const Color(0xFFFFF7ED),
              ),
              _Metric(
                'Rs ${inventoryValue.toStringAsFixed(0)}',
                'Stock value',
                Icons.payments_rounded,
                const Color(0xFFBE185D),
                const Color(0xFFFCE7F3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.value, this.label, this.icon, this.color, this.tint);
  final String value, label;
  final IconData icon;
  final Color color, tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Search Field ─────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search by name, category, unit, stock or price…',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: onClear == null
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: onClear,
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE8541A), width: 1.5),
        ),
      ),
    );
  }
}

// ─── Products Table ───────────────────────────────────────────────────────────

class _ProductsTable extends StatelessWidget {
  const _ProductsTable({
    required this.products,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
    required this.showVendorColumn,
    required this.resolveVendorName,
  });

  final List<ProductModel> products;
  final int sortColumnIndex;
  final bool sortAscending;
  final ValueChanged<int> onSort;
  final ValueChanged<ProductModel> onEdit;
  final ValueChanged<ProductModel> onDelete;
  final Future<void> Function(ProductModel product) onView;
  final bool showVendorColumn;
  final String Function(String vendorId) resolveVendorName;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: LayoutBuilder(
          builder: (_, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                sortColumnIndex: sortColumnIndex,
                sortAscending: sortAscending,
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFFFF5EF),
                ),
                headingTextStyle: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                ),
                dataTextStyle: const TextStyle(
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w600,
                ),
                dataRowMinHeight: 68,
                dataRowMaxHeight: 80,
                columnSpacing: 24,
                horizontalMargin: 16,
                columns: [
                  DataColumn(
                    label: const Text('Product'),
                    onSort: (_, __) => onSort(0),
                  ),
                  if (showVendorColumn) const DataColumn(label: Text('Vendor')),
                  DataColumn(
                    label: const Text('Category'),
                    onSort: (_, __) => onSort(showVendorColumn ? 2 : 1),
                  ),
                  DataColumn(
                    label: const Text('Stock'),
                    numeric: true,
                    onSort: (_, __) => onSort(showVendorColumn ? 3 : 2),
                  ),
                  DataColumn(
                    label: const Text('MRP'),
                    numeric: true,
                    onSort: (_, __) => onSort(showVendorColumn ? 4 : 3),
                  ),
                  DataColumn(
                    label: const Text('Original Price'),
                    numeric: true,
                    onSort: (_, __) => onSort(showVendorColumn ? 5 : 4),
                  ),
                  const DataColumn(label: Text('Unit')),
                  const DataColumn(label: Text('Actions')),
                ],
                rows: products.asMap().entries.map((e) {
                  final i = e.key;
                  final p = e.value;
                  return DataRow(
                    color: WidgetStateProperty.resolveWith((s) {
                      if (s.contains(WidgetState.hovered)) {
                        return const Color(0xFFFFF5EF);
                      }
                      return i.isEven ? Colors.white : const Color(0xFFF8FAFC);
                    }),
                    cells: [
                      DataCell(_ProductNameCell(product: p)),
                      if (showVendorColumn)
                        DataCell(
                          _VendorBadge(
                            vendorName: resolveVendorName(p.vendorId),
                          ),
                        ),
                      DataCell(_CategoryBadge(category: p.category)),
                      DataCell(_StockBadge(stock: p.stock)),
                      DataCell(
                        Text(
                          'Rs ${(p.mrp > 0 ? p.mrp : p.cost).toStringAsFixed(0)}',
                        ),
                      ),
                      DataCell(
                        Text(
                          'Rs ${p.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color(0xFF0F766E),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      DataCell(_UnitListCell(product: p)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFE8541A),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                              ),
                              onPressed: () => onView(p),
                              icon: const Icon(
                                Icons.visibility_rounded,
                                size: 18,
                              ),
                              label: const Text('View'),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit_rounded, size: 20),
                              onPressed: () => onEdit(p),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: Color(0xFFDC2626),
                              ),
                              onPressed: () => onDelete(p),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VendorBadge extends StatelessWidget {
  const _VendorBadge({required this.vendorName});
  final String vendorName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8541A).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        vendorName,
        style: const TextStyle(
          color: Color(0xFFE8541A),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProductNameCell extends StatelessWidget {
  const _ProductNameCell({required this.product});
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(product.category);
    return Row(
      children: [
        // Product image thumbnail or icon
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 42,
            height: 42,
            child: product.imageUrl.startsWith('http')
                ? Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _ProductIconFallback(color: color),
                  )
                : _ProductIconFallback(color: color),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 160,
          child: Text(
            product.name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductIconFallback extends StatelessWidget {
  const _ProductIconFallback({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.12),
      child: Icon(Icons.inventory_rounded, color: color, size: 22),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.stock});
  final int stock;

  @override
  Widget build(BuildContext context) {
    final color = stock <= 10
        ? const Color(0xFFDC2626)
        : stock <= 40
        ? const Color(0xFFB45309)
        : const Color(0xFF16A34A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$stock',
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _ProductDetailsDialog extends StatelessWidget {
  const _ProductDetailsDialog({
    required this.product,
    this.vendorName = 'Main store',
  });

  final ProductModel product;
  final String vendorName;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl.trim();
    final hasImage = imageUrl.startsWith('http');
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0EB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.visibility_rounded,
              color: Color(0xFFE8541A),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Product details',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: hasImage
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const _ImagePlaceholder(),
                        )
                      : const _ImagePlaceholder(),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _InfoPill(
                    label: 'Product ID',
                    value: _formatProductDisplayId(product.id),
                  ),
                  _InfoPill(label: 'Vendor', value: vendorName),
                  _InfoPill(
                    label: 'Vendor ID',
                    value: _formatVendorDisplayId(product.vendorId, null),
                  ),
                  _InfoPill(label: 'Category', value: product.category),
                  _InfoPill(label: 'Stock', value: '${product.stock}'),
                  _InfoPill(
                    label: 'MRP',
                    value:
                        'Rs ${(product.mrp > 0 ? product.mrp : product.cost)}',
                  ),
                  _InfoPill(
                    label: 'Original Price',
                    value: 'Rs ${product.price}',
                  ),
                  _InfoPill(label: 'Units', value: _unitSummary(product)),
                  _InfoPill(
                    label: 'Customer rating',
                    value: product.ratingCount > 0
                        ? '${product.rating.toStringAsFixed(1)} (${product.ratingCount})'
                        : 'No customer ratings yet',
                  ),
                  _InfoPill(
                    label: 'Section',
                    value: _sectionLabel(product.dashboardSection),
                  ),
                ],
              ),
              if (product.unitVariants.isNotEmpty) ...[
                const SizedBox(height: 18),
                const Text(
                  'Unit breakdown',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: product.unitVariants
                      .asMap()
                      .entries
                      .map(
                        (entry) => _UnitVariantChip(
                          label: _variantUnitLabel(entry.value.unit),
                          value: _variantSummary(entry.value),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 18),
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  product.description.trim().isEmpty
                      ? 'No description provided'
                      : product.description,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE8541A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 170),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

String _resolveVendorName(
  String vendorId, [
  List<VendorModel> vendors = const [],
]) {
  final value = vendorId.trim();
  if (value.isEmpty || value == 'main') {
    return 'Main store';
  }
  for (final vendor in vendors) {
    if (vendor.vendorId == value || vendor.id == value) {
      final name = vendor.name.trim();
      return name.isEmpty ? value : name;
    }
  }
  return value;
}

String _sectionLabel(String section) {
  switch (section) {
    case 'fresh_picks':
      return 'Fresh picks';
    case 'daily_essentials':
      return 'Daily essentials';
    case 'popular_products':
      return 'Popular products';
    default:
      return section;
  }
}

double _originalPriceValue(ProductModel product) => product.price;

String _formatProductDisplayId(String? productId) {
  final normalized = (productId ?? '').trim();
  final upper = normalized.toUpperCase();
  if (upper.startsWith('DMD-PROD-')) return upper;

  final source = normalized.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  if (source.isEmpty) return 'DMD-PROD-0000';
  final suffix = source.length >= 4
      ? source.substring(source.length - 4)
      : source.padLeft(4, '0');
  return 'DMD-PROD-${suffix.toUpperCase()}';
}

String _formatVendorDisplayId(String? vendorId, String? id) {
  final normalized = (vendorId ?? '').trim();
  final upper = normalized.toUpperCase();
  if (upper.startsWith('DMD-VENDOR-')) return upper;

  final source = (id ?? normalized).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  if (source.isEmpty) return 'DMD-VENDOR-0000';
  final suffix = source.length >= 4
      ? source.substring(source.length - 4)
      : source.padLeft(4, '0');
  return 'DMD-VENDOR-${suffix.toUpperCase()}';
}

String _unitSummary(ProductModel product) {
  final variants = product.unitVariants;
  if (variants.isEmpty) {
    final unit = product.unit.trim();
    return unit.isEmpty ? 'item' : unit;
  }
  final labels = variants
      .map((variant) => _variantUnitLabel(variant.unit))
      .where((label) => label.trim().isNotEmpty)
      .toList();
  if (labels.isEmpty) return 'item';
  if (labels.length <= 3) return labels.join(', ');
  return '${labels.take(2).join(', ')} + ${labels.length - 2} more';
}

List<String> _unitLabels(ProductModel product) {
  final variants = product.unitVariants;
  if (variants.isEmpty) {
    final unit = product.unit.trim();
    return [unit.isEmpty ? 'item' : _variantUnitLabel(unit)];
  }
  return variants
      .map((variant) => _variantUnitLabel(variant.unit))
      .where((label) => label.trim().isNotEmpty)
      .toList();
}

String _variantSummary(ProductUnitVariant variant) {
  final unit = variant.unit.trim().isEmpty ? 'item' : variant.unit.trim();
  return '$unit • Rs ${variant.price.toStringAsFixed(0)} • Discount Rs ${variant.discountCost.toStringAsFixed(0)} • Stock ${variant.stock}';
}

String _variantUnitLabel(String unit) {
  final value = unit.trim();
  if (value.isEmpty) return 'item';
  if (RegExp(r'^\d').hasMatch(value)) return value;
  return '1 $value';
}

class _UnitVariantChip extends StatelessWidget {
  const _UnitVariantChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1D2C2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9E6B52),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitListCell extends StatelessWidget {
  const _UnitListCell({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final labels = _unitLabels(product);
    if (labels.isEmpty) {
      return const Text('item');
    }

    return SizedBox(
      width: 210,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: labels.map((label) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7F2),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFF1D2C2)),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFFE8541A),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ReadOnlyNotice extends StatelessWidget {
  const _ReadOnlyNotice({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0EB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFE8541A), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    height: 1.45,
                    fontSize: 12,
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

// ─── Product Dialog ───────────────────────────────────────────────────────────
// KEY FIX: imageUrl is now optional — product can be saved without an image.
// Upload errors are shown inline but do NOT block save.

class _ProductDialog extends StatefulWidget {
  const _ProductDialog({this.product});
  final ProductModel? product;

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _UnitVariantDraft {
  _UnitVariantDraft({
    String unit = '',
    String price = '',
    String discountCost = '',
    String stock = '',
  }) : unitCtrl = TextEditingController(text: unit),
       priceCtrl = TextEditingController(text: price),
       discountCostCtrl = TextEditingController(text: discountCost),
       stockCtrl = TextEditingController(text: stock);

  final TextEditingController unitCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController discountCostCtrl;
  final TextEditingController stockCtrl;

  void dispose() {
    unitCtrl.dispose();
    priceCtrl.dispose();
    discountCostCtrl.dispose();
    stockCtrl.dispose();
  }

  Map<String, dynamic> toJson() => {
    'unit': unitCtrl.text.trim(),
    'price': double.parse(priceCtrl.text.trim()),
    'discountCost': double.parse(discountCostCtrl.text.trim()),
    'stock': int.parse(stockCtrl.text.trim()),
  };
}

class _ProductDialogState extends State<_ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final List<_UnitVariantDraft> _unitVariants = [];

  String? _selectedCategory;
  String _dashboardSection = 'daily_essentials';
  bool _saving = false;
  bool _uploading = false;
  String? _uploadError; // shown inline, does NOT block save
  String? _saveError;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p == null) {
      _addUnitVariant();
      return;
    }
    _nameCtrl.text = p.name;
    _imageCtrl.text = p.imageUrl;
    _descriptionCtrl.text = p.description;
    _dashboardSection = p.dashboardSection;
    _selectedCategory = p.category;
    if (p.unitVariants.isNotEmpty) {
      for (final variant in p.unitVariants) {
        _unitVariants.add(
          _UnitVariantDraft(
            unit: variant.unit,
            price: variant.price.toStringAsFixed(0),
            discountCost: variant.discountCost.toStringAsFixed(0),
            stock: variant.stock.toString(),
          ),
        );
      }
    } else {
      _addUnitVariant(
        unit: p.unit,
        price: p.price.toStringAsFixed(0),
        discountCost: (p.mrp > 0 ? p.mrp : p.cost).toStringAsFixed(0),
        stock: p.stock.toString(),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _imageCtrl.dispose();
    _descriptionCtrl.dispose();
    for (final variant in _unitVariants) {
      variant.dispose();
    }
    super.dispose();
  }

  void _addUnitVariant({
    String unit = '',
    String price = '',
    String discountCost = '',
    String stock = '',
  }) {
    _unitVariants.add(
      _UnitVariantDraft(
        unit: unit,
        price: price,
        discountCost: discountCost,
        stock: stock,
      ),
    );
  }

  void _removeUnitVariant(int index) {
    if (_unitVariants.length <= 1) return;
    setState(() {
      final removed = _unitVariants.removeAt(index);
      removed.dispose();
    });
  }

  // ── Image upload ──────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    setState(() {
      _uploading = true;
      _uploadError = null;
    });

    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) {
        setState(() => _uploading = false);
        return;
      }

      Uint8List? bytes;
      String path = picked.path;

      if (kIsWeb) {
        bytes = await picked.readAsBytes();
      }

      final url = await context.read<AppState>().uploadProductImage(
        path,
        bytes: bytes,
        fileName: picked.name,
      );

      if (!mounted) return;
      setState(() {
        _imageCtrl.text = url;
        _uploading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadError =
            'Upload failed: ${e.toString().replaceFirst('Exception: ', '')}';
        _uploading = false;
      });
    }
  }

  // ── Save product ──────────────────────────────────────────────────────────
  Future<void> _save() async {
    // Clear previous save error
    setState(() => _saveError = null);

    if (!_formKey.currentState!.validate()) return;
    if (_unitVariants.isEmpty) {
      setState(() {
        _saveError = 'Please add at least one unit.';
      });
      return;
    }

    setState(() => _saving = true);

    try {
      final state = context.read<AppState>();
      final imageUrl = _imageCtrl.text.trim();
      if (imageUrl.isEmpty) {
        setState(() {
          _saveError = 'Please upload a product image first.';
        });
        return;
      }
      final finalImageUrl = imageUrl;
      final unitVariants = _unitVariants
          .map((variant) => variant.toJson())
          .toList();
      final primaryVariant = unitVariants.first;
      final existingRating = widget.product?.rating ?? 0;

      if (_isEdit) {
        await state.updateProduct(
          productId: widget.product!.id,
          name: _nameCtrl.text.trim(),
          category: _selectedCategory ?? '',
          price: primaryVariant['price'] as double,
          cost: primaryVariant['discountCost'] as double,
          mrp: primaryVariant['discountCost'] as double,
          stock: primaryVariant['stock'] as int,
          unit: primaryVariant['unit'] as String? ?? 'item',
          rating: existingRating,
          description: _descriptionCtrl.text.trim(),
          dashboardSection: _dashboardSection,
          imageUrl: finalImageUrl,
          unitVariants: unitVariants,
        );
      } else {
        await state.createProduct(
          name: _nameCtrl.text.trim(),
          category: _selectedCategory ?? '',
          price: primaryVariant['price'] as double,
          cost: primaryVariant['discountCost'] as double,
          mrp: primaryVariant['discountCost'] as double,
          stock: primaryVariant['stock'] as int,
          unit: primaryVariant['unit'] as String? ?? 'item',
          rating: 0,
          description: _descriptionCtrl.text.trim(),
          dashboardSection: _dashboardSection,
          imageUrl: finalImageUrl,
          unitVariants: unitVariants,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saveError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        // Resolve categories
        final cats = state.categoryCatalog.map((c) => c.name).toList();
        if (_selectedCategory == null && cats.isNotEmpty) {
          _selectedCategory = cats.first;
        }
        if (_selectedCategory != null && !cats.contains(_selectedCategory)) {
          cats.add(_selectedCategory!);
        }

        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          title: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Color(0xFFE8541A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isEdit ? 'Edit product' : 'Add product',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── Image upload section ────────────────────────────
                    _ImageSection(
                      imageUrl: _imageCtrl.text,
                      uploading: _uploading,
                      uploadError: _uploadError,
                      onPickImage: _pickImage,
                    ),

                    const SizedBox(height: 16),

                    // ── Product name ────────────────────────────────────
                    _Field(
                      controller: _nameCtrl,
                      label: 'Product name *',
                      icon: Icons.label_rounded,
                      validator: (v) => (v?.trim().isEmpty ?? true)
                          ? 'Name is required'
                          : null,
                    ),

                    // ── Category dropdown ───────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<String>(
                        value: cats.contains(_selectedCategory)
                            ? _selectedCategory
                            : null,
                        decoration: InputDecoration(
                          labelText: 'Category *',
                          prefixIcon: const Icon(Icons.category_rounded),
                          filled: true,
                          fillColor: const Color(0xFFF8F8F8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE8E8E8),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE8541A),
                              width: 1.5,
                            ),
                          ),
                        ),
                        items: cats
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedCategory = v),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Category is required'
                            : null,
                      ),
                    ),

                    // ── Unit variants ─────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Unit variants *',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFE8541A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                            onPressed: () => setState(_addUnitVariant),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text(
                              'Add unit',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'Each unit row has unit, price, discount cost, and stock.',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._unitVariants.asMap().entries.map((entry) {
                      final index = entry.key;
                      final variant = entry.value;
                      return _UnitVariantCard(
                        index: index,
                        total: _unitVariants.length,
                        unitCtrl: variant.unitCtrl,
                        priceCtrl: variant.priceCtrl,
                        discountCostCtrl: variant.discountCostCtrl,
                        stockCtrl: variant.stockCtrl,
                        onRemove: () => _removeUnitVariant(index),
                      );
                    }),

                    const SizedBox(height: 4),
                    const _ReadOnlyNotice(
                      icon: Icons.star_rounded,
                      title: 'Ratings are customer-driven',
                      message:
                          'Vendors and super admin cannot edit product ratings here. Ratings should come from customers after delivered orders.',
                    ),

                    // ── Description ──────────────────────────────────
                    _Field(
                      controller: _descriptionCtrl,
                      label: 'Description',
                      icon: Icons.description_rounded,
                      required: false,
                      maxLines: 3,
                    ),

                    // ── Dashboard section ─────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<String>(
                        value: _dashboardSection,
                        decoration: InputDecoration(
                          labelText: 'Dashboard section *',
                          prefixIcon: const Icon(Icons.view_agenda_rounded),
                          filled: true,
                          fillColor: const Color(0xFFF8F8F8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE8E8E8),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE8541A),
                              width: 1.5,
                            ),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'fresh_picks',
                            child: Text('Fresh picks'),
                          ),
                          DropdownMenuItem(
                            value: 'daily_essentials',
                            child: Text('Daily essentials'),
                          ),
                          DropdownMenuItem(
                            value: 'popular_products',
                            child: Text('Popular products'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _dashboardSection = v);
                        },
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Dashboard section is required'
                            : null,
                      ),
                    ),

                    // ── Save error ──────────────────────────────────────
                    if (_saveError != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFCDD2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Color(0xFFDC2626),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _saveError!,
                                style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
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
          ),
          actions: [
            TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE8541A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(
                _saving
                    ? 'Saving…'
                    : (_isEdit ? 'Save changes' : 'Add product'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Image Section ────────────────────────────────────────────────────────────

class _ImageSection extends StatelessWidget {
  const _ImageSection({
    required this.imageUrl,
    required this.uploading,
    required this.uploadError,
    required this.onPickImage,
  });

  final String imageUrl;
  final bool uploading;
  final String? uploadError;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        imageUrl.startsWith('http') || imageUrl.startsWith('assets/');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
            child: SizedBox(
              height: 170,
              width: double.infinity,
              child: hasImage
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : const Center(child: CircularProgressIndicator()),
                      errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
                    )
                  : const _ImagePlaceholder(),
            ),
          ),

          // Upload row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Product image',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasImage
                                ? '✅ Image uploaded'
                                : 'Optional — tap Upload to add one',
                            style: TextStyle(
                              fontSize: 12,
                              color: hasImage
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF9E9E9E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: uploading
                            ? const Color(0xFFCCCCCC)
                            : const Color(0xFFE8541A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onPressed: uploading ? null : onPickImage,
                      icon: uploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.upload_rounded, size: 18),
                      label: Text(
                        uploading ? 'Uploading…' : 'Upload',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                // Upload error (non-blocking)
                if (uploadError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFB45309),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            uploadError!,
                            style: const TextStyle(
                              color: Color(0xFFB45309),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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

class _UnitVariantCard extends StatelessWidget {
  const _UnitVariantCard({
    required this.index,
    required this.total,
    required this.unitCtrl,
    required this.priceCtrl,
    required this.discountCostCtrl,
    required this.stockCtrl,
    required this.onRemove,
  });

  final int index;
  final int total;
  final TextEditingController unitCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController discountCostCtrl;
  final TextEditingController stockCtrl;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFFE8541A),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Unit details',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (total > 1)
                TextButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  label: const Text('Remove'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _Field(
            controller: unitCtrl,
            label: 'Unit * (kg / ltr / gram)',
            icon: Icons.straighten_rounded,
            validator: (v) =>
                (v?.trim().isEmpty ?? true) ? 'Unit is required' : null,
          ),
          Row(
            children: [
              Expanded(
                child: _Field(
                  controller: priceCtrl,
                  label: 'Price *',
                  icon: Icons.sell_rounded,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    if (v?.trim().isEmpty ?? true) return 'Required';
                    if (double.tryParse(v!.trim()) == null) {
                      return 'Invalid number';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Field(
                  controller: discountCostCtrl,
                  label: 'Discount cost *',
                  icon: Icons.price_change_rounded,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    if (v?.trim().isEmpty ?? true) return 'Required';
                    if (double.tryParse(v!.trim()) == null) {
                      return 'Invalid number';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          _Field(
            controller: stockCtrl,
            label: 'Stock *',
            icon: Icons.inventory_2_rounded,
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v?.trim().isEmpty ?? true) return 'Required';
              if (int.tryParse(v!.trim()) == null) return 'Must be integer';
              return null;
            },
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEEEEEE),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_photo_alternate_rounded,
              size: 48,
              color: Color(0xFFCCCCCC),
            ),
            SizedBox(height: 8),
            Text(
              'No image',
              style: TextStyle(
                color: Color(0xFFAAAAAA),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable Field ───────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.required = true,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool required;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: const Color(0xFFF8F8F8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE8541A), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDC2626)),
          ),
        ),
        validator:
            validator ??
            (v) {
              if (!required) return null;
              return (v?.trim().isEmpty ?? true) ? '$label is required' : null;
            },
      ),
    );
  }
}

// ─── Empty / Error states ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_rounded,
            size: 56,
            color: Color(0xFFEEEEEE),
          ),
          const SizedBox(height: 12),
          const Text(
            'No products yet',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE8541A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Add first product',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _NothingFound extends StatelessWidget {
  const _NothingFound();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: const Row(
        children: [
          Icon(Icons.search_off_rounded, color: Color(0xFFCCCCCC), size: 32),
          SizedBox(width: 14),
          Text(
            'No products match your search',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

Color _categoryColor(String category) {
  final v = category.toLowerCase();
  if (v.contains('veg') || v.contains('fruit')) {
    return const Color(0xFF16A34A);
  }
  if (v.contains('dairy') || v.contains('milk')) {
    return const Color(0xFF2563EB);
  }
  if (v.contains('snack')) return const Color(0xFFDB2777);
  if (v.contains('staple') || v.contains('rice')) {
    return const Color(0xFFB45309);
  }
  return const Color(0xFF7C3AED);
}
