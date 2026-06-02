import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../app_page.dart';
import 'add_edit_address_screen.dart';

class AddressScreen extends StatelessWidget {
  const AddressScreen({super.key});
  static const routeName = '/address';

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Addresses',
      actions: [
        IconButton(
          onPressed: () =>
              Navigator.pushNamed(context, AddEditAddressScreen.routeName),
          icon: const Icon(Icons.add_location_alt),
        ),
      ],
      children: [
        FutureBuilder<List<dynamic>>(
          future: context.read<AppState>().addresses(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LinearProgressIndicator();
            final addresses = snapshot.data!;
            return Column(
              children: addresses.map((item) {
                final address = item as Map<String, dynamic>;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(address['label'] as String? ?? 'Address'),
                    subtitle: Text(
                      '${address['line1'] ?? ''}, ${address['city'] ?? ''} ${address['pincode'] ?? ''}',
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
