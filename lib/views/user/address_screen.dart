import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/address_model.dart';
import '../../providers/app_state.dart';
import '../app_page.dart';
import 'add_edit_address_screen.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});
  static const routeName = '/address';

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  late Future<List<AddressModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AppState>().loadAddresses();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = context.read<AppState>().loadAddresses();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Saved Addresses',
      bottomNavIndex: 3,
      actions: [
        IconButton(
          onPressed: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => const AddEditAddressScreen(),
              ),
            );
            if (result == true) await _refresh();
          },
          icon: const Icon(Icons.add_location_alt_rounded),
        ),
      ],
      children: [
        FutureBuilder<List<AddressModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final addresses = snapshot.data ?? const <AddressModel>[];
            if (addresses.isEmpty) {
              return _EmptyAddressState(
                onAdd: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddEditAddressScreen(),
                    ),
                  );
                  if (result == true) await _refresh();
                },
              );
            }
            return Column(
              children: [
                for (final item in addresses)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AddressTile(
                      address: item,
                      onEdit: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditAddressScreen(address: item),
                          ),
                        );
                        if (result == true) await _refresh();
                      },
                      onDelete: () async {
                        await context.read<AppState>().deleteAddress(item.id);
                        await _refresh();
                      },
                      onSetDefault: () async {
                        await context.read<AppState>().setDefaultAddress(item.id);
                        await _refresh();
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  final AddressModel address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    address.label,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            Text(address.line1),
            const SizedBox(height: 4),
            Text(address.shortAddress),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: onSetDefault,
                child: const Text('Set as default'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyAddressState extends StatelessWidget {
  const _EmptyAddressState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.location_off_rounded, size: 40),
            const SizedBox(height: 12),
            const Text(
              'No saved addresses yet',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add one to speed up checkout and order delivery.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAdd,
              child: const Text('Add Address'),
            ),
          ],
        ),
      ),
    );
  }
}
