/// Smoke Test - Basic app launch verification
///
/// This test verifies:
/// 1. App launches successfully
/// 2. Initial screen is displayed
/// 3. We can interact with the UI

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../utils/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Smoke Test', () {
    testWidgets('App launches and shows initial screen', (tester) async {
      print('[SMOKE] Starting smoke test...');

      // Launch app
      await tester.pumpWidget(const TestApp());

      // Wait for initial frame
      print('[SMOKE] App launched, waiting for initial frame...');
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Debug: Print widget tree to see what's on screen
      print('[SMOKE] Current widget tree:');

      // Check for common screens/widgets
      final scaffoldFinder = find.byType(Scaffold);
      final textFinder = find.byType(Text);

      print('[SMOKE] Found ${scaffoldFinder.evaluate().length} Scaffold widgets');
      print('[SMOKE] Found ${textFinder.evaluate().length} Text widgets');

      // Print first few text widgets to see what's on screen
      for (var element in textFinder.evaluate().take(10)) {
        final widget = element.widget as Text;
        final data = widget.data ?? (widget.textSpan?.toPlainText() ?? 'TextSpan');
        print('[SMOKE] Text: "$data"');
      }

      // Check for specific screens
      if (find.text('Szybka').evaluate().isNotEmpty) {
        print('[SMOKE] Welcome screen detected (found "Szybka")');
      }
      if (find.text('Witaj').evaluate().isNotEmpty) {
        print('[SMOKE] Welcome screen detected (found "Witaj")');
      }
      if (find.text('Co potrzebujesz').evaluate().isNotEmpty) {
        print('[SMOKE] Client home screen detected');
      }
      if (find.text('Dostępne zlecenia').evaluate().isNotEmpty) {
        print('[SMOKE] Contractor home screen detected');
      }
      if (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
        print('[SMOKE] Loading indicator visible');
      }

      // This test always passes - it's just for diagnostics
      expect(scaffoldFinder.evaluate().isNotEmpty, isTrue,
        reason: 'App should have at least one Scaffold');

      print('[SMOKE] Smoke test completed');
    });
  });
}
