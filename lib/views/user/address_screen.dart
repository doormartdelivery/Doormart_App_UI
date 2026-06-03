import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/address_model.dart';
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
      bottomNavIndex: 3,
      actions: [
        IconButton(
          onPressed: () =>
              Navigator.pushNamed(context, AddEditAddressScreen.routeName),
          icon: const Icon(Icons.add_location_alt),
        ),
      ],
      children: [
        FutureBuilder<List<AddressModel>>(
          future: context.read<AppState>().addresses(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LinearProgressIndicator();
            final addresses = snapshot.data!;
            return Column(
              children: addresses.map((item) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(item.label),
                    subtitle: Text(item.fullAddress),
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
