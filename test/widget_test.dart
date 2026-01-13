// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:moneymind/main.dart';
import 'package:moneymind/login.dart';

void main() {
  testWidgets('Shows login screen when no user is signed in', (WidgetTester tester) async {
    // Build our app with no current user injected and skip auth checks.
    await tester.pumpWidget(MoneyMind(skipAuth: true));

    // Verify that the LoginScreen is shown by finding the Email field label.
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });
}
