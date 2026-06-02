import 'package:flutter_test/flutter_test.dart';

import 'package:doormartdelivery/main.dart';

void main() {
  testWidgets('Doormart home renders', (WidgetTester tester) async {
    await tester.pumpWidget(const DoormartDeliveryApp());

    expect(find.text('Delivery in 10 minutes'), findsOneWidget);
    expect(find.text('Shop by category'), findsOneWidget);
  });
}
