import 'package:flutter_test/flutter_test.dart';
import 'package:msu_food2/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MsuFoodApp());
  });
}