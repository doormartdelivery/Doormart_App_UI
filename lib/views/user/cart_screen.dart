import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../widgets/app_button.dart';
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
                          onPressed: () => state.decrement(line.product),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('Rs ${line.total.toStringAsFixed(0)}'),
                        IconButton(
                          onPressed: () => state.addToCart(line.product),
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
                ? () {}
                : () => Navigator.pushNamed(context, CheckoutScreen.routeName),
          ),
        ),
      ],
    );
  }
}
