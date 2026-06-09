import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/app_state.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  static const routeName = '/admin/stock';

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Future<Map<String, dynamic>> _dashboardFuture;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward();
    _dashboardFuture = context.read<AppState>().adminDashboard();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _dashboardFuture = context.read<AppState>().adminDashboard();
      _controller
        ..reset()
        ..forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6),
      appBar: AppBar(
        title: const Text('Stock alerts'),
        actions: [
          IconButton(
            tooltip: 'Sync stock',
            onPressed: _refresh,
            icon: const Icon(Icons.sync),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: _ErrorCard(message: snapshot.error.toString(), onRetry: _refresh),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final lowStockItems = _parseLowStock(snapshot.data!);
            final visibleItems = _filter == 'All'
                ? lowStockItems
                : lowStockItems.where((item) => item.status == _filter).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _AnimatedIn(
                  animation: _controller,
                  index: 0,
                  child: _StockHero(items: lowStockItems),
                ),
                const SizedBox(height: 14),
                _AnimatedIn(
                  animation: _controller,
                  index: 1,
                  child: _StockMetrics(items: lowStockItems),
                ),
                const SizedBox(height: 18),
                _AnimatedIn(
                  animation: _controller,
                  index: 2,
                  child: _AlertFilter(
                    selected: _filter,
                    onChanged: (value) => setState(() => _filter = value),
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth > 980
                        ? 3
                        : constraints.maxWidth > 650
                            ? 2
                            : 1;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: visibleItems.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: columns == 1 ? 1.95 : 1.45,
                      ),
                      itemBuilder: (context, index) => _AnimatedIn(
                        animation: _controller,
                        index: index + 3,
                        child: _StockCard(item: visibleItems[index]),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                _AnimatedIn(
                  animation: _controller,
                  index: 8,
                  child: _RestockPlanner(
                    items: lowStockItems.where((item) => item.status != 'Healthy').toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StockHero extends StatelessWidget {
  const _StockHero({required this.items});

  final List<_StockAlertItem> items;

  @override
  Widget build(BuildContext context) {
    final critical = items.where((item) => item.status == 'Critical').length;
    final low = items.where((item) => item.status == 'Low').length;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF17211B),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inventory watchtower',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Live low-stock items from the backend. Prioritize restock before orders are affected.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: .78),
                        ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HeroPill('Critical', critical, const Color(0xFFDC2626)),
                      _HeroPill('Low stock', low, const Color(0xFFB45309)),
                    ],
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Icon(Icons.warning_amber, color: Colors.white, size: 38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockMetrics extends StatelessWidget {
  const _StockMetrics({required this.items});

  final List<_StockAlertItem> items;

  @override
  Widget build(BuildContext context) {
    final critical = items.where((item) => item.status == 'Critical').length;
    final low = items.where((item) => item.status == 'Low').length;
    final healthy = items.where((item) => item.status == 'Healthy').length;
    final totalUnits = items.fold<int>(0, (sum, item) => sum + item.stock);
    final metrics = [
      _Metric('Critical', '$critical', Icons.error, const Color(0xFFDC2626)),
      _Metric('Low stock', '$low', Icons.trending_down, const Color(0xFFB45309)),
      _Metric('Healthy', '$healthy', Icons.verified, const Color(0xFF0F766E)),
      _Metric('Units live', '$totalUnits', Icons.inventory, const Color(0xFF2563EB)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 760 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: columns == 4 ? 2.2 : 1.65,
          ),
          itemBuilder: (context, index) => _MetricCard(metric: metrics[index]),
        );
      },
    );
  }
}

class _AlertFilter extends StatelessWidget {
  const _AlertFilter({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const filters = ['All', 'Critical', 'Low', 'Healthy'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final active = selected == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: active,
              label: Text(filter),
              avatar: Icon(active ? Icons.done : Icons.circle_outlined, size: 17),
              onSelected: (_) => onChanged(filter),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  const _StockCard({required this.item});

  final _StockAlertItem item;

  @override
  Widget build(BuildContext context) {
    final percent = item.stock / item.target;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SizedBox(
                      width: 46,
                      height: 46,
                      child: Icon(item.icon, color: item.color),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                        Text(item.category, style: const TextStyle(color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  _StatusBadge(label: item.status, color: item.color),
                ],
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${item.stock}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text('/ ${item.target} units', style: const TextStyle(color: Color(0xFF64748B))),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: percent.clamp(0, 1),
                  minHeight: 9,
                  color: item.color,
                  backgroundColor: item.color.withValues(alpha: .12),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.event_available, size: 17, color: Color(0xFF64748B)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Restock: ${item.restock}',
                      style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestockPlanner extends StatelessWidget {
  const _RestockPlanner({required this.items});

  final List<_StockAlertItem> items;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Restock priority', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                ),
                IconButton.filledTonal(
                  tooltip: 'Create purchase order',
                  onPressed: () {},
                  icon: const Icon(Icons.add_shopping_cart),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No stock alerts right now.'),
              )
            else
              ...items.map((item) => _RestockRow(item: item)),
          ],
        ),
      ),
    );
  }
}

class _RestockRow extends StatelessWidget {
  const _RestockRow({required this.item});

  final _StockAlertItem item;

  @override
  Widget build(BuildContext context) {
    final need = item.target - item.stock;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(item.status == 'Critical' ? Icons.bolt : Icons.low_priority, color: item.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text('Need $need units  •  ${item.restock}', style: const TextStyle(color: Color(0xFF64748B))),
              ],
            ),
          ),
          FilledButton.tonal(onPressed: () {}, child: const Text('Order')),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: metric.color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox(width: 44, height: 44, child: Icon(metric.icon, color: metric.color)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(metric.value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  Text(metric.label, style: const TextStyle(color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          '$label: $value',
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _AnimatedIn extends StatelessWidget {
  const _AnimatedIn({required this.animation, required this.index, required this.child});

  final Animation<double> animation;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval((index * .07).clamp(0, .72), 1, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFFBE123C),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _StockAlertItem {
  const _StockAlertItem({
    required this.name,
    required this.category,
    required this.stock,
    required this.target,
    required this.status,
    required this.restock,
    required this.color,
    required this.icon,
  });

  final String name;
  final String category;
  final int stock;
  final int target;
  final String status;
  final String restock;
  final Color color;
  final IconData icon;
}

class _Metric {
  const _Metric(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

List<_StockAlertItem> _parseLowStock(Map<String, dynamic> data) {
  final rawItems = (data['lowStock'] as List<dynamic>? ?? const []);
  return rawItems.map((raw) {
    final item = raw as Map<String, dynamic>;
    final product = ProductModel.fromJson(item);
    final target = _targetFor(product);
    final stock = product.stock;
    final ratio = target == 0 ? 1.0 : stock / target;
    final status = ratio <= 0.2
        ? 'Critical'
        : ratio <= 0.5
            ? 'Low'
            : 'Healthy';
    final restockDays = status == 'Critical'
        ? 'Today'
        : status == 'Low'
            ? 'Tomorrow'
            : 'This week';
    return _StockAlertItem(
      name: product.name,
      category: product.category,
      stock: stock,
      target: target,
      status: status,
      restock: restockDays,
      color: _stockColor(status),
      icon: _stockIcon(product.category),
    );
  }).toList();
}

int _targetFor(ProductModel product) {
  if (product.stock <= 0) return 20;
  if (product.stock <= 5) return 20;
  if (product.stock <= 10) return 25;
  if (product.stock <= 15) return 30;
  return product.stock + 20;
}

Color _stockColor(String status) {
  switch (status) {
    case 'Critical':
      return const Color(0xFFDC2626);
    case 'Low':
      return const Color(0xFFB45309);
    case 'Healthy':
    default:
      return const Color(0xFF0F766E);
  }
}

IconData _stockIcon(String category) {
  final value = category.toLowerCase();
  if (value.contains('dairy') || value.contains('milk')) return Icons.local_drink;
  if (value.contains('fruit')) return Icons.eco;
  if (value.contains('staple') || value.contains('rice')) return Icons.rice_bowl;
  if (value.contains('baby')) return Icons.child_care;
  return Icons.inventory_2;
}
