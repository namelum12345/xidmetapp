// Basic smoke test — avoid full app + Firebase (not available in unit test binding).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qonsudan_xidmet/screens/login_screen.dart';

void main() {
  testWidgets('Login screen shows title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    expect(find.text('Qonşudan Xidmət'), findsOneWidget);
    expect(find.text('Daxil ol'), findsWidgets);
  });
}
