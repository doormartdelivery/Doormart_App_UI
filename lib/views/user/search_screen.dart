import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/customer/search/voice_search_widget.dart';
import '../../providers/app_state.dart';
import '../../widgets/product_card.dart';
import '../../widgets/toast_widget.dart';
import '../app_page.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  static const routeName = '/search';

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _searchController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final initialQuery = ModalRoute.of(context)?.settings.arguments as String?;
    if (initialQuery != null && initialQuery.trim().isNotEmpty) {
      _searchController.text = initialQuery.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AppState>().loadProducts(search: initialQuery.trim());
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Search',
      bottomNavIndex: 1,
      children: [
        VoiceSearchWidget(
          controller: _searchController,
          autofocus: true,
          hintText: 'Search groceries in English or Tamil',
          onSearchChanged: (query) {
            context.read<AppState>().loadProducts(search: query);
          },
          onSubmitted: (query) {
            context.read<AppState>().loadProducts(search: query);
          },
        ),
        const SizedBox(height: 12),
        Consumer<AppState>(
          builder: (context, state, _) {
            if (state.loading && state.products.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null && state.products.isEmpty) {
              return Text(state.error!);
            }
            if (_searchController.text.trim().isNotEmpty &&
                state.products.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No matching products found'),
                ),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.products.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 230,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) => ProductCard(
                product: state.products[index],
                onAdd: () async {
                  final added = await state.addToCart(state.products[index]);
                  if (!context.mounted) return;
                  showToast(
                    context,
                    added
                        ? '${state.products[index].name} added to cart'
                        : state.error ?? 'Please login first',
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
