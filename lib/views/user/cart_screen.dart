import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/toast_widget.dart';
import '../app_page.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  static const routeName = '/cart';

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Cart',
      children: [
        Consumer<AppState>(
          builder: (context, state, _) {
            if (state.cart.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('Your cart is empty')),
                ),
              );
            }

            return Column(
              children: [
                ...state.cart.map(
                  (line) => ListTile(
                    leading: const Icon(Icons.shopping_basket),
                    title: Text(line.product.name),
                    subtitle: Text(
                      '${line.quantity} x Rs ${line.product.price.toStringAsFixed(0)}',
                    ),
                    trailing: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () async {
                            final changed = await state.decrement(line.product);
                            if (!context.mounted) return;
                            showToast(
                              context,
                              changed
                                  ? '${line.product.name} removed one item'
                                  : state.error ?? 'Please login first',
                            );
                          },
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('Rs ${line.total.toStringAsFixed(0)}'),
                        IconButton(
                          onPressed: () async {
                            final added = await state.addToCart(line.product);
                            if (!context.mounted) return;
                            showToast(
                              context,
                              added
                                  ? '${line.product.name} added to cart'
                                  : state.error ?? 'Please login first',
                            );
                          },
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Delivery fee'),
                  trailing: Text('Rs ${state.deliveryFee.toStringAsFixed(0)}'),
                ),
                ListTile(
                  title: const Text('Total'),
                  trailing: Text(
                    'Rs ${state.total.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            );
          },
        ),
        Consumer<AppState>(
          builder: (context, state, _) => AppButton(
            label: 'Checkout',
            icon: Icons.payment,
            onPressed: state.cart.isEmpty
                ? () => showToast(context, 'Your cart is empty')
                : () {
                    showToast(context, 'Proceeding to checkout');
                    Navigator.pushNamed(context, CheckoutScreen.routeName);
                  },
          ),
        ),
      ],
    );
  }
}
