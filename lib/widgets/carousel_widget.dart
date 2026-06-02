import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants.dart';

class CarouselWidget extends StatefulWidget {
  const CarouselWidget({super.key});

  @override
  State<CarouselWidget> createState() => _CarouselWidgetState();
}

class _CarouselWidgetState extends State<CarouselWidget> {
  final PageController _controller = PageController(viewportFraction: 0.34);
  int _page = 0;
  late final Timer _timer;

  final List<String> _items = const [
    'Farm Fresh',
    'Milk & Bread',
    'Weekend Staples',
    'Organic Picks',
    'Snacks',
    'Cleaning',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: AppConstants.carouselAutoSlideSeconds),
      (_) => _next(),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    _page = (_page + 1) % _items.length;
    if (_controller.hasClients) {
      _controller.animateToPage(
        _page,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: Row(
            children: [
              IconButton(
                onPressed: _next,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _items.length,
                  onPageChanged: (value) => setState(() => _page = value),
                  itemBuilder: (context, index) => Card(
                    child: Center(
                      child: Text(
                        _items[index],
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: _next,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _items.length,
            (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == _page
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
