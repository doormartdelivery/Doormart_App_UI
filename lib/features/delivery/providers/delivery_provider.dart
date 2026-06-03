import 'package:flutter/foundation.dart';

import '../../../models/delivery_person_model.dart';

class DeliveryProvider extends ChangeNotifier {
  final List<DeliveryPersonModel> people = const [
    DeliveryPersonModel(
      id: 'd1',
      name: 'Arun Kumar',
      phone: '9000000001',
      active: true,
      completedOrders: 84,
    ),
    DeliveryPersonModel(
      id: 'd2',
      name: 'Meena S',
      phone: '9000000002',
      active: false,
      completedOrders: 51,
    ),
  ];
}
