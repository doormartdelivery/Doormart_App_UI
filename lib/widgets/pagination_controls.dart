import 'package:flutter/material.dart';

class PaginationControls extends StatelessWidget {
  const PaginationControls({
    super.key,
    required this.page,
    required this.pageCount,
    required this.itemCount,
    required this.pageSize,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int pageCount;
  final int itemCount;
  final int pageSize;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) return const SizedBox.shrink();
    final first = page * pageSize + 1;
    final last = (first + pageSize - 1).clamp(1, itemCount);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
      child: Row(
        children: [
          Text(
            '$first–$last of $itemCount',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF667085),
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Previous page',
            onPressed: page > 0 ? onPrevious : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text(
            '${page + 1} / $pageCount',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          IconButton(
            tooltip: 'Next page',
            onPressed: page + 1 < pageCount ? onNext : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

List<T> paginateItems<T>(List<T> items, int page, int pageSize) {
  final start = page * pageSize;
  if (start >= items.length) return const [];
  final end = (start + pageSize).clamp(0, items.length).toInt();
  return items.sublist(start, end);
}

class PaginatedCollection<T> extends StatefulWidget {
  const PaginatedCollection({
    super.key,
    required this.items,
    required this.builder,
    this.pageSize = 10,
  });

  final List<T> items;
  final int pageSize;
  final Widget Function(List<T> visibleItems) builder;

  @override
  State<PaginatedCollection<T>> createState() => _PaginatedCollectionState<T>();
}

class _PaginatedCollectionState<T> extends State<PaginatedCollection<T>> {
  int _page = 0;

  @override
  void didUpdateWidget(covariant PaginatedCollection<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.items, widget.items)) {
      _page = 0;
    }
    final lastPage = widget.items.isEmpty
        ? 0
        : (widget.items.length - 1) ~/ widget.pageSize;
    if (_page > lastPage) _page = lastPage;
  }

  @override
  Widget build(BuildContext context) {
    final pageCount = widget.items.isEmpty
        ? 1
        : (widget.items.length + widget.pageSize - 1) ~/ widget.pageSize;
    final visible = paginateItems(widget.items, _page, widget.pageSize);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.builder(visible),
        PaginationControls(
          page: _page,
          pageCount: pageCount,
          itemCount: widget.items.length,
          pageSize: widget.pageSize,
          onPrevious: () => setState(() => _page--),
          onNext: () => setState(() => _page++),
        ),
      ],
    );
  }
}
