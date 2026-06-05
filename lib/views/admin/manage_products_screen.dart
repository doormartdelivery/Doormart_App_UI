import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/app_state.dart';
import '../app_page.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  static const routeName = '/admin/products';

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AppState>().loadProducts());
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProductModel> _filteredProducts(List<ProductModel> products) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return products;

    return products.where((product) {
      return product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          product.unit.toLowerCase().contains(query) ||
          product.stock.toString().contains(query) ||
          product.price.toStringAsFixed(0).contains(query);
    }).toList();
  }

  List<ProductModel> _sortedProducts(List<ProductModel> products) {
    final sorted = [...products];
    int compare(ProductModel a, ProductModel b) {
      return switch (_sortColumnIndex) {
        0 => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        1 => a.category.toLowerCase().compareTo(b.category.toLowerCase()),
        2 => a.stock.compareTo(b.stock),
        3 => a.cost.compareTo(b.cost),
        4 => a.price.compareTo(b.price),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
    }

    sorted.sort((a, b) {
      final result = compare(a, b);
      return _sortAscending ? result : -result;
    });
    return sorted;
  }

  Future<void> _openAddProductForm() async {
    final added = await showDialog<bool>(
      context: context,
      builder: (context) => const _AddProductDialog(),
    );

    if (!mounted || added != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product added successfully')),
    );
  }

  Future<void> _openEditProductForm(ProductModel product) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => _ProductDialog(product: product),
    );

    if (!mounted || updated != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product updated successfully')),
    );
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('Delete product'),
        content: Text('Remove ${product.name} from the product table?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await context.read<AppState>().deleteProduct(product.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Manage products',
      actions: [
        IconButton.filled(
          tooltip: 'Add product',
          onPressed: _openAddProductForm,
          icon: const Icon(Icons.add),
        ),
      ],
      children: [
        Consumer<AppState>(
          builder: (context, state, _) {
            final allProducts = _sortedProducts(state.products);
            final products = _filteredProducts(allProducts);
            if (state.loading && products.isEmpty) {
              return const LinearProgressIndicator();
            }
            if (state.error != null && products.isEmpty) {
              return _ProductsError(message: state.error!);
            }
            if (products.isEmpty) {
              return _ProductsEmptyState(onAdd: _openAddProductForm);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProductsHero(
                  products: allProducts,
                  onAdd: _openAddProductForm,
                ),
                const SizedBox(height: 14),
                _ProductSearchField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  onClear: _query.isEmpty
                      ? null
                      : () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                ),
                const SizedBox(height: 14),
                _ProductsTable(
                  products: products,
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
                  onSort: _sortBy,
                  onEdit: _openEditProductForm,
                  onDelete: _deleteProduct,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ProductSearchField extends StatelessWidget {
  const _ProductSearchField({
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
        hintText: 'Search products by name, category, unit, stock, or price',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: onClear == null
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close),
                onPressed: onClear,
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}

class _ProductsHero extends StatelessWidget {
  const _ProductsHero({required this.products, required this.onAdd});

  final List<ProductModel> products;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final lowStock = products.where((product) => product.stock <= 10).length;
    final categories = products.map((product) => product.category).toSet().length;
    final inventoryValue = products.fold<double>(
      0,
      (sum, product) => sum + (product.cost * product.stock),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFF16A34A), Color(0xFF0891B2), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.inventory_2, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Product inventory',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F766E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HeroMetric('Products', '${products.length}', Icons.widgets),
                _HeroMetric('Categories', '$categories', Icons.category),
                _HeroMetric('Low stock', '$lowStock', Icons.warning_amber),
                _HeroMetric(
                  'Stock value',
                  'Rs ${inventoryValue.toStringAsFixed(0)}',
                  Icons.payments,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductsTable extends StatelessWidget {
  const _ProductsTable({
    required this.products,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ProductModel> products;
  final int sortColumnIndex;
  final bool sortAscending;
  final ValueChanged<int> onSort;
  final ValueChanged<ProductModel> onEdit;
  final ValueChanged<ProductModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE7F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  sortColumnIndex: sortColumnIndex,
                  sortAscending: sortAscending,
                  headingRowColor:
                      WidgetStateProperty.all(const Color(0xFFECFDF5)),
                  headingTextStyle: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                  dataTextStyle: const TextStyle(
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w600,
                  ),
                  dataRowMinHeight: 68,
                  dataRowMaxHeight: 78,
                  columnSpacing: 26,
                  horizontalMargin: 16,
                  columns: [
                    DataColumn(
                      label: const Text('Product'),
                      onSort: (_, __) => onSort(0),
                    ),
                    DataColumn(
                      label: const Text('Category'),
                      onSort: (_, __) => onSort(1),
                    ),
                    DataColumn(
                      label: const Text('Stock'),
                      numeric: true,
                      onSort: (_, __) => onSort(2),
                    ),
                    DataColumn(
                      label: const Text('Cost'),
                      numeric: true,
                      onSort: (_, __) => onSort(3),
                    ),
                    DataColumn(
                      label: const Text('Price'),
                      numeric: true,
                      onSort: (_, __) => onSort(4),
                    ),
                    const DataColumn(label: Text('Unit')),
                    const DataColumn(label: Text('Actions')),
                  ],
                  rows: products.asMap().entries.map((entry) {
                    final index = entry.key;
                    final product = entry.value;
                    return DataRow(
                      color: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered)) {
                          return const Color(0xFFEFF6FF);
                        }
                        return index.isEven
                            ? const Color(0xFFFFFFFF)
                            : const Color(0xFFF8FAFC);
                      }),
                      cells: [
                        DataCell(_ProductNameCell(product: product)),
                        DataCell(_CategoryBadge(category: product.category)),
                        DataCell(_StockBadge(stock: product.stock)),
                        DataCell(Text('Rs ${product.cost.toStringAsFixed(0)}')),
                        DataCell(
                          Text(
                            'Rs ${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Color(0xFF0F766E),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        DataCell(Text(product.unit)),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Edit product',
                                onPressed: () => onEdit(product),
                                icon: const Icon(Icons.edit),
                              ),
                              IconButton(
                                tooltip: 'Delete product',
                                onPressed: () => onDelete(product),
                                icon: const Icon(Icons.delete),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
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
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: _categoryColor(product.category).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              Icons.inventory,
              color: _categoryColor(product.category),
              size: 21,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 170,
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

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(category);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          category,
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          '$stock',
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _AddProductDialog extends StatelessWidget {
  const _AddProductDialog();

  @override
  Widget build(BuildContext context) => const _ProductDialog();
}

class _ProductDialog extends StatefulWidget {
  const _ProductDialog({this.product});

  final ProductModel? product;

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _costController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _imageController = TextEditingController();
  final _unitController = TextEditingController();
  bool _saving = false;
  String? _error;

  bool get _editing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product == null) return;
    _nameController.text = product.name;
    _categoryController.text = product.category;
    _costController.text = product.cost.toStringAsFixed(0);
    _priceController.text = product.price.toStringAsFixed(0);
    _stockController.text = product.stock.toString();
    _imageController.text = product.imageUrl;
    _unitController.text = product.unit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _costController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final state = context.read<AppState>();
      final product = widget.product;
      if (product == null) {
        await state.createProduct(
          name: _nameController.text.trim(),
          category: _categoryController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          cost: double.parse(_costController.text.trim()),
          stock: int.parse(_stockController.text.trim()),
          imageUrl: _imageController.text.trim(),
        );
      } else {
        await state.updateProduct(
          productId: product.id,
          name: _nameController.text.trim(),
          category: _categoryController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          cost: double.parse(_costController.text.trim()),
          stock: int.parse(_stockController.text.trim()),
          unit: _unitController.text.trim().isEmpty
              ? 'item'
              : _unitController.text.trim(),
          imageUrl: _imageController.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (exception) {
      setState(() => _error = exception.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const SizedBox(
              width: 38,
              height: 38,
              child: Icon(Icons.add_box, color: Color(0xFF2563EB)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(_editing ? 'Edit product' : 'Add product')),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ProductField(
                  controller: _nameController,
                  label: 'Product name',
                  icon: Icons.inventory_2,
                ),
                _ProductField(
                  controller: _categoryController,
                  label: 'Category',
                  icon: Icons.category,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _ProductField(
                        controller: _costController,
                        label: 'Cost',
                        icon: Icons.price_change,
                        numeric: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ProductField(
                        controller: _priceController,
                        label: 'Selling price',
                        icon: Icons.sell,
                        numeric: true,
                      ),
                    ),
                  ],
                ),
                _ProductField(
                  controller: _stockController,
                  label: 'Stock',
                  icon: Icons.numbers,
                  integer: true,
                ),
                _ProductField(
                  controller: _unitController,
                  label: 'Unit',
                  icon: Icons.straighten,
                  required: false,
                ),
                _ProductField(
                  controller: _imageController,
                  label: 'Image URL or asset path',
                  icon: Icons.image,
                  required: false,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
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
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add),
          label: Text(
            _saving ? 'Saving' : (_editing ? 'Save product' : 'Add product'),
          ),
        ),
      ],
    );
  }
}

class _ProductField extends StatelessWidget {
  const _ProductField({
    required this.controller,
    required this.label,
    required this.icon,
    this.numeric = false,
    this.integer = false,
    this.required = true,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool numeric;
  final bool integer;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: numeric || integer ? TextInputType.number : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (required && text.isEmpty) return '$label is required';
          if (text.isEmpty) return null;
          if (integer && int.tryParse(text) == null) return 'Enter a number';
          if (numeric && double.tryParse(text) == null) return 'Enter a price';
          return null;
        },
      ),
    );
  }
}

class _ProductsEmptyState extends StatelessWidget {
  const _ProductsEmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.inventory_2, color: Color(0xFF2563EB)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No products found',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductsError extends StatelessWidget {
  const _ProductsError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          message,
          style: const TextStyle(
            color: Color(0xFFBE123C),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

Color _categoryColor(String category) {
  final value = category.toLowerCase();
  if (value.contains('veg') || value.contains('fruit')) {
    return const Color(0xFF16A34A);
  }
  if (value.contains('dairy') || value.contains('milk')) {
    return const Color(0xFF2563EB);
  }
  if (value.contains('snack')) return const Color(0xFFDB2777);
  if (value.contains('staple') || value.contains('rice')) {
    return const Color(0xFFB45309);
  }
  return const Color(0xFF7C3AED);
}
