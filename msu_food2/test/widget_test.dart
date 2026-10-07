import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msu_food2/main.dart';
import 'package:msu_food2/screens/login_screen.dart';

void main() {
  testWidgets('App shell builds without initializing Firebase', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MsuFoodApp(home: Scaffold(body: Text('App is ready'))),
    );

    expect(find.text('App is ready'), findsOneWidget);
  });

  testWidgets('Login uses the vector food logo without raster background', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MsuFoodApp(home: LoginScreen()));

    expect(find.byIcon(Icons.ramen_dining_rounded), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
