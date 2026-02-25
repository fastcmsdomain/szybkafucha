import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:szybka_fucha/features/auth/screens/onboarding_screen.dart';
import 'package:szybka_fucha/features/auth/screens/public_home_screen.dart';
import 'package:szybka_fucha/main.dart';

void main() {
  testWidgets('App starts and shows onboarding screen', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const ProviderScope(child: SzybkaFuchaApp()));

    // Allow time for router to initialize
    await tester.pumpAndSettle();

    final hasOnboarding = find.byType(OnboardingScreen).evaluate().isNotEmpty;
    final hasPublicHome = find.byType(PublicHomeScreen).evaluate().isNotEmpty;
    expect(hasOnboarding || hasPublicHome, isTrue);
  });

  testWidgets('App has correct title', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SzybkaFuchaApp()));

    await tester.pumpAndSettle();

    // Find MaterialApp.router and check title
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.title, 'SzybkaFucha');
  });
}
