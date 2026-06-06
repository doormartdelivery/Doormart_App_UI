import 'package:flutter/material.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  static const routeName = '/admin/stock';

  @override
  Widget build(BuildContext context) {
    return const _StockAlertPanel();
  }
}

class _StockAlertPanel extends StatefulWidget {
  const _StockAlertPanel();

  @override
  State<_StockAlertPanel> createState() => _StockAlertPanelState();
}

class _StockAlertPanelState extends State<_StockAlertPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  String _filter = 'All';

  static final List<_StockItem> _items = [
    _StockItem('Tomato', 'Vegetables', 18, 120, 'Critical', 'Today 4 PM', Color(0xFFDC2626), Icons.spa),
    _StockItem('Milk 1L', 'Dairy', 32, 160, 'Low', 'Tomorrow 8 AM', Color(0xFF2563EB), Icons.local_drink),
    _StockItem('Rice 5kg', 'Staples', 42, 210, 'Low', 'Tomorrow 11 AM', Color(0xFFB45309), Icons.rice_bowl),
    _StockItem('Banana', 'Fruits', 76, 140, 'Healthy', 'Friday 9 AM', Color(0xFF0F766E), Icons.eco),
    _StockItem('Cooking oil', 'Staples', 12, 90, 'Critical', 'Today 2 PM', Color(0xFFDB2777), Icons.inventory_2),
    _StockItem('Baby wipes', 'Baby care', 64, 130, 'Healthy', 'Monday 10 AM', Color(0xFF7C3AED), Icons.child_care),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _filter == 'All'
        ? _items
        : _items.where((item) => item.status == _filter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6),
      appBar: AppBar(
        title: const Text('Stock alerts'),
        actions: [
          IconButton(
            tooltip: 'Sync stock',
            onPressed: () {
              _controller
                ..reset()
                ..forward();
            },
            icon: const Icon(Icons.sync),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _AnimatedIn(animation: _controller, index: 0, child: const _StockHero()),
            const SizedBox(height: 14),
            _AnimatedIn(animation: _controller, index: 1, child: _StockMetrics(items: _items)),
            const SizedBox(height: 18),
            _AnimatedIn(
              animation: _controller,
              index: 2,
              child: _AlertFilter(selected: _filter, onChanged: (value) => setState(() => _filter = value)),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 980 ? 3 : constraints.maxWidth > 650 ? 2 : 1;
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
              child: _RestockPlanner(items: _items.where((item) => item.status != 'Healthy').toList()),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockHero extends StatelessWidget {
  const _StockHero();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF17211B),
        borderRadius: BorderRadius.circular(8),
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
                    'Catch low stock early, prioritize restock runs, and protect customer orders.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: .78),
                        ),
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(8),
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

  final List<_StockItem> items;

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

  final _StockItem item;

  @override
  Widget build(BuildContext context) {
    final percent = item.stock / item.target;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SizedBox(width: 46, height: 46, child: Icon(item.icon, color: item.color)),
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
                borderRadius: BorderRadius.circular(8),
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

  final List<_StockItem> items;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
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
            ...items.map((item) => _RestockRow(item: item)),
          ],
        ),
      ),
    );
  }
}

class _RestockRow extends StatelessWidget {
  const _RestockRow({required this.item});

  final _StockItem item;

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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: metric.color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(8),
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
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

class _StockItem {
  const _StockItem(
    this.name,
    this.category,
    this.stock,
    this.target,
    this.status,
    this.restock,
    this.color,
    this.icon,
  );

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
