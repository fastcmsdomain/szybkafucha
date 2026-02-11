import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:szybka_fucha/main.dart';

void main() {
  testWidgets('App starts and shows Welcome screen', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(
      const ProviderScope(
        child: SzybkaFuchaApp(),
      ),
    );

    // Allow time for router to initialize
    await tester.pumpAndSettle();

    // Verify the welcome screen is displayed
    // Check for welcome headline (from AppStrings.welcomeTitle)
    expect(find.text('Pomoc jest bliżej niż myślisz'), findsOneWidget);
    // Check for social login buttons
    expect(find.textContaining('Google'), findsOneWidget);
  });

  testWidgets('App has correct title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SzybkaFuchaApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Find MaterialApp.router and check title
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.title, 'SzybkaFucha');
  });
}
