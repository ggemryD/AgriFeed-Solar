// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:smart_solar_pig_feeder/main.dart';

void main() {
  testWidgets('Displays sign in screen when unauthenticated', (tester) async {
    await tester.pumpWidget(const AgriFeedSolarApp());

    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text("Don't have an account?"), findsOneWidget);
  });
}
